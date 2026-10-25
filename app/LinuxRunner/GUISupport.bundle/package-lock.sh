#!/bin/sh
# Shared by the managed support installers and App Manager, per environment.
# Every LinuxRunner package operation (installer-run.sh, package-manager.sh)
# takes this lock, then waits until no other package operation runs in Linux:
# on Debian the first-start configuration (init.sh → initialize-debian.sh →
# dpkg --configure -a) must finish first. Until it does dpkg holds its lock and
# ca-certificates has not built the trust store, so apt fails with "could not
# get lock" and "certificate verify failed" (IPA 890). Locks are never removed
# and package processes are never killed here.
package_lock_acquire() {
    lock=.install-lock
    if ! mkdir "$lock" 2>/dev/null; then
        [ ! -L "$lock" ] || { echo 'PACKAGE_LOCK: unsafe symlink'; return 75; }
        owner=$(cat "$lock/pid" 2>/dev/null || true)
        case "$owner" in ''|*[!0-9]*)
            created=$(stat -c %Y "$lock" 2>/dev/null || date +%s); now=$(date +%s)
            [ "$((now-created))" -ge 60 ] || { echo 'PACKAGE_LOCK: owner publication pending'; return 75; }
            owner=0;;
        esac
        if [ "$owner" != 0 ] && kill -0 "$owner" 2>/dev/null &&
            tr '\000' ' ' < "/proc/$owner/cmdline" 2>/dev/null | grep -Eq 'installer-run.sh|package-manager.sh'; then
            echo "PACKAGE_LOCK: category=PACKAGE_MANAGER_BUSY managed operation already running pid=$owner"; return 75
        fi
        echo 'PACKAGE_LOCK: recovering abandoned LinuxRunner lock (its owner is gone)'
        rm -f "$lock/pid"; rmdir "$lock" || return 75; mkdir "$lock" || return 75
    fi
    echo $$ > "$lock/pid"
    trap 'rm -f "$lock/pid"; rmdir "$lock" 2>/dev/null || true' EXIT
    package_system_ready
}

# Other package processes in this Linux environment (pid and command line),
# excluding this process tree's own shell. Matched by the program actually
# running (argv[0], or the script a shell runs), never by text elsewhere on the
# command line, so e.g. "grep initialize-debian.sh" is not a package process.
package_processes() {
    for lr_proc in /proc/[0-9]*; do
        lr_pid=${lr_proc#/proc/}
        [ "$lr_pid" != "$$" ] || continue
        lr_cmd=$( { tr '\000' ' ' < "$lr_proc/cmdline"; } 2>/dev/null) || continue
        lr_arg0=${lr_cmd%% *} lr_rest=${lr_cmd#* }; lr_arg1=${lr_rest%% *}
        case "${lr_arg0##*/}" in
            dpkg|apt-get|apt|apk|aptitude|unattended-upgrade|initialize-debian.sh) echo "$lr_pid $lr_cmd";;
            sh|dash|bash) case "${lr_arg1##*/}" in initialize-debian.sh) echo "$lr_pid $lr_cmd";; esac;;
            *) case "$lr_arg0" in /usr/lib/apt/methods/*) echo "$lr_pid $lr_cmd";; esac;;
        esac
    done
}

# Wait for Debian's first-start configuration and for any other package
# operation. Progress: PACKAGE_STAGE lines (shown by the app). Fails with
# category PACKAGE_MANAGER_STUCK only when nothing progresses for 15 minutes.
package_system_ready() {
    if [ -x /usr/lib/linuxrunner/initialize-debian.sh ] && [ "$(id -u)" = 0 ]; then
        # apt itself waits for dpkg's lock instead of failing (all apt users).
        if [ -d /etc/apt/apt.conf.d ] && [ ! -e /etc/apt/apt.conf.d/90linuxrunner-lock-wait ]; then
            printf 'DPkg::Lock::Timeout "900";\n' > /etc/apt/apt.conf.d/90linuxrunner-lock-wait.new &&
                mv /etc/apt/apt.conf.d/90linuxrunner-lock-wait.new /etc/apt/apt.conf.d/90linuxrunner-lock-wait
        fi
        # Private names: these functions run inside installer-run.sh, whose
        # own $log must not be replaced.
        lr_init_log=/var/log/linuxrunner-initialize.log lr_last= lr_idle=0 lr_named=
        while [ ! -f /var/lib/linuxrunner/initialized ]; do
            # init.sh may be about to start it (app just launched): make sure
            # twice, 5 s apart, that neither it nor dpkg runs before starting it.
            if ! package_processes | grep -q -e 'initialize-debian.sh' -e 'dpkg' && sleep 5 &&
                ! package_processes | grep -q -e 'initialize-debian.sh' -e 'dpkg'; then
                # Not running: interrupted earlier or never started. It resumes
                # where it stopped (dpkg --configure -a, then the trust store).
                echo 'PACKAGE_STAGE: Finishing Debian setup (first start)'
                if ! /usr/lib/linuxrunner/initialize-debian.sh >> "$lr_init_log" 2>&1; then
                    echo 'PACKAGE_LOCK: category=PACKAGE_DATABASE_RECOVERY_REQUIRED Debian first-start configuration failed'
                    tail -n 8 "$lr_init_log" | sed 's/^/PACKAGE_DETAIL: /'
                    return 1
                fi
                continue
            fi
            lr_configured=$(grep -c '^Setting up ' "$lr_init_log" 2>/dev/null || true)
            # Real total: configured so far plus what dpkg still lists as unpacked.
            lr_pending=$(dpkg-query -W -f '${Status}\n' 2>/dev/null | grep -c 'unpacked\|half-configured' || true)
            lr_current=$(grep '^Setting up ' "$lr_init_log" 2>/dev/null | tail -n 1 | cut -d' ' -f3)
            # Name the processes waited on once (the device log then shows
            # which pid holds dpkg's lock).
            [ -n "$lr_named" ] || { lr_named=1; package_processes | sed 's/^/PACKAGE_DETAIL: waiting for /'; }
            if [ "$lr_configured" != "$lr_last" ]; then lr_last=$lr_configured lr_idle=0
                echo "PACKAGE_STAGE: Finishing Debian setup (first start): ${lr_configured:-0} packages configured${lr_current:+, now $lr_current}"
                echo "PACKAGE_PROGRESS: ${lr_configured:-0} $(( ${lr_configured:-0} + ${lr_pending:-0} ))"
            else lr_idle=$((lr_idle+3)); fi
            if [ "$lr_idle" -ge 900 ]; then
                echo "PACKAGE_LOCK: category=PACKAGE_MANAGER_STUCK Debian first-start configuration made no progress for 15 minutes (last: ${lr_current:-none})"
                package_processes | sed 's/^/PACKAGE_DETAIL: running /'
                return 1
            fi
            sleep 3
        done
    fi
    # Any other package process (e.g. a terminal apt-get): wait for it.
    lr_waited=0
    while lr_others=$(package_processes) && [ -n "$lr_others" ]; do
        [ "$lr_waited" -gt 0 ] || { echo 'PACKAGE_STAGE: Waiting for another package installation to finish'; printf '%s\n' "$lr_others" | sed 's/^/PACKAGE_DETAIL: running /'; }
        lr_waited=$((lr_waited+3)); [ "$lr_waited" -lt 1800 ] || { echo 'PACKAGE_LOCK: category=PACKAGE_MANAGER_BUSY another package operation is still running after 30 minutes'; return 75; }
        sleep 3
    done
    return 0
}

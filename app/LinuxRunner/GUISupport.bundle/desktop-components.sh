#!/bin/sh
set -eu
cd "$(dirname "$0")"
session=$1
case "$session" in /*) ;; *) session="$PWD/$session";; esac
export LR_DESKTOP_SESSION="$session"
base="$PWD/desktop"
[ "$(id -u)" = 0 ] || base="${XDG_DATA_HOME:-$HOME/.local/share}/linuxrunner/desktop"
# Desktop environment: LinuxRunner (Openbox) by default; "plasma" (experimental,
# KDE Plasma X11 from the distribution's packages) when chosen in Settings ›
# Desktop (LR_DESKTOP_ENVIRONMENT from session.sh) or in this account's
# ~/.config/linuxrunner/desktop-environment. Plasma not installed: the regular
# desktop starts instead, so Open Desktop keeps working.
environment=${LR_DESKTOP_ENVIRONMENT:-}
[ -n "$environment" ] && [ "$environment" != linuxrunner ] || environment=$(cat "${XDG_CONFIG_HOME:-$HOME/.config}/linuxrunner/desktop-environment" 2>/dev/null || echo linuxrunner)
[ "$environment" = plasma ] || environment=linuxrunner
if [ "$environment" = plasma ] && ! command -v startplasma-x11 >/dev/null; then echo 'DESKTOP_STARTUP: plasma=not-installed; starting the LinuxRunner desktop (Settings › Desktop Environment › Install KDE Plasma)'; environment=linuxrunner; fi
[ -x ./desktop-probe ] || { echo 'DESKTOP_STARTUP: missing=desktop-probe; run Install Desktop Support'; exit 127; }
wm= panel= surface= conf= limit=120
qt_desktop=0
case "$(sed -n 's/^ID=//p' /etc/os-release 2>/dev/null | tr -d '\"')" in arch|archarm) qt_desktop=1;; esac
if [ "$environment" = linuxrunner ]; then
desktop_tools="openbox pcmanfm"
[ "$qt_desktop" = 0 ] || desktop_tools="openbox pcmanfm-qt lxqt-panel"
for tool in $desktop_tools; do command -v "$tool" >/dev/null || { echo "DESKTOP_STARTUP: missing=$tool; run Install Desktop Support"; exit 127; }; done
/bin/sh ./desktop-configure.sh
export XDG_CURRENT_DESKTOP=LXDE DESKTOP_SESSION=LinuxRunner
if [ "$qt_desktop" = 1 ]; then
 export XDG_CURRENT_DESKTOP=LXQt XDG_SESSION_TYPE=x11 QT_QPA_PLATFORM=xcb
 export QT_FORCE_STDERR_LOGGING=${QT_FORCE_STDERR_LOGGING:-1}
 echo 'DESKTOP_STARTUP: environment=linuxrunner components=openbox,lxqt-panel,pcmanfm-qt (Arch X11 desktop)'
fi
export XDG_DATA_DIRS="$base/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
fi
component_name() { [ "$environment" != plasma ] || { echo "Plasma session (plasma.log)"; return; }; case "$1" in "$wm") echo "window manager (wm.log)";; "$panel") echo "panel (panel.log)";; "$surface") echo "desktop surface (desktop.log)";; *) echo unknown;; esac; }
cleanup() { trap - EXIT; for pid in "$surface" "$panel" "$wm" "$conf"; do [ -z "$pid" ] || kill "$pid" 2>/dev/null || true; done; }
trap cleanup EXIT
if [ "$environment" = plasma ]; then
 command -v startplasma-x11 >/dev/null || { echo 'DESKTOP_STARTUP: missing=startplasma-x11; install KDE Plasma (plasma-desktop kwin-x11)'; exit 127; }
 # One process tree (ksmserver, KWin, plasmashell): it is the window manager, panel and desktop.
 # No systemd: Plasma's session manager starts its components itself.
 export XDG_CURRENT_DESKTOP=KDE XDG_SESSION_TYPE=x11 KDE_FULL_SESSION=true KDE_SESSION_VERSION=6 DESKTOP_SESSION=plasma
 # iOS locks the device itself: Plasma's own idle screen locker would put a Linux
 # password prompt over the desktop after a few idle minutes. First start of an
 # account only; a kscreenlockerrc the user already has is left as it is.
 plasma_config="${XDG_CONFIG_HOME:-$HOME/.config}"
 if mkdir -p "$plasma_config" && [ ! -e "$plasma_config/kscreenlockerrc" ]; then
  printf '[Daemon]\nAutolock=false\nLockOnResume=false\n' > "$plasma_config/kscreenlockerrc" && echo 'DESKTOP_STARTUP: plasma screen locker defaults written (autolock off; iOS locks the device)'
 fi
 startplasma-x11 > "$session/plasma.log" 2>&1 & wm=$!; panel=$wm; surface=$wm; limit=960   # Plasma needs minutes under the interpreter
 echo "DESKTOP_STARTUP: environment=plasma (experimental) session=$wm"
else
start_wm() { openbox --config-file "$base/config/openbox/rc.xml" >> "$session/wm.log" 2>&1 & wm=$!; }
if [ "$qt_desktop" = 1 ]; then
 start_panel() { lxqt-panel --config "$base/config/lxqt/panel.conf" >> "$session/panel.log" 2>&1 & panel=$!; }
elif command -v lxpanel >/dev/null; then
 start_panel() { GTK_THEME=Adwaita:dark lxpanel --profile LinuxRunner >> "$session/panel.log" 2>&1 & panel=$!; }
elif command -v xfce4-panel >/dev/null; then
 confbin=/usr/lib/xfce4/xfconf/xfconfd
 [ -x "$confbin" ] || confbin=/usr/libexec/xfce4/xfconf/xfconfd
 [ -x "$confbin" ] || { echo 'DESKTOP_STARTUP: xfconfd-missing'; exit 127; }
 "$confbin" > "$session/xfconf.log" 2>&1 & conf=$!
 start_panel() { GTK_THEME=Adwaita:dark xfce4-panel --disable-wm-check >> "$session/panel.log" 2>&1 & panel=$!; }
else echo 'DESKTOP_STARTUP: panel-missing'; exit 127; fi
start_surface() {
 if [ "$qt_desktop" = 1 ]; then pcmanfm-qt --profile LinuxRunner-X11 --desktop >> "$session/desktop.log" 2>&1 &
 else GTK_THEME=Adwaita:dark pcmanfm --profile LinuxRunner --desktop >> "$session/desktop.log" 2>&1 & fi
 surface=$!
}
start_wm; start_panel; start_surface
fi
# Supervision. A panel or desktop-surface crash must not end the session: the X
# server, window manager and open applications stay up and the component is
# restarted, at most $restart_limit times in a row (a run of $restart_window s
# or more resets the count). Every exit is reported with its status; restarts
# append to the component's log, so its first failure is kept. Past the limit
# the desktop continues without it (desktop-state: degraded=<roles>). The window
# manager is restarted the same way, but its final failure ends the session.
# Plasma is one process tree and is not restarted.
restart_limit=3 restart_window=120 failed=
wm_started=$(date +%s) panel_started=$(date +%s) surface_started=$(date +%s) wm_restarts=0 panel_restarts=0 surface_restarts=0
role_log() { case "$1" in wm) echo wm.log;; panel) echo panel.log;; *) echo desktop.log;; esac; }
role_name() { case "$1" in wm) echo "window manager (wm.log)";; panel) echo "panel (panel.log)";; *) echo "desktop surface (desktop.log)";; esac; }
write_degraded() {
 [ -f "$session/desktop-state" ] || return 0
 { grep -v -e '^degraded=' -e '^ready=' "$session/desktop-state" || true; echo "ready=0"; echo "degraded=$(echo $failed | tr ' ' ,)"; } > "$session/desktop-state.degraded"
 mv "$session/desktop-state.degraded" "$session/desktop-state"
}
supervise() {
 if [ "$environment" = plasma ]; then kill -0 "$wm" 2>/dev/null || { echo "$1: component_exited name=$(component_name "$wm") pid=$wm"; exit 1; }; return 0; fi
 for role in wm panel surface; do
  eval "pid=\$$role started=\$${role}_started restarts=\$${role}_restarts"
  [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null || continue
  status=0; wait "$pid" 2>/dev/null || status=$?
  write_degraded
  ran=$(( $(date +%s) - started )); [ "$ran" -lt "$restart_window" ] || restarts=0
  echo "$1: component_exited name=$(role_name "$role") pid=$pid status=$status ran=${ran}s"
  if [ "$restarts" -ge "$restart_limit" ]; then
   [ "$role" != wm ] || { echo "$1: component_failed name=$(role_name wm) restarts=$restarts; ending the desktop session"; exit 1; }
   echo "$1: component_failed name=$(role_name "$role") restarts=$restarts; the desktop continues without it"
   eval "$role="; failed="${failed:+$failed }$role"; write_degraded; continue
  fi
  restarts=$((restarts + 1)); sleep "$restarts"
  printf '\n=== LinuxRunner: restart %s/%s after exit status %s ===\n' "$restarts" "$restart_limit" "$status" >> "$session/$(role_log "$role")"
  "start_$role"; eval "${role}_started=$(date +%s) ${role}_restarts=$restarts pid=\$$role"
  echo "$1: component_restarted name=$(role_name "$role") pid=$pid attempt=$restarts/$restart_limit"
 done
}
# Ready: a window manager, plus a panel and a desktop surface unless that one has
# permanently failed (then the state says degraded=...).
desktop_ready() {
 ./desktop-probe > "$session/desktop-state.probe" || return 1
 awk -F= -v failed=" $failed " '{ v[$1] = $2 }
  END { complete = v["wm"] + 0 > 0 && v["panel"] + 0 > 0 && v["surface"] + 0 > 0 && failed == "  "; ok = v["wm"] + 0 > 0 && (v["panel"] + 0 > 0 || index(failed, " panel ")) && (v["surface"] + 0 > 0 || index(failed, " surface "))
        if (v["root_geometry"] != "") printf "root_geometry=%s\npanel_geometry=%s\nsurface_geometry=%s\n", v["root_geometry"], v["panel_geometry"], v["surface_geometry"];
        printf "wm=%s\npanel=%s\nsurface=%s\nready=%d\n", v["wm"], v["panel"], v["surface"], complete
        d = failed; gsub(/^ +| +$/, "", d); gsub(/ +/, ",", d); if (d != "") printf "degraded=%s\n", d
        exit !ok }' "$session/desktop-state.probe" > "$session/desktop-state.new"
}
i=0 started=$(date +%s)
echo "DESKTOP_STARTUP: waiting for window manager, panel and desktop (wm=$wm panel=$panel surface=$surface)"
until desktop_ready; do
 supervise DESKTOP_STARTUP
 [ ! -e "$session/stop" ] || exit 0
 i=$((i+1)); [ "$i" -lt "$limit" ] || { echo "DESKTOP_STARTUP: readiness_timeout after $(( $(date +%s) - started ))s (inspect wm/panel/desktop logs)"; cat "$session/desktop-state.new"; head -n 120 /proc/ish/tasks; exit 1; }; sleep .5
done
mv "$session/desktop-state.new" "$session/desktop-state"
echo "DESKTOP_STARTUP: ready=$(sed -n 's/^ready=//p' "$session/desktop-state") wm=PASS panel=$([ -n "$panel" ] && echo PASS || echo FAILED) surface=$([ -n "$surface" ] && echo PASS || echo FAILED) ready_after=$(( $(date +%s) - started ))s rendering=requires-frame-observation"
mkdir -p "$session/requests"
health_tick=0
while [ ! -e "$session/stop" ]; do
 supervise DESKTOP_SESSION
 health_tick=$((health_tick+1))
 if [ "$health_tick" -ge 10 ]; then
  health_tick=0
  if desktop_ready; then mv "$session/desktop-state.new" "$session/desktop-state"; fi
 fi
 for request in "$session"/requests/launch-*.sh; do
  [ -f "$request" ] && [ ! -L "$request" ] || continue
  name=${request##*/}; mv "$request" "$request.running"
  (code=0; /bin/sh "$request.running" >> "$session/application.log" 2>&1 || code=$?; printf '%s\n' "$code" > "$session/requests/$name.result"; rm -f "$request.running") &
  echo "DESKTOP_LAUNCH: request=$name started"
 done
 sleep .5
done

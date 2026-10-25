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
if [ "$environment" = linuxrunner ]; then
for tool in openbox pcmanfm; do command -v "$tool" >/dev/null || { echo "DESKTOP_STARTUP: missing=$tool; run Install Desktop Support"; exit 127; }; done
/bin/sh ./desktop-configure.sh
export XDG_CURRENT_DESKTOP=LXDE DESKTOP_SESSION=LinuxRunner
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
openbox --config-file "$base/config/openbox/rc.xml" > "$session/wm.log" 2>&1 & wm=$!
if command -v lxpanel >/dev/null; then
 GTK_THEME=Adwaita:dark lxpanel --profile LinuxRunner > "$session/panel.log" 2>&1 & panel=$!
elif command -v xfce4-panel >/dev/null; then
 confbin=/usr/lib/xfce4/xfconf/xfconfd
 [ -x "$confbin" ] || confbin=/usr/libexec/xfce4/xfconf/xfconfd
 [ -x "$confbin" ] || { echo 'DESKTOP_STARTUP: xfconfd-missing'; exit 127; }
 "$confbin" > "$session/xfconf.log" 2>&1 & conf=$!
 GTK_THEME=Adwaita:dark xfce4-panel --disable-wm-check > "$session/panel.log" 2>&1 & panel=$!
else echo 'DESKTOP_STARTUP: panel-missing'; exit 127; fi
GTK_THEME=Adwaita:dark pcmanfm --profile LinuxRunner --desktop > "$session/desktop.log" 2>&1 & surface=$!
fi
i=0 started=$(date +%s)
echo "DESKTOP_STARTUP: waiting for window manager, panel and desktop (wm=$wm panel=$panel surface=$surface)"
until ./desktop-probe --ready > "$session/desktop-state.new"; do
 for pid in "$wm" "$panel" "$surface"; do kill -0 "$pid" || { echo "DESKTOP_STARTUP: component_exited name=$(component_name "$pid") pid=$pid after $(( $(date +%s) - started ))s"; exit 1; }; done
 [ ! -e "$session/stop" ] || exit 0
 i=$((i+1)); [ "$i" -lt "$limit" ] || { echo "DESKTOP_STARTUP: readiness_timeout after $(( $(date +%s) - started ))s (inspect wm/panel/desktop logs)"; cat "$session/desktop-state.new"; head -n 120 /proc/ish/tasks; exit 1; }; sleep .5
done
mv "$session/desktop-state.new" "$session/desktop-state"
echo "DESKTOP_STARTUP: wm=PASS panel=PASS surface=PASS ready_after=$(( $(date +%s) - started ))s rendering=requires-frame-observation"
mkdir -p "$session/requests"
while [ ! -e "$session/stop" ]; do
 for pid in "$wm" "$panel" "$surface"; do kill -0 "$pid" || { echo "DESKTOP_SESSION: component_exited name=$(component_name "$pid") pid=$pid"; exit 1; }; done
 for request in "$session"/requests/launch-*.sh; do
  [ -f "$request" ] && [ ! -L "$request" ] || continue
  name=${request##*/}; mv "$request" "$request.running"
  (code=0; /bin/sh "$request.running" >> "$session/application.log" 2>&1 || code=$?; printf '%s\n' "$code" > "$session/requests/$name.result"; rm -f "$request.running") &
  echo "DESKTOP_LAUNCH: request=$name started"
 done
 sleep .5
done

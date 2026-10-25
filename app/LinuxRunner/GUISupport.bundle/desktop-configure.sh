#!/bin/sh
set -eu
cd "$(dirname "$0")"
base="$PWD/desktop"
[ "$(id -u)" = 0 ] || base="${XDG_DATA_HOME:-$HOME/.local/share}/linuxrunner/desktop"
mkdir -p "$base/config/openbox" "$base/config/lxpanel/LinuxRunner/panels" "$base/config/pcmanfm/LinuxRunner" "$base/share/themes/LinuxRunner/openbox-3" "$base/config/gtk-3.0" "$base/config/xfce4/xfconf/xfce-perchannel-xml"
# Dedicated component configuration: never replace guest home, Telegram/browser
# profiles or existing ~/.config. Publish defaults only when absent.
put() { [ -e "$2" ] || { cp "$1" "$2.new"; chmod 600 "$2.new"; mv "$2.new" "$2"; }; }
put desktop-openbox.xml "$base/config/openbox/rc.xml"
put desktop-panel.conf "$base/config/lxpanel/LinuxRunner/panels/panel"
put desktop-theme.conf "$base/share/themes/LinuxRunner/openbox-3/themerc"
if [ ! -e "$base/config/pcmanfm/LinuxRunner/desktop-items-0.conf" ]; then
 cat > "$base/config/pcmanfm/LinuxRunner/desktop-items-0.conf.new" <<EOF
[*]
wallpaper_mode=fit
wallpaper_common=1
wallpaper=$PWD/desktop-wallpaper.png
desktop_bg=#0b1425
desktop_fg=#e9f1ff
desktop_shadow=#000000
desktop_font=DejaVu Sans 11
show_wm_menu=1
show_documents=0
show_trash=1
show_mounts=0
EOF
 mv "$base/config/pcmanfm/LinuxRunner/desktop-items-0.conf.new" "$base/config/pcmanfm/LinuxRunner/desktop-items-0.conf"
fi
if [ ! -e "$base/config/gtk-3.0/settings.ini" ]; then
 cat > "$base/config/gtk-3.0/settings.ini.new" <<EOF
[Settings]
gtk-theme-name=Adwaita
gtk-application-prefer-dark-theme=1
gtk-icon-theme-name=Adwaita
gtk-font-name=DejaVu Sans 11
EOF
 mv "$base/config/gtk-3.0/settings.ini.new" "$base/config/gtk-3.0/settings.ini"
fi
put desktop-xfce-panel.xml "$base/config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
put desktop-pcmanfm.conf "$base/config/pcmanfm/LinuxRunner/pcmanfm.conf"
# Expose only named component profiles through the user's real XDG directory.
# Changing a panel process's XDG_CONFIG_HOME also changes every app it launches.
# Keep the original environment, and link owned profiles without overwriting any
# existing user path (including a deliberately customized/dangling symlink).
user_config=${XDG_CONFIG_HOME:-${HOME:?HOME is required}/.config}
case "$user_config" in /*) ;; *) echo 'DESKTOP_CONFIG: XDG_CONFIG_HOME must be absolute'; exit 2;; esac
profile_link() {
 destination=$2
 if [ ! -e "$destination" ] && [ ! -L "$destination" ]; then
  mkdir -p "$(dirname "$destination")"
  ln -s "$1" "$destination"
 fi
}
profile_link "$base/config/lxpanel/LinuxRunner" "$user_config/lxpanel/LinuxRunner"
profile_link "$base/config/pcmanfm/LinuxRunner" "$user_config/pcmanfm/LinuxRunner"
profile_link "$base/config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" "$user_config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
printf 'schema=1\nconfiguration=first-write-only\n' > "$base/configuration.meta.new"
mv "$base/configuration.meta.new" "$base/configuration.meta"
echo "DESKTOP_CONFIG: version=1 destination=$base user_files=preserved result=PASS"

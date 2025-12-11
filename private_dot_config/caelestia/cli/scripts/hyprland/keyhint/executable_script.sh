PATH_IMAGES="$HOME/.config/caelestia/store/keybinds"


service="${1:-hyprland}"
level="${2:-base}"

kitty -e swayimg -f -s 2.2 "$PATH_IMAGES/$service/$level.png"
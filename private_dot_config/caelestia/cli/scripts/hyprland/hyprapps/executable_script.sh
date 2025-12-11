# !/usr/bin/env bash
# scripts/hyprland/services/script.sh


color_picker() {
  hyprpicker -a -f hex -n -q
}


# Аргументы
method="${1:-clipboard}"    # Стандартный метод управления оболочкой

case "$method" in
  picker)                   color_picker            ;;
  *)                        echo "Error args"       ;;
esac
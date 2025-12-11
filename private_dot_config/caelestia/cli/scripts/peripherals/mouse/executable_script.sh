#!/usr/bin/env bash
# scripts/peripherals/mouse/script.sh

# IMPORTS
VarManager="$HOME/.config/caelestia/cli/scripts/hyprland/variables/VarManager.sh"

send_notify() {
  local body="$1"
  local icon="$2"
  local sound="$3"

  local FIFO="$HOME/.cache/caelestia/osd.fifo"

  # Формируем JSON одной строкой
  local json
  json=$(printf '{"group":"mouse","title":"Mouse","body":"%s","icon":"%s","timeout":2500,"sound":"%s","urgency":"normal"}\n' \
        "$body" "$icon" "$sound")

  # Записываем в FIFO
  printf '%s' "$json" > "$FIFO"
}

get_value() {
  echo "$($VarManager get "mouse_enabled")"
}

enable() {
  local notify="$1"

  $VarManager set "mouse_enabled" true
  hyprctl keyword "\$mouse_enabled" "true" -r
  
  if [ "$notify" == "true" ]; then
    send_notify "Enabled" "mouse" "toggle"
  fi
}

disable() {
  local notify="$1"

  $VarManager set "mouse_enabled" false
  hyprctl keyword "\$mouse_enabled" "false" -r

  if [ "$notify" == "true" ]; then
    send_notify "Disabled" "mouse-off" "toggle"
  fi
}

toggle() {
  local notify="$1"

  if [ "$(get_value)" == "true" ]; then
    disable "$notify"
  else
    enable "$notify"
  fi
  
}

# Аргументы
method="${1:-get}"    # Стандартный метод управления мышью
notify="${2:-true}"   # Уведомления

case "$method" in
  get)                get_value   "$notify"     ;;
  enable)             enable      "$notify"     ;;
  disable)            disable     "$notify"     ;;
  toggle)             toggle      "$notify"     ;;
  *)                  echo        "Error args"  ;;
esac
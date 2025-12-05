#!/usr/bin/env bash
# scripts/peripherals/wifi/script.sh

# IMPORTS
VarManager="$HOME/.config/caelestia/cli/scripts/hyprland/variables/VarManager.sh"

send_notify() {
  local body="$1"
  local icon="$2"
  local sound="$3"

  local FIFO="$HOME/.cache/caelestia/osd.fifo"

  # Формируем JSON одной строкой
  local json
  json=$(printf '{"group":"wifi","title":"Wi-Fi","body":"%s","icon":"%s","timeout":2500,"sound":"%s","urgency":"normal"}\n' \
        "$body" "$icon" "$sound")

  # Записываем в FIFO
  printf '%s' "$json" > "$FIFO"
}

get_value() {
  echo "$($VarManager get "wifi_enabled")"
}

enable() {
  local notify="$1"

  $VarManager set "wifi_enabled" true
  rfkill unblock wifi
  
  if [ "$notify" == "true" ]; then
    send_notify "Enabled" "wifi" "toggle"
  fi
}

disable() {
  local notify="$1"

  $VarManager set "wifi_enabled" false
  rfkill block wifi

  if [ "$notify" == "true" ]; then
    send_notify "Disabled" "wifi-off" "toggle"
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
method="${1:-get}"      # Стандартный метод управления Wi-Fi
notify="${2:-true}"     # Уведомления

case "$method" in
  get)                    get_value   "$notify"     ;;
  enable)                 enable      "$notify"     ;;
  disable)                disable     "$notify"     ;;
  toggle)                 toggle      "$notify"     ;;
  *)                      echo        "Error args"  ;;
esac
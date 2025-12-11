#!/usr/bin/env bash
# scripts/hyprland/idle/script.sh

send_notify() {
  local body="$1"
  local icon="$2"
  local sound="$3"

  local FIFO="$HOME/.cache/caelestia/osd.fifo"

  # Формируем JSON одной строкой
  local json
  json=$(printf '{"group":"hyprland","title":"Hyprland","body":"%s","icon":"%s","timeout":2500,"sound":"%s","urgency":"normal"}\n' \
        "$body" "$icon" "$sound")

  # Записываем в FIFO
  printf '%s' "$json" > "$FIFO"
}

device_sleep() {
    systemctl suspend
}

device_lock() {
    loginctl lock-session
}

display_power() {
    local status="${1:on}"

    case "$status" in
        on)     hyprctl dispatch dpms on    ;;
        off)    hyprctl dispatch dpms off   ;;
        *)      hyprctl dispatch dpms on    ;;
    esac
}

send_warning() {
    local status="$1"

    case "$status" in
        off)    send_notify "The device will be locked after 1 minute."     "sleep"     "warning"   ;;
        on)     send_notify "The device was unlocked"                       "unlock"    "toggle-2"  ;;
        *)      send_notify "The device was unlocked"                       "unlock"    "toggle-2"  ;;
    esac
}

# Аргументы
method="${1:-notify}"       # Стандартный метод управления оболочкой
arg_1="${2:-on}"            # Статус
notify="${2:-false}"        # Увдомления

case "$method" in
  sleep)                    device_sleep                "$notify"       ;;
  lock)                     device_lock                 "$notify"       ;;
  notify)                   send_warning    "$arg_1"    "$notify"       ;;
  display)                  display_power   "$arg_1"    "$notify"       ;;
  *)                        echo                        "Error args"    ;;
esac
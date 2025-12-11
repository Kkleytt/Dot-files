#!/usr/bin/env bash
# scripts/caelestia/shell/script.sh

send_notify() {
  local body="$1"
  local icon="$2"
  local sound="$3"

  local FIFO="$HOME/.cache/caelestia/osd.fifo"

  # Формируем JSON одной строкой
  local json
  json=$(printf '{"group":"notify","title":"Notify","body":"%s","icon":"%s","timeout":2500,"sound":"%s","urgency":"normal"}\n' \
        "$body" "$icon" "$sound")

  # Записываем в FIFO
  printf '%s' "$json" > "$FIFO"
}

get_value() {
    local notify="$1"
    local result=$(caelestia shell notifs isDndEnabled)
    if [[ "$notify" == true ]]; then
        [[ "$result" == false ]] && send_notify "Уведомления включены" "notifications" "pop"
    fi
    echo "$result"
}

enable() {
  local notify="$1"
  
  caelestia shell notifs enableDnd
  [[ "$notify" == true ]] && send_notify "Уведомления выключены" "notifications" "pop"
}

disable() {
  local notify="$1"

  caelestia shell notifs disableDnd
  [[ "$notify" == true ]] && send_notify "Уведомления включены" "notifications" "pop"
}

toggle() {
  local notify="$1"
  local status=$(get_value "false")
  
  [[ "$status" == true ]] && disable "$notify"
  [[ "$status" == false ]] && enable "$notify"
}

# Аргументы
method="${1:-toggle}"       # Стандартный метод управления оболочкой
notify="${2:-true}"         # Увдомления

case "$method" in
    get)                    get_value   "$notify"       ;;
    enable)                 enable      "$notify"       ;;
    disable)                disable     "$notify"       ;;
    toggle)                 toggle      "$notify"       ;;
    *)                      echo        "Error args"    ;;
esac

#!/usr/bin/env bash
# scripts/caelestia/shell/script.sh

send_notify() {
  local body="$1"
  local icon="$2"
  local sound="$3"

  local FIFO="$HOME/.cache/caelestia/osd.fifo"

  # Формируем JSON одной строкой
  local json
  json=$(printf '{"group":"caelestia-shell","title":"Caelestia","body":"%s","icon":"%s","timeout":2500,"sound":"%s","urgency":"normal"}\n' \
        "$body" "$icon" "$sound")

  # Записываем в FIFO
  printf '%s' "$json" > "$FIFO"
}

get_value() {
  if pgrep caelestia >/dev/null 2>&1 || pgrep quickshell >/dev/null 2>&1; then
    echo true
  else
    echo false
  fi
}

enable() {
  local notify="$1"

  caelestia shell -d

  if [ "$notify" == "true" ]; then
    send_notify "Start shell" "shell" "system"
  fi
}

disable() {
  local notify="$1"

  if [ "$notify" == "true" ]; then
    send_notify "Stop shell" "shell-off" "system"
  fi

  caelestia-shell kill  
}

restart() {
  local notify="$1"

  if [ "$notify" == "true" ]; then
    send_notify "Restart shell" "shell-restart" "system"
  fi

  echo "1"
  caelestia-shell kill
  echo "2"
  sleep 2
  echo "3"
  caelestia shell -d
  echo "4"
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
method="${1:-restart}"    # Стандартный метод управления оболочкой
notify="${2:-false}"       # Увдомления

case "$method" in
  enable)                 enable      "$notify"     ;;
  disable)                disable     "$notify"     ;;
  restart)                restart     "$notify"     ;;
  toggle)                 toggle      "$notify"     ;;
  *)                      echo        "Error args"  ;;
esac
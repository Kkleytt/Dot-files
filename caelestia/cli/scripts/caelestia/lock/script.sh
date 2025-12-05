#!/usr/bin/env bash
# scripts/caelestia/lock/script.sh

send_notify() {
  local body="$1"
  local icon="$2"
  local sound="$3"

  local FIFO="$HOME/.cache/caelestia/osd.fifo"

  # Формируем JSON одной строкой
  local json
  json=$(printf '{"group":"caelestia-lock","title":"Caelestia","body":"%s","icon":"%s","timeout":2500,"sound":"%s","urgency":"normal"}\n' \
        "$body" "$icon" "$sound")

  # Записываем в FIFO
  printf '%s' "$json" > "$FIFO"
}

lock() {
  local notify="$1"

  caelestia shell lock lock
  
  if [ "$notify" == "true" ]; then
    send_notify "Lock" "lock" "lock"
  fi
}

unlock() {
  local notify="$1"

  caelestia shell lock unlock

  if [ "$notify" == "true" ]; then
    send_notify "Unlock" "unlock" "lock"
  fi
}

islocked() {
  local notify="$1"

  value="$(caelestia shell lock isLocked)"
  echo "$value"

  if [ "$notify" == "true" ]; then
    send_notify "Lock - $value" "info" "pop"
  fi
}

# Аргументы
method="${1:-lock}"         # Стандартный метод управления блокировкой системы
notify="${2:-true}"         # Уведомления

case "$method" in
  lock)                     lock          "$notify"     ;;
  unlock)                   unlock        "$notify"     ;;
  islocked)                 islocked      "$notify"     ;;
  *)                        echo          "Error args"  ;;
esac
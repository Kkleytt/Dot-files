#!/usr/bin/env bash
# scripts/media/screenrecord/script.sh

send_notify() {
  local body="$1"
  local icon="$2"
  local sound="${3:-"system"}"

  local FIFO="$HOME/.cache/caelestia/osd.fifo"

  # Формируем JSON одной строкой
  local json
  json=$(printf '{"group":"screenrecord","title":"Screenrecord","body":"%s","icon":"%s","timeout":2500,"sound":"%s","urgency":"normal"}\n' \
        "$body" "$icon" "$sound")

  # Записываем в FIFO
  printf '%s' "$json" > "$FIFO"
}

is_recording() {
  # ищем процессы gpu-screen-recorder (gsr) или kms-сервер
  pgrep -f "gsr-kms-server|gpu-screen-recorder" >/dev/null 2>&1
}


record() {
  local area="" sound="" pause=""

  # Разбираем аргументы в любом порядке
  for arg in "$@"; do
    case "$arg" in
      -r) area="-r" ;;
      -s) sound="-s" ;;
      -p) pause="-p" ;;
    esac
  done

  # Запуск записи
  caelestia record $area $sound $pause

  # Уведомления
  [[ "$sound" == "-s" ]] && send_notify "Attention record sound" "microphone" "system"

  if is_recording; then
    [[ "$pause" == "-p" ]] && send_notify "Attention record pause" "pause" "pop"
  fi
}

# === Запуск ===
record "$@"

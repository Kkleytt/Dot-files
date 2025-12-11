#!/usr/bin/env bash
# scripts/media/player/script.sh

send_notify() {
  local title="$1"
  local body="$2"
  local icon="$3"
  local sound="$4"

  local FIFO="$HOME/.cache/caelestia/osd.fifo"

  # Формируем JSON одной строкой
  local json
  json=$(printf '{"group":"player","title":"%s","body":"%s","icon":"%s","timeout":2500,"sound":"%s","urgency":"normal"}\n' \
        "$title" "$body" "$icon" "$sound")

  # Записываем в FIFO
  printf '%s' "$json" > "$FIFO"
}

get_artist() {
  echo "$(playerctl metadata artist)" 
}

get_title() {
  echo "$(playerctl metadata title)"
}

play() {
  local notify="$1"

  playerctl play
  if [[ "$notify" == "true" ]]; then
    send_notify "$(get_artist)" "$(get_title)" "play" "player"
  fi
}

pause() {
  local notify="$1"

  playerctl pause
  if [[ "$notify" == "true" ]]; then
    send_notify "$(get_artist)" "$(get_title)" "pause" "player"
  fi
}

toggle() {
  local notify="$1"

  if [[ "$(playerctl status)" == "Playing" ]]; then
    pause "$notify"
    return
  fi
  play "$notify"
}

stop() {
  local notify="$1"

  playerctl stop
  if [[ "$notify" == "true" ]]; then
    send_notify "Player" "Stop" "stop" "player"
  fi
}

next(){
  local notify="$1"

  playerctl next
  if [[ "$notify" == "true" ]]; then
    send_notify "$(get_artist)" "$(get_title)" "next" "player"
    sleep 2
    send_notify "$(get_artist)" "$(get_title)" "next" "player"
  fi
}

previous() {
  local notify="$1"

  playerctl previous
  if [[ "$notify" == "true" ]]; then
    send_notify "$(get_artist)" "$(get_title)" "previous" "player"
    sleep 2
    send_notify "$(get_artist)" "$(get_title)" "previous" "player"
  fi
}

# Аргументы
method="${1:-get}"        # Стандартный метод управления плеером
notify="${2:-true}"       # Уведомления

case "$method" in
  play)                   play      "$notify"     ;;
  pause)                  pause     "$notify"     ;;
  toggle)                 toggle    "$notify"     ;;
  stop)                   stop      "$notify"     ;;
  next)                   next      "$notify"     ;;
  prev)                   previous  "$notify"     ;;
  *)                      echo      "Error args"  ;;
esac

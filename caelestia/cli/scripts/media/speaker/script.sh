#!/usr/bin/env bash
# scripts/media/speaker/script.sh

send_notify() {
  local body="$1"
  local icon="$2"
  local sound="$3"

  local FIFO="$HOME/.cache/caelestia/osd.fifo"

  # Формируем JSON одной строкой
  local json
  json=$(printf '{"group":"speaker","title":"Speaker","body":"%s","icon":"%s","timeout":2500,"sound":"%s","urgency":"normal"}\n' \
        "$body" "$icon" "$sound")

  # Записываем в FIFO
  printf '%s' "$json" > "$FIFO"
}

get_value() {
  # Один вызов pamixer вместо двух
  local mute
  mute=$(pamixer --get-mute)
  if [[ "$mute" == "true" ]]; then
    echo "mute"
  else
    pamixer --get-volume
  fi
}

get_icon() {
  local current="$1"
  if [[ "$current" == "mute" ]]; then
    echo "volume-off"
    return
  fi

  local thresholds=(0 15 25 40 50 65 75 90 100 115 125 140 150 165 175 190 200)
  local icon="volume-200"

  for t in "${thresholds[@]}"; do
    if (( current <= t )); then
      icon="volume-$t"
      break
    fi
  done

  echo "$icon"
}

enable() {
  local notify="$1"
  pamixer -u
  # if [[ "$notify" == true ]]; then
  #   send_notify "Unmute" "$(get_icon "$(get_value)")" "toggle"
  # fi
}

disable() {
  local notify="$1"
  pamixer -m
  # if [[ "$notify" == true ]]; then
  #   send_notify "Mute" "volume-off" "toggle"
  # fi
}

toggle() {
  local notify="$1"
  local current_state
  current_state=$(get_value)
  if [[ "$current_state" == "mute" ]]; then
    enable "$notify"
  else
    disable "$notify"
  fi
}

set_value() {
  local value="$1"
  local limit="$2"
  local notify="$3"

  pamixer --set-volume "$value" --allow-boost --set-limit "$limit"

  # if [[ "$notify" == true ]]; then
  #   send_notify "$value %" "$(get_icon "$value")" "volume"
  # fi
}

up_value() {
  local step="$1"
  local limit="$2"
  local notify="$3"

  local current_value
  current_value=$(get_value)
  
  if [[ "$current_value" == "mute" ]]; then
    enable "$notify"
  fi
  
  local new_value=$(( current_value + step ))

  local remainder=$(( current_value % step ))
  (( remainder != 0 )) && new_value=$(( current_value + step - remainder ))
  (( new_value > limit )) && new_value=$limit

  set_value "$new_value" "$limit" "$notify"
}

down_value() {
  local step="$1"
  local limit="$2"
  local notify="$3"

  local current_value
  current_value=$(get_value)

  if [[ "$current_value" == "mute" ]]; then
    enable "$notify"
  fi
  
  local new_value=$(( current_value - step ))

  local remainder=$(( current_value % step ))
  (( remainder != 0 )) && new_value=$(( current_value - remainder ))
  (( new_value < 0 )) && new_value=0

  set_value "$new_value" "$limit" "$notify"
}

# Аргументы
method="${1:-get}"        # Станадртный метод управления громкостью
arg_1="${2:-5}"           # Стандартный шаг изменения громкости
arg_2="${3:-200}"         # Стандартный лимит громкости
notify="${4:-false}"      # Уведомления

case "$method" in
  get)                    get_value                       "$notify" ;;
  enable)                 enable                          "$notify" ;;
  disable)                disable                         "$notify" ;;
  toggle)                 toggle                          "$notify" ;;
  set)                    set_value   "$arg_1"  "$arg_2"  "$notify" ;;
  up)                     up_value    "$arg_1"  "$arg_2"  "$notify" ;;
  down)                   down_value  "$arg_1"  "$arg_2"  "$notify" ;;
  *)                      echo        "Error args"                  ;;
esac
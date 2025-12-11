#!/usr/bin/env bash
# scripts/media/brightness/script.sh

send_notify() {
  local body="$1"
  local icon="$2"
  local sound="$3"

  FIFO="$HOME/.cache/caelestia/osd.fifo"

  local json
  json=$(printf '{"group":"brightness","title":"Brightness","body":"%s","icon":"%s","timeout":2500,"sound":"%s","urgency":"normal"}\n' \
        "$body" "$icon" "$sound")

  printf '%s' "$json" > "$FIFO"
}

get_value() {
  local float_value=$(caelestia shell brightness get)
  value=$(awk -v v="$float_value" 'BEGIN { printf "%.2f", v*100 }')
  int_value=$(awk -v v="$value" 'BEGIN { print int(v) }')

  echo "$int_value"
}

get_icon() {
  local current="$1"
  local thresholds=(0 20 40 60 80 100)
  local icon="brightness-100"

  for t in "${thresholds[@]}"; do
    if (( current <= t )); then
      icon="brightness-$t"
      break
    fi
  done

  echo "$icon"
}

set_value() {
  local value="$1"
  local notify="$2"

  (( value < 0 )) && value=0
  (( value > 100 )) && value=100
  float_value=$(printf "%.2f" "$(echo "$value / 100" | bc -l)")

  caelestia shell brightness set $float_value

  # if [[ "$notify" == true ]]; then
  #   send_notify "$value %" "$(get_icon "$value")" "brightness"
  # fi
}

up_value() {
  local step="$1"
  local notify="$2"

  local current_value
  current_value=$(get_value)

  local new_value=$(( current_value + step ))

  local remainder=$(( current_value % step ))
  (( remainder != 0 )) && new_value=$(( current_value + step - remainder ))
  (( new_value > 100 )) && new_value=100

  set_value "$new_value" "$notify"
}

down_value() {
  local step="$1"
  local notify="$2"

  local current_value
  current_value=$(get_value)

  local new_value=$(( current_value - step ))

  local remainder=$(( current_value % step ))
  (( remainder != 0 )) && new_value=$(( current_value - remainder ))
  (( new_value < 0 )) && new_value=0

  set_value "$new_value" "$notify"
}

cycle_value() {
  local steps="$1"
  local notify="$2"

  local current_value
  current_value=$(get_value)

  local step_size=$(( 100 / (steps - 1) ))
  local levels=()
  for ((i=0; i<steps; i++)); do
    levels+=( $(( i * step_size )) )
  done

  local next=${levels[0]}
  echo "${levels[@]}"
  for lvl in "${levels[@]}"; do
    if (( current_value < lvl )); then
      echo "$lvl" "$current_value"
      next=$lvl
      break
    fi
  done

  set_value "$next" "$notify"
}

# Аргументы
method="${1:-get}"      # Стандартный метод управления яркостью (GET) 
arg_2="${2:-5}"         # Стандартный шаг изменения яркости (%)
notify="${3:-false}"    # Уведомления (true / false)

case "$method" in
  get)                  get_value ;;
  set)                  set_value       "$arg_2"  "$notify"     ;;
  up)                   up_value        "$arg_2"  "$notify"     ;;
  down)                 down_value      "$arg_2"  "$notify"     ;;
  cycle)                cycle_value     "$arg_2"  "$notify"     ;;
  *)                    echo                      "Error args"  ;;
esac

#!/usr/bin/env bash
# scripts/peripherals/keyboard/script.sh

# IMPORTS
VarManager="$HOME/.config/caelestia/cli/scripts/hyprland/variables/script.sh"

send_notify() {
  local body="$1"
  local icon="$2"
  local sound="$3"
  local timeout="${4:-2500}"
  local group="${5:-keyboard}"

  local FIFO="$HOME/.cache/caelestia/osd.fifo"

  # Формируем JSON одной строкой
  local json
  json=$(printf '{"group":"%s","title":"Keyboard","body":"%s","icon":"%s","timeout":%s,"sound":"%s","urgency":"normal"}\n' \
        "$group" "$body" "$icon" "$timeout" "$sound")

  # Записываем в FIFO
  printf '%s' "$json" > "$FIFO"
}

get_value() {
  echo "$($VarManager get "keyboard_enabled")"
}

enable() {
  local notify="$1"

  $VarManager set "keyboard_enabled" true
  hyprctl keyword "\$keyboard_enabled" "true" -r
  
  if [ "$notify" == "true" ]; then
    send_notify "Enabled" "keyboard" "toggle"
  fi
}

disable() {
  local notify="$1"

  $VarManager set "keyboard_enabled" false
  hyprctl keyword "\$keyboard_enabled" "false" -r

  if [ "$notify" == "true" ]; then
    send_notify "Disabled" "keyboard-off" "toggle"
  fi
}

layout() {
  local mode="${1:-adaptive}"
  local target_layout="$2"
  local notify="$3"
  local settings_file="$($VarManager get userConfigs)/UserSettings.conf"
  echo "$settings_file"

  # Игнорируемые устройства
  local -a ignore_patterns=("Bluetooth Speaker" "--(avrcp)" "Other Device Name")

  # Текущая раскладка (с защитой)
  local current_layout
  current_layout="$($VarManager get "keyboard_layout" 2>/dev/null || echo "ru")"

  # Если пусто или неизвестно — fallback на us
  if [[ -z "$current_layout" || "$current_layout" != "us" && "$current_layout" != "ru" ]]; then
    echo "Layout status unavailable, defaulting to 'us'"
    current_layout="ru"
  fi
  echo "Current layout: $current_layout"

  local -a layouts=(us ru)
  local new_layout="$current_layout"
  local next_index=0

  if [[ "$mode" == "adaptive" ]]; then
    # циклическое переключение
    for i in "${!layouts[@]}"; do
      if [[ "${layouts[i]}" == "$current_layout" ]]; then
        next_index=$(( (i + 1) % ${#layouts[@]} ))
        break
      fi
    done
    new_layout="${layouts[next_index]}"
  else
    # конкретная раскладка
    for i in "${!layouts[@]}"; do
      if [[ "${layouts[i]}" == "$target_layout" ]]; then
        next_index="$i"
        new_layout="$target_layout"
        break
      fi
    done
  fi

  echo "Switching to layout: $new_layout"

  # Применяем ко всем клавиатурам, кроме игнорируемых
  while IFS= read -r name; do
    for pat in "${ignore_patterns[@]}"; do
      [[ "$name" == *"$pat"* ]] && continue 2
    done
    if ! hyprctl switchxkblayout "$name" "$next_index"; then
      echo "Failed on device: $name" >&2
      # вместо exit 1 — fallback на us
      hyprctl switchxkblayout "$name" 0
    fi
  done < <(hyprctl devices -j | jq -r '.keyboards[].name')

  # Сохраняем и уведомляем
  $VarManager set "keyboard_layout" "$new_layout"
  if [[ "$notify" == true ]]; then
    send_notify "Switch to ${new_layout^^}" "language" "keyboard" 500 "language"
  fi
}


get_backlight() {
  local info current max percent
  info=$(brightnessctl -d '*::kbd_backlight' i 2>/dev/null)

  # Извлекаем current и max
  current=$(echo "$info" | awk '/Current brightness/ {print $3}')
  max=$(echo "$info" | awk '/Max brightness/ {print $3}')

  echo "$current $max"
}

backlight() {
  local direction="${1:-"up"}"
  local notify="$2"


  if [[ "$direction" == "up" ]]; then
    brightnessctl -d '*::kbd_backlight' set "+10%" >/dev/null
  elif [[ "$direction" == "down" ]]; then
    brightnessctl -d '*::kbd_backlight' set "10-%" >/dev/null
  else
    echo "Invalid direction. Use 'up' or 'down'."
  fi

  # Обновляем значение и уведомление
  read -r current max <<< "$(get_backlight)"
  percent=$(( current * 100 / max))

  if (( percent < 15 )); then
    icon="backlight-off"
  elif (( percent < 70 )); then
    icon="backlight-low"
  else
    icon="backlight-high"
  fi
  
  send_notify "Backlight $percent%" $icon "toggle"
}

toggle() {
  local notify="$1"

  if [ "$(get_value)" == "true" ]; then
    disable "$notify"
  else
    enable "$notify"
  fi
  sleep 5.0
  enable "$notify"
  
}

# Аргументы
method="${1:-get}"        # Стандартный метод управления клавиатурой
arg_1="${2:-adaptive}"    # Режим смены раскладки / Направление смены подсветки
arg_2="${3:-us}"          # Целевая раскладка
notify="${4:-true}"       # Уведомления

case "$method" in
  get)                    get_value                       "$notify"   ;;
  enable)                 enable                          "$notify"   ;;
  disable)                disable                         "$notify"   ;;
  toggle)                 toggle                          "$notify"   ;;
  layout)                 layout      "$arg_1"  "$arg_2"  "false"     ;;
  backlight)              backlight   "$arg_1"            "$notify"   ;;
  *)                      echo        "Error args"                    ;;
esac
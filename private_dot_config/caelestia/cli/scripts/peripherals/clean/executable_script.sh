#!/usr/bin/env bash
# scripts/peripherals/all/script.sh

# IMPORTS
VarManager="$HOME/.config/caelestia/cli/scripts/hyprland/variables/VarManager.sh"

send_notify() {
  local title="$1"
  local body="$2"
  local icon="$3"
  local sound="$4"
  local timeout="${5:-2500}"

  local FIFO="$HOME/.cache/caelestia/osd.fifo"

  # Формируем JSON одной строкой
  local json
  json=$(printf '{"group":"peripherals","title":"Peripherals","body":"%s","icon":"%s","timeout":%s,"sound":"%s","urgency":"normal"}\n' \
        "$body" "$icon" "$timeout" "$sound")

  # Записываем в FIFO
  printf '%s' "$json" > "$FIFO"
}

get_value() {
  echo "Touchscreen: $($VarManager get "touchscreen_enabled")"
  echo "Touchpad: $($VarManager get "touchpad_enabled")"
  echo "Mouse: $($VarManager get "mouse_enabled")"
  echo "Keyboard: $($VarManager get "keyboard_enabled")"
  echo "Wi-Fi: $($VarManager get "wifi_enabled")"
  echo "Bluetooth: $($VarManager get "bluetooth_enabled")"
}

enable() {
  local notify="$1"

  rfkill unblock bluetooth
  rfkill unblock wifi

  $VarManager set "touchscreen_enabled" true
  hyprctl keyword "\$touchscreen_enabled" "true" -r

  $VarManager set "touchpad_enabled" true
  hyprctl keyword "\$touchpad_enabled" "true" -r

  $VarManager set "mouse_enabled" true
  hyprctl keyword "\$mouse_enabled" "true" -r

  $VarManager set "keyboard_enabled" true
  hyprctl keyword "\$keyboard_enabled" "true" -r

  if [[ "$notify" == true ]]; then
    send_notify  "Peripherals" "All enabled" "usb" "drop"
  fi
}

timer() {
  # Универсальная функция переключения устройств
  toggle_all_devices() {
    local status="$1"
    local devices=("keyboard" "touchpad" "mouse" "touchscreen")

    for dev in "${devices[@]}"; do
      if [ "$($VarManager get "clean_${dev}_mode")" == "true" ]; then
        $VarManager set "${dev}_enabled" "$status"
        hyprctl keyword "\$${dev}_enabled" "$status" -r
      fi
    done

    if [ "$status" == "true" ]; then
      brightnessctl set 40%
    else
      brightnessctl set 0%
    fi
  }
  
  local clean_time="${1:-120}"
  local clean_time_canceled="${2:-5}"

  # Параметры
  local clean_status

  # Включаем режим ожидания
  $VarManager set "clean_status" true
  send_notify "Sure?" "Press again within $clean_time_canceled seconds to cancel" "danger" "error-2"
  (
    sleep "$clean_time_canceled"
    if [ "$($VarManager get "clean_status")" == "true" ]; then
      $VarManager set "clean_status" false

      toggle_all_devices "false"
      send_notify "Peripherals blocked" "Devices blocked for $clean_time seconds" "block" "drop" $(( clean_time * 1000))

      sleep "$clean_time"

      toggle_all_devices "true"
      send_notify "Peripherals unblocked" "Devices unblocked" "unblock" "drop"
    fi
  ) &
}

ui() {
    ROFI_CMD="rofi -dmenu -i -matching normal -config $HOME/.config/rofi/configs/power.rasi"
    options=(
        "10"
        "30"
        "60"
        "120"
        "300"
        "Cancel"
    )
    
    # Показываем меню
    choice="$(printf '%s\n' "${options[@]}" | eval "$ROFI_CMD")"
    [ -z "$choice" ] && exit 0
    
    case "$choice" in
        Cancel) exit 0 ;;
        10) timer "$choice" ;;
        30) timer "$choice" ;;
        60) timer "$choice" ;;
        120) timer "$choice" ;;
        300) timer "$choice" ;;
        *) echo "Error args" ;;
    esac
}


# Аргументы
method="${1:-ui}"         # Стандартный метод управления 
notify="${2:-true}"       # Уведомления


if [ "$($VarManager get "clean_status")" == "true" ]; then
  $VarManager set "clean_status" false
  send_notify "Peripherals" "Cancel clean mode" "cancel" "drop"
  exit 0
fi

case "$method" in
  get)                    get_value   "$notify"     ;;
  enable)                 enable      "$notify"     ;;
  timer)                  timer                     ;;
  ui)                     ui                        ;;              
  *)                      echo        "Error args"  ;;
esac
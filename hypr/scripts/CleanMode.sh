#!/bin/bash

# Список устройств, которые нужно отключить
DEVICE_LIST=("at-translated-set-2-keyboard" "power-button" "sleep-button" "touchpad" "touchscreen")

# Установка переменной окружения, если не задана
if [ -z "$XDG_RUNTIME_DIR" ]; then
  export XDG_RUNTIME_DIR=/run/user/$(id -u)
fi

# Отключение устройств
for DEVICE in "${DEVICE_LIST[@]}"; do
  hyprctl keyword "device:$DEVICE:enabled" 0
done

# Ждать 5 минут
sleep 10

# Включение устройств обратно
for DEVICE in "${DEVICE_LIST[@]}"; do
  hyprctl keyword "device:$DEVICE:enabled" 1
done

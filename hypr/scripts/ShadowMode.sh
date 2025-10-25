#!/bin/bash

# Status methods
volume_status=true
microphone_status=true
display_status=true
display_default=40
display_dark=0
block_status=true
change_desktop_status=true
kill_bar_status=true

check_shadow() {
    # 1. Проверка микрофона
    local mic_muted
    mic_muted=$(pamixer --default-source --get-mute 2>/dev/null)
    [[ "$mic_muted" != "true" ]] && echo "!Int" && return 0

    # 2. Проверка динамиков
    local speaker_muted
    speaker_muted=$(pamixer --get-mute 2>/dev/null)
    [[ "$speaker_muted" != "true" ]] && echo "!Out" && return 0

    # 3. Проверка яркости
    local brightness
    brightness=$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%')
    # Если brightnessctl недоступен или яркость > 0
    if [[ -z "$brightness" ]] || [[ "$brightness" -ne 0 ]]; then
        echo "!Bri"
        return 0
    fi

    # 4. Проверка: запущен ли Caelystia Shell?
    local config_file="$HOME/.config/caelestia/shell.json"
    current=$(jq -r '.bar.persistent' "$config_file" 2>/dev/null)
    if [[ "$current" == "true" ]]; then
        echo "!Bar"
        return 0
    fi

    # 5. Проверка: на каком workspace мы находимся?
    local current_ws
    current_ws=$(hyprctl monitors -j 2>/dev/null | jq -r '.[0].activeWorkspace.id // empty')

    # Если не удалось определить — считаем "не тень"
    if [[ -z "$current_ws" ]] || ! [[ "$current_ws" =~ ^[0-9]+$ ]]; then
        echo "!WS"
        return 0
    fi

    # Если workspace в диапазоне 1–50 → не тень
    if [[ "$current_ws" -ge 1 ]] && [[ "$current_ws" -le 50 ]]; then
        echo "!WS"
        return 0
    fi

    return 1
}

volume_mute() {
    local enable_shadow="$1"

    if [ "$enable_shadow" -eq 0 ]; then
        echo "Muting speakers"
        pamixer -m >/dev/null
    else
        echo "Unmuting speakers"
        pamixer -u >/dev/null
    fi
}

microphone_mute() {
    local enable_shadow="$1"

    if [ "$enable_shadow" -eq 0 ]; then
        echo "Muting microphone"
        pamixer --default-source -m >/dev/null
    else
        echo "Unmuting microphone"
        pamixer --default-source -u >/dev/null
    fi
}

display_mute() {
    local enable_shadow="$1"

    if [ "$enable_shadow" -eq 0 ]; then
        echo "Setting display to dark mode (${display_dark}%)"
        brightnessctl set "${display_dark}%" >/dev/null
    else
        echo "Restoring display brightness (${display_default}%)"
        brightnessctl set "${display_default}%" >/dev/null
    fi
}

change_desktop() {
    local status_shadow="$1"

    if [ "$status_shadow" -eq 0 ]; then
        echo "Block desktop"
        hyprctl dispatch workspace 100 >/dev/null
    else
        echo "Unblock desktop"
        hyprctl dispatch workspace 1 >/dev/null
    fi
}

block_display() {
    local enable_shadow="$1"

    if [ "$enable_shadow" -eq 0 ]; then
        echo "Blocking display"
        hyprctl dispatch global "caelestia:lock"
    fi
}

kill_bar() {
    local status_shadow="$1"
    local config_file="$HOME/.config/caelestia/shell.json"

    if [[ -f "$config_file" ]]; then
        if ! command -v jq >/dev/null 2>&1; then
                echo "Error: 'jq' is required to modify JSON config." >&2
                return 1
        fi

        if [ "$status_shadow" -eq 0 ]; then
            echo "Block bar"
            jq '.bar.persistent = false' "$config_file" > "$config_file.tmp" && mv "$config_file.tmp" "$config_file"
        else
            echo "Unblock bar"
            jq '.bar.persistent = true' "$config_file" > "$config_file.tmp" && mv "$config_file.tmp" "$config_file"
        fi

    else
        echo "Config file not found: $config_file" >&2
    fi
}

# Определяем, в теневом ли режиме система
if check_shadow; then
    status_shadow=0
else
    status_shadow=1
fi

echo "Shadow toggle target: $([ "$status_shadow" -eq 1 ] && echo "ON" || echo "OFF")"

# Включаем/Отключаем звук динамиков
if [ "$volume_status" = "true" ]; then
    volume_mute "$status_shadow"
fi
true
# Включаем/Отключаем звук микрофона 
if [ "$microphone_status" = "true" ]; then
    microphone_mute "$status_shadow"
fi

# Закрываем/Открываем панель
if [ "$kill_bar_status" = "true" ]; then
    kill_bar "$status_shadow"
fi

# Включаем/Отключаем дисплей (яркость до 0%)
if [ "$display_status" = "true" ]; then
    display_mute "$status_shadow"
fi

# Переключаем рабочий стол
if [ "$change_desktop_status" = "true" ]; then
    change_desktop "$status_shadow"
fi

# Блокируем/Разблокируем дисплей
if [ "$block_status" = "true" ]; then
    block_display "$status_shadow"
fi


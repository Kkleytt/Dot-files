#!/bin/bash

# Status methods
volume_status=true
microphone_status=true
display_status=true
display_default=40
display_dark=0
block_status=true

check_shadow() {
    local mic_muted=$(pamixer --default-source --get-mute 2>/dev/null)
    local speaker_muted=$(pamixer --get-mute 2>/dev/null)
    local brightness=$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%')

    # Если pamixer недоступен, считаем как "не muted"
    [[ "$mic_muted" != "true" ]] && return 1
    [[ "$speaker_muted" != "true" ]] && return 1
    [[ "$brightness" != 0 ]] && return 1

    return 0  # всё выключено → теневой режим
}

volume_mute() {
    local enable_shadow="$1"  # "0" = shadow ON (mute), "1" = shadow OFF (unmute)
    if [ "$enable_shadow" -eq 1 ]; then
        echo "Muting speakers"
        pamixer -m >/dev/null
    else
        echo "Unmuting speakers"
        pamixer -u >/dev/null
    fi
}

microphone_mute() {
    local enable_shadow="$1"
    if [ "$enable_shadow" -eq 1 ]; then
        echo "Muting microphone"
        pamixer --default-source -m >/dev/null
    else
        echo "Unmuting microphone"
        pamixer --default-source -u >/dev/null
    fi
}

display_mute() {
    local enable_shadow="$1"

    if [ "$enable_shadow" -eq 1 ]; then
        echo "Setting display to dark mode (${display_dark}%)"
        brightnessctl set "${display_dark}%" >/dev/null
    else
        echo "Restoring display brightness (${display_default}%)"
        brightnessctl set "${display_default}%" >/dev/null
    fi
}

block_display() {
    local enable_shadow="$1"

    if [ "$enable_shadow" -eq 1 ]; then
        echo "Blocking display"
        hyprctl dispatch global "caelestia:lock"
    fi
}

# Определяем, в теневом ли режиме система
if check_shadow; then
    status_shadow=0  # в теневом режиме → нужно ВКЛЮЧИТЬ всё
else
    status_shadow=1  # не в теневом → нужно ВЫКЛЮЧИТЬ всё
fi

echo "Shadow toggle target: $([ "$status_shadow" -eq 0 ] && echo "ON" || echo "OFF")"

# Применяем изменения в зависимости от настроек
if [ "$volume_status" = "true" ]; then
    volume_mute "$status_shadow"
fi

if [ "$microphone_status" = "true" ]; then
    microphone_mute "$status_shadow"
fi

if [ "$display_status" = "true" ]; then
    display_mute "$status_shadow"
fi

if [ "$block_status" = "true" ]; then
    block_display "$status_shadow"
fi
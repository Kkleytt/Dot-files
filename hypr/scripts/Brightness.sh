#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit   💫 ---- */  ##
# Script for Monitor backlights (if supported) using brightnessctl

iDIR="$HOME/.config/swaync/icons"
notification_timeout=1000
send_notify=true
BRI_STEP_SIZE=5
CYCLE_LEVELS=(0 25 50 75 100)

# Отправка уведомлений
send_notification() {
    local brightness=$1
    local icon_path=$2

    if [ $send_notify == "true" ]; then
        notify-send -e \
            -h string:x-canonical-private-synchronous:brightness_notif \
            -h int:value:"$brightness" \
            -u low \
            -i "$icon_path" \
            "Screen" "Brightness: ${brightness}%"
    fi
}

# Получение значения яркости
get_brightness() {
    brightnessctl -m | cut -d, -f4 | tr -d '%'
}

# Получение иконки
get_icon_path() {
    local brightness=$1
    local level=$(( (brightness + 19) / 20 * 20 ))  # Round up to next 20
    if (( level > 100 )); then
        level=100
    fi
    echo "$iDIR/brightness-${level}.png"
}

# Функция округления громкости
round_brightness() {
    local brightness=$1
    local direction=$2 # "up" или "down"
    local step=$3

    if [[ "$direction" == "up" ]]; then
        # Округление вверх до кратного STEP_SIZE
        echo $(( ((brightness + step - 1) / step) * step ))
    else
        # Округление вниз до кратного STEP_SIZE
        echo $(( (brightness / step) * step ))
    fi
}

# Функция изменения яркости
change_brightness() {
    local direction="$1"
    local step="$2"
    local current new icon

    current=$(get_brightness)

    if (( current % step == 0 )); then
        if [[ $direction == "up" ]]; then
            new=$(( current + step ))
        else
            new=$(( current - step ))
        fi
    else
        new=$( round_brightness "$current" "$direction" "$step")
    fi

    delta=$(( new - current ))
    if (( delta > 0 )); then
        rel="+${delta}%"
    elif (( delta < 0 )); then
        rel="${delta#-}%-"
    else
        rel="+0%"
    fi

    # apply relative change
    brightnessctl set "$rel"

    icon=$(get_icon_path "$new")

    send_notification "$new" "$icon"
}

# Функция циклического переключения яркости
cycle_brightness() {
    local current=$(get_brightness)
    local next_level=0
    local found=false

    # Проходим по массиву уровней
    for level in "${CYCLE_LEVELS[@]}"; do
        # Если текущая яркость меньше уровня, округляем вверх к этому уровню
        if (( current < level )); then
            next_level=$level
            found=true
            break
        fi
    done

    # Если текущая яркость >= 100 или не найден следующий уровень, возвращаемся к 0%
    if [ "$found" != "true" ]; then
        next_level=0
    fi

    # Устанавливаем новую яркость
    brightnessctl set "${next_level}%"

    # Отправляем уведомление
    icon=$(get_icon_path "$next_level")
    send_notification "$next_level" "$icon"
}

# Main
if [ -z "$2" ]; then
    step=BRI_STEP_SIZE
else
    step="$2"
fi

case "$1" in
    "--get")
        get_brightness
        ;;
    "--inc")
        change_brightness "up" "$step"
        ;;
    "--dec")
        change_brightness "down" "$step"
        ;;
    "--cycle")
        cycle_brightness
        ;;
    *)
        get_brightness
        ;;
esac
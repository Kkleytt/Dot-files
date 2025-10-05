#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for Monitor backlights (if supported) using brightnessctl

iDIR="$HOME/.config/swaync/icons"
notification_timeout=1000
send_notify=false

# Правила регулировки (Кол-во шагов регулировки)
BRI_STEPS=20
SEND_NOTIFY=false
BRI_STEP_SIZE=$((100 / $BRI_STEPS))


# Отправка уведомлений
send_notification() {
    local brightness=$1
    local icon_path=$2

    notify-send -e \
        -h string:x-canonical-private-synchronous:brightness_notif \
        -h int:value:"$brightness" \
        -u low \
        -i "$icon_path" \
        "Screen" "Brightness: ${brightness}%"
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

    if [[ "$direction" == "up" ]]; then
        # Округление вверх до кратного STEP_SIZE
        echo $(( ((brightness + BRI_STEP_SIZE - 1) / BRI_STEP_SIZE) * BRI_STEP_SIZE ))
    else
        # Округление вниз до кратного STEP_SIZE
        echo $(( (brightness / BRI_STEP_SIZE) * BRI_STEP_SIZE ))
    fi
}

# Функция изменения яркости
change_brightness() {
    local direction="$1"
    local current new icon

    current=$(get_brightness)

    if (( current % BRI_STEP_SIZE == 0 )); then
        if [[ $direction == "up" ]]; then
            new=$(( current + BRI_STEP_SIZE ))
        else
            new=$(( current - BRI_STEP_SIZE ))
        fi
    else
        new=$( round_brightness "$current" "$direction" )
    fi



    

    # Clamp between 5 and 100
    (( new < 5 )) && new=5
    (( new > 100 )) && new=100

    brightnessctl set "${new}%"

    icon=$(get_icon_path "$new")

    if [ $send_notify == "true" ]; then
        send_notification "$new" "$icon"
    fi
}


# Main
case "$1" in
    "--get")
        get_brightness
        ;;
    "--inc")
        change_brightness "up"
        ;;
    "--dec")
        change_brightness "down"
        ;;
    *)
        get_brightness
        ;;
esac

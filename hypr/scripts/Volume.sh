#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Scripts for volume controls for audio and mic 

iDIR="$HOME/.config/swaync/icons"
sDIR="$HOME/.config/hypr/scripts"


# Правила регулировки (Кол-во шагов регулировки + Лимит громкости)
VOL_STEP_SIZE=5
VOL_LIMIT=200
MIC_STEP_SIZE=5
SEND_NOTIFY=true
SEND_NOTIFY_CHANGE=false


# Отправка уведомления
notify_user() {
    local method="$1"
    local device="$2"

    if [ $SEND_NOTIFY = true ]; then
        if [[ "$method" == "toggle" ]]; then
            if [[ "$device" == "in" ]]; then
                if [ "$(pamixer --default-source --get-mute)" == "true" ]; then
                    notify-send -e -u low -h boolean:SWAYNC_BYPASS_DND:true -i "$iDIR/microphone-mute.png" " Microphone:" " Switched OFF"
                elif [ "$(pamixer --default-source --get-mute)" == "false" ]; then
                    notify-send -e -u low -h boolean:SWAYNC_BYPASS_DND:true -i "$iDIR/microphone.png" " Microphone:" " Switched ON"
                fi
            else
                if [ "$(pamixer --get-mute)" == "true" ]; then
                    notify-send -e -u low -h boolean:SWAYNC_BYPASS_DND:true -i "$iDIR/volume-mute.png" " Speakers:" " Switched OFF"
                elif [ "$(pamixer --get-mute)" == "false" ]; then
                    notify-send -e -u low -h boolean:SWAYNC_BYPASS_DND:true -i "$(get_icon)" " Speakers:" " Switched ON"
                fi
            fi
        else
            if [ $SEND_NOTIFY_CHANGE = true ]; then
                if [[ "$device" == "mic" ]]; then
                    notify-send -e -h int:value:"$volume" -h "string:x-canonical-private-synchronous:volume_notif" -h boolean:SWAYNC_BYPASS_DND:true -u low -i "$icon"  " Mic Level:" " $volume"
                else
                    notify-send -e -h int:value:"$(get_volume | sed 's/%//')" -h string:x-canonical-private-synchronous:volume_notif -h boolean:SWAYNC_BYPASS_DND:true -u low -i "$(get_icon)" " Volume Level:" " $(get_volume)" && "$sDIR/Sounds.sh" --volume
                fi
            fi
        fi
    fi
}

# Получение громкости динамиков
get_volume() {
    volume=$(pamixer --get-volume)
    if [[ "$volume" -eq "0" ]]; then
        echo "Muted"
    else
        echo "$volume %"
    fi
}
# Получение громкости микрофон
get_mic_volume() {
    volume=$(pamixer --default-source --get-volume)
    if [[ "$volume" -eq "0" ]]; then
        echo "Muted"
    else
        echo "$volume %"
    fi
}
# Получение иконки микрофон
get_mic_icon() {
    current=$(pamixer --default-source --get-volume)
    if [[ "$current" -eq "0" ]]; then
        echo "$iDIR/microphone-mute.png"
    else
        echo "$iDIR/microphone.png"
    fi
}
# Получение иконки динамиков
get_icon() {
    current=$(get_volume)
    if [[ "$current" == "Muted" ]]; then
        echo "$iDIR/volume-mute.png"
    elif [[ "${current%\%}" -le 30 ]]; then
        echo "$iDIR/volume-low.png"
    elif [[ "${current%\%}" -le 60 ]]; then
        echo "$iDIR/volume-mid.png"
    else
        echo "$iDIR/volume-high.png"
    fi
}
# Функция включения Mute
toggle_mute() {
    device="$1"

    if [[ $device == "in" ]]; then
        if [ "$(pamixer --default-source --get-mute)" == "false" ]; then
            pamixer --default-source -m 
        elif [ "$(pamixer --default-source --get-mute)" == "true" ]; then
            pamixer -u --default-source u
        fi
    else
        if [ "$(pamixer --get-mute)" == "false" ]; then
            pamixer -m
        elif [ "$(pamixer --get-mute)" == "true" ]; then
            pamixer -u 
        fi     
    fi

    notify_user "toggle" "$device"
}
# Функция округления громкости
round_volume() {
    local vol=$1
    local direction=$2 # "up" или "down"

    if [[ "$direction" == "up" ]]; then
        # Округление вверх до кратного STEP_SIZE
        echo $(( ((vol + step - 1) / step) * step ))
    else
        # Округление вниз до кратного STEP_SIZE
        echo $(( (vol / step) * step ))
    fi
}

# Изменение громкости динамиков
out_volume() {
    local direction="$1"
    local step="$2"

    # Проверяем был ли установлен Mute
    if [ "$(pamixer --get-mute)" == "true" ]; then
        toggle_mute "out" 
    fi

    # Получаем текущую громкость
    current_vol=$(pamixer --get-volume)

    # Вычисляем новую громкость для установки
    if (( current_vol % step == 0 )); then
        if [[ $direction == "up" ]]; then
            new_vol=$(( current_vol + step ))
        else
            new_vol=$(( current_vol - step ))
        fi
    else
        if [[ $direction == "up" ]]; then
            new_vol=$(round_volume "$current_vol" "up")
        else
            new_vol=$(round_volume "$current_vol" "down")
        fi
    fi

    # Проверяем громкость на лимит
    if [[ $direction == "up" ]]; then
        if (( new_vol > VOL_LIMIT )); then
            new_vol=$VOL_LIMIT
        fi
    else
        if (( new_vol < 0 )); then
            new_vol=0
        fi
    fi

    # Устанавливаем новую громкость
    pamixer --set-volume "$new_vol" --allow-boost --set-limit "$VOL_LIMIT" 
    
    notify_user "change" "out"
}

# Изменение громкости микрофона
in_volume() {
    local direction="$1"
    local step="$2"

    if [ "$(pamixer --default-source --get-mute)" == "true" ]; then
        toggle_mute "in"
    fi

    current_vol=$(pamixer --default-source --get-volume)

    if (( current_vol % step == 0 )); then
        if [[ $direction == "up" ]]; then
            new_vol=$(( current_vol + step ))
        else
            new_vol=$(( current_vol - step ))
        fi
    else
        if [[ $direction == "up" ]]; then
            new_vol=$(round_volume "$current_vol" "up")
        else
            new_vol=$(round_volume "$current_vol" "down")
        fi
    fi  

    pamixer --default-source --set-volume "$new_vol" 
    
    notify_user "change" "in"
}

# Универсальная функция изменения громкости
edit_volume() {
    local device="$1"
    local direction="$2"
    local step="$3"

    if [[ $device == "out" ]]; then
        out_volume "$direction" "$step"
    else
        in_volume "$direction" "$step"
    fi
}


if [ -z "$2" ]; then
    out_step=VOL_STEP_SIZE
    in_step=MIC_STEP_SIZE
else
    in_step="$2"
    out_step="$2"
fi


# Execute accordingly
if [[ "$1" == "--get" ]]; then
	get_volume
elif [[ "$1" == "--inc" ]]; then
	edit_volume "out" "up" "out_step"
elif [[ "$1" == "--dec" ]]; then
	edit_volume "out" "down" "out_step"
elif [[ "$1" == "--toggle" ]]; then
	toggle_mute "out"
elif [[ "$1" == "--toggle-mic" ]]; then
	toggle_mute "in"
elif [[ "$1" == "--get-icon" ]]; then
	get_icon
elif [[ "$1" == "--get-mic-icon" ]]; then
	get_mic_icon
elif [[ "$1" == "--mic-inc" ]]; then
	edit_volume "in" "up" "in_step"
elif [[ "$1" == "--mic-dec" ]]; then
	edit_volume "in" "down" "in_step"
else
	get_volume
fi

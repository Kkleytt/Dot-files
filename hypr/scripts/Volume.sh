#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Scripts for volume controls for audio and mic 

iDIR="$HOME/.config/swaync/icons"
sDIR="$HOME/.config/hypr/scripts"


# Правила регулировки (Кол-во шагов регулировки + Лимит громкости)
VOL_STEPS=50
VOL_LIMIT=150
MIC_STEPS=20
SEND_NOTIFY=false

VOL_STEP_SIZE=$((100 / $VOL_STEPS))
MIC_STEP_SIZE=$((100 / $MIC_STEPS))


# Отправка уведомления о динамиках
notify_user() {
    if [[ "$(get_volume)" == "Muted" ]]; then
        notify-send -e -h string:x-canonical-private-synchronous:volume_notif -h boolean:SWAYNC_BYPASS_DND:true -u low -i "$(get_icon)" " Volume:" " Muted"
    else
        notify-send -e -h int:value:"$(get_volume | sed 's/%//')" -h string:x-canonical-private-synchronous:volume_notif -h boolean:SWAYNC_BYPASS_DND:true -u low -i "$(get_icon)" " Volume Level:" " $(get_volume)" &&
        "$sDIR/Sounds.sh" --volume
    fi
}
# Отправка уведомления о микрофоне
notify_mic_user() {
    volume=$(get_mic_volume)
    icon=$(get_mic_icon)
    notify-send -e -h int:value:"$volume" -h "string:x-canonical-private-synchronous:volume_notif" -h boolean:SWAYNC_BYPASS_DND:true -u low -i "$icon"  " Mic Level:" " $volume"
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
            pamixer --default-source -m && notify-send -e -u low -h boolean:SWAYNC_BYPASS_DND:true -i "$iDIR/microphone-mute.png" " Microphone:" " Switched OFF"
        elif [ "$(pamixer --default-source --get-mute)" == "true" ]; then
            pamixer -u --default-source u && notify-send -e -u low -h boolean:SWAYNC_BYPASS_DND:true -i "$iDIR/microphone.png" " Microphone:" " Switched ON"
        fi
    else
        if [ "$(pamixer --get-mute)" == "false" ]; then
            pamixer -m && notify-send -e -u low -h boolean:SWAYNC_BYPASS_DND:true -i "$iDIR/volume-mute.png" " Mute"
        elif [ "$(pamixer --get-mute)" == "true" ]; then
            pamixer -u && notify-send -e -u low -h boolean:SWAYNC_BYPASS_DND:true -i "$(get_icon)" " Volume:" " Switched ON"
        fi
    fi
}
# Функция округления громкости
round_volume() {
    local vol=$1
    local direction=$2 # "up" или "down"

    if [[ "$direction" == "up" ]]; then
        # Округление вверх до кратного STEP_SIZE
        echo $(( ((vol + VOL_STEP_SIZE - 1) / VOL_STEP_SIZE) * VOL_STEP_SIZE ))
    else
        # Округление вниз до кратного STEP_SIZE
        echo $(( (vol / VOL_STEP_SIZE) * VOL_STEP_SIZE ))
    fi
}

# Изменение громкости динамиков
out_volume() {
    local direction="$1"

    # Проверяем был ли установлен Mute
    if [ "$(pamixer --get-mute)" == "true" ]; then
        toggle_mute "out"
    fi

    # Получаем текущую громкость
    current_vol=$(pamixer --get-volume)

    # Вычисляем новую громкость для установки
    if (( current_vol % VOL_STEP_SIZE == 0 )); then
        if [[ $direction == "up" ]]; then
            new_vol=$(( current_vol + VOL_STEP_SIZE ))
        else
            new_vol=$(( current_vol - VOL_STEP_SIZE ))
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
    
    if [ $SEND_NOTIFY == "true" ]; then
        notify_user
    fi
}

# Изменение громкости микрофона
in_volume() {
    local direction="$1"

    if [ "$(pamixer --default-source --get-mute)" == "true" ]; then
        toggle_mute "in"
    fi

    current_vol=$(pamixer --default-source --get-volume)

    if (( current_vol % MIC_STEP_SIZE == 0 )); then
        if [[ $direction == "up" ]]; then
            new_vol=$(( current_vol + MIC_STEP_SIZE ))
        else
            new_vol=$(( current_vol - MIC_STEP_SIZE ))
        fi
    else
        if [[ $direction == "up" ]]; then
            new_vol=$(round_volume "$current_vol" "up")
        else
            new_vol=$(round_volume "$current_vol" "down")
        fi
    fi  

    pamixer --default-source --set-volume "$new_vol" 
    
    if [ $SEND_NOTIFY == "true" ]; then
        notify_mic_user
    fi
}

# Универсальная функция изменения громкости
edit_volume() {
    local device="$1"
    local direction="$2"

    if [[ $device == "out" ]]; then
        out_volume "$direction"
    else
        in_volume "$direction"
    fi
}



# Execute accordingly
if [[ "$1" == "--get" ]]; then
	get_volume
elif [[ "$1" == "--inc" ]]; then
	edit_volume "out" "up"
elif [[ "$1" == "--dec" ]]; then
	edit_volume "out" "down"
elif [[ "$1" == "--toggle" ]]; then
	toggle_mute "out"
elif [[ "$1" == "--toggle-mic" ]]; then
	toggle_mute "in"
elif [[ "$1" == "--get-icon" ]]; then
	get_icon
elif [[ "$1" == "--get-mic-icon" ]]; then
	get_mic_icon
elif [[ "$1" == "--mic-inc" ]]; then
	edit_volume "in" "up"
elif [[ "$1" == "--mic-dec" ]]; then
	edit_volume "in" "down"
else
	get_volume
fi

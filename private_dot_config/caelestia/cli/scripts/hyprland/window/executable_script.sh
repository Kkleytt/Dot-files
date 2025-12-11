toggle(){
    TMP_FILE="$XDG_RUNTIME_DIR/hyprland-show-desktop"
    CURRENT_WORKSPACE=$(hyprctl monitors -j | jq '.[] | .activeWorkspace | .name' | sed 's/"//g')
    
    if [ -s "$TMP_FILE-$CURRENT_WORKSPACE" ]; then
      readarray -d $'\n' -t ADDRESS_ARRAY <<< $(< "$TMP_FILE-$CURRENT_WORKSPACE")
      for address in "${ADDRESS_ARRAY[@]}"
      do
        CMDS+="dispatch movetoworkspacesilent name:$CURRENT_WORKSPACE,address:$address;"
      done
      hyprctl --batch "$CMDS"
      rm "$TMP_FILE-$CURRENT_WORKSPACE"
    else
      HIDDEN_WINDOWS=$(hyprctl clients -j | jq --arg CW "$CURRENT_WORKSPACE" '.[] | select (.workspace .name == $CW) | .address')
      readarray -d $'\n' -t ADDRESS_ARRAY <<< $HIDDEN_WINDOWS
      for address in "${ADDRESS_ARRAY[@]}"
      do
        address=$(sed 's/"//g' <<< $address )
        [[ -n address ]] && TMP_ADDRESS+="$address\n"
        CMDS+="dispatch movetoworkspacesilent special:desktop,address:$address;"
      done
      hyprctl --batch "$CMDS"
      echo -e "$TMP_ADDRESS" | sed -e '/^$/d' > "$TMP_FILE-$CURRENT_WORKSPACE"
    fi
}

move_to(){
    [[ "$1" == "+" ]] && hyprctl dispatch movetoworkspace +1 && exit 1
    [[ "$1" == "-" ]] && hyprctl dispatch movetoworkspace -1 && exit 1
    hyprctl dispatch movetoworkspace "$1"
}

shift_to(){
    hyprctl dispatch movewindow "$1"
}

resize(){
    hyprctl dispatch resizeactive "$1" "$2"
}

# === Аргументы ===
method="${1:-toggle}"       # Стандартный метод
workspace="${2:-1}"         # Номер стола

# === Запуск ===
case "$method" in
  toggle)                   toggle                                      ;;
  shift)                    shift_to            "$2"                    ;;
  move)                     move_to             "$workspace"            ;;
  resize)                   resize              "$2" "$3"               ;;
  *)                        echo                "Error args"            ;;
esac
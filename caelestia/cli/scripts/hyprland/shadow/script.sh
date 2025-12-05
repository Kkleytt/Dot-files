#!/usr/bin/env bash
# /scripts/hyprland/shadow/script.sh
set -euo pipefail

VarManager="$HOME/.config/caelestia/cli/scripts/hyprland/variables/script.sh"


toggle_shadow() { 
  check_shadow() { 
    # Проверка микрофона, динамиков, оболочки, яркости и workspace 
    local current_mic=$(pamixer --default-source --get-mute 2>/dev/null) 
    local current_speaker=$(pamixer --get-mute 2>/dev/null) 
    local current_bri=$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%') 

    [[ "$current_mic" != "true" ]] || [[ "$current_speaker" != "true" ]] && echo "1" && return 0 
    [[ -z "$current_bri" ]] || [[ "$current_bri" -ne 0 ]] && echo "2" && return 0 

    return 1 
  } 
  
  hide() { 
    caelestia shell lock lock &
    brightnessctl set "0%" -q &
    playerctl stop &
    pamixer -m & 
    pamixer --default-source -m &
    caelestia shell notifs enableDnd &
  }

  unhide() { 
    brightnessctl set "30%" -q & 
    pamixer -u & 
    pamixer --default-source -u & 
    caelestia shell notifs disableDnd &
  } 
  
  if check_shadow; then 
    hide
  else 
    unhide
  fi 
}

app() {
    local name=${1:-T}
    local cmd=${2:-kitty}
    local target="special:${name}"
    local prev_file="/tmp/special_prev_ws_${USER}_${name}"
    
    # Проверки
    command -v hyprctl >/dev/null 2>&1 || { echo "hyprctl not found"; exit 1; }
    command -v jq >/dev/null 2>&1 || { echo "jq not found"; exit 1; }
    
    # Найти существующие workspaces на первом мониторе
    local current_ws=$(hyprctl monitors -j | jq -r '.[0].activeWorkspace.name')
    local ws_clients=$(hyprctl clients -j | jq -r --arg ws "$target" '.[] | select(.workspace.name == $ws)')
    echo "Сравнение: " "$current_ws" " VS " "$name"
    
    # Уже находимся на этом слое
    if [[ "$current_ws" == "$name" ]]; then
        caelestia toggle "$name"
    elif [[ -n "$ws_clients" ]]; then
        caelestia toggle "$name"
    else
        caelestia toggle "$workspace"
        sleep 0.1
        echo "$cmd"
        hyprctl dispatch exec "$cmd"
    fi
    
    exit 0 
}

move_to(){
    hyprctl dispatch movetoworkspace "special:$1"
}

create_space() {
  caelestia toggle "$1"
}


# === Аргументы ===
method="${1:-app}"          # Стандартный метод
workspace="${2:-T}"         # Имя стола
cmd="${3:-kitty}"           # Команда для открытия приложения

# === Запуск ===
case "$method" in
  toggle)                   toggle_shadow                               ;;
  app)                      app                 "$workspace"    "$cmd"  ;;
  space)                    create_space        "$workspace"            ;;
  move)                     move_to             "$workspace"            ;;
  *)                        echo                "Error args"            ;;
esac

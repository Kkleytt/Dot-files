#!/usr/bin/env bash
set -euo pipefail

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


method="${1:-app}"
workspace="${2:-T}"
cmd="${3:-kitty}"


case "$method" in
    app)    app "$workspace" "$cmd" ;;
    *)      echo "Error args" ;;
esac



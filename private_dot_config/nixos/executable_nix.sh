#!/usr/bin/env bash

PROJECT_PATH="/home/kkleytt/.config/nixos"

# Функция вывода доступных аргументов
echo_table() {
  cat <<'EOF'
Использование: nix-clean.sh {method} {options}

- methods: {commit|push|build|remove|clear|reboot|edit}

Exmaples:
    - ./nix.sh build {host} - Пересобрать систему
    - ./nix.sh remove {number} - Удалить конкретную сборку
    - ./nix.sh clear - Очистить система от хлама
    - ./nix.sh reboot - Перезапустить систему
EOF
}

# --- Функции действий ---
clear_trash() {
    echo ""
    echo "▶▶▶ Очистка мусора..."
    sudo nix-collect-garbage -d
}

rebuild_system() {
    local host="${1:-mobile}"
    
    echo ""
    echo "▶▶▶ Пересборка системы..."
    cd "$PROJECT_PATH"
    sudo nixos-rebuild switch --flake .#$host
}

remove_build() {
    local number="$1"
    
    [[ -z "$number" ]] && { echo " Ошибка: аргумент не передан"; exit 1; }
    echo ""
    echo "▶▶▶ Удаление сборки $number..."
    cd "$PROJECT_PATH"
    sudo nix-env -p /nix/var/nix/profiles/system --delete-generations $number
}

reboot() {
    echo ""
    echo "▶▶▶ Перезагрузка системы..."
    sudo reboot
}

method="${1:-build}"

case "$method" in
    build)      rebuild_system "$2" ;;
    remove)     remove_build "$2" ;;
    clear)      clear_trash ;;
    reboot)     reboot ;;
    *)          echo "Error args" ;;
esac

#!/usr/bin/env bash

PROJECT_PATH="/home/kkleytt/.config/nixos"

# Функция вывода доступных аргументов
echo_table() {
  cat <<'EOF'
Использование: nix-clean.sh {method} {options}

- methods: {commit|push|build|remove|clear|reboot|edit}

Exmaples:
    - ./nix.sh commit {message} - Сделать комит
    - ./nix.sh push {remote} {branch} - Запушить в удаленный репозиторий
    - ./nix.sh build {host} - Пересобрать систему
    - ./nix.sh remove {number} - Удалить конкретную сборку
    - ./nix.sh clear - Очистить система от хлама
    - ./nix.sh reboot - Перезапустить систему
    - ./nix.sh edit - Открыть редактор кода
EOF
}

# --- Функции действий ---
git_commit() {
    local message="${1:-Auto commit by NixOS}"
    
  echo ""
  echo "▶▶▶ Commit всех файлов..."
  cd "$PROJECT_PATH"
  sudo git add .
  sudo git commit -m "#message" || echo "Нет изменений для коммита"
}

git_push() {
    local remote="${1:-origin}"
    local branch="${2:-main}"
    
    echo ""
    echo "▶▶▶ Push ветки $branch в удаленный репозиторий $remote..."
    cd "$PROJECT_PATH"
    git push "$remote" "$branch" || echo "Ошибка при выполнении пуша в удаленый репозиторий" 
}

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

shortcut_1() {
    git_commit
    git_push
    rebuild_system
}



method="${1:-build}"

case "$method" in
    commit)     git_commit "$2" ;;
    push)       git_push "$2" "$3" ;;
    build)      rebuild_system "$2" ;;
    remove)     remove_build "$2" ;;
    clear)      clear_trash ;;
    reboot)     reboot ;;
    sh1)        shortcut_1 ;;
    *)          echo "Error args" ;;
esac

#!/usr/bin/env bash
# Модуль для автоматизированного удаления старых версий NixOS и сборки системы

set -euo pipefail

# Переменные статуса флагов
DO_GIT=false
DO_PUSH=false
DO_CLEAR=false
DO_SUDO_CLEAR=false
DO_BUILD=false
DO_REBOOT=false

PROJECT_PATH="/home/kkleytt/.config/nixos"

# Функция вывода доступных аргументов
echo_table() {
  cat <<'EOF'
Использование: nix-clean.sh [опции]

  -g | -G | --git         Сделать коммит репозитория
  -p | -P | --push        Сделать коммит и пуш репозитория
  -b | -B | --build       Собрать систему заново
  -c | -C | --clear       Очистка прошлых версий
  -s | -S | --sudo-clear  Глубокая очистка с sudo правами
  -r | -R | --reboot      Перезагрузить систему после пересборки
  -h | -H | --help        Показать эту справку

Можно комбинировать короткие флаги в одну группу:
  -gbs   (git → build → sudo-clear)
  -sr    (sudo-clear → reboot)
EOF
}

# --- Функции действий ---
do_git() {
  echo ""
  echo "▶▶▶ Git commit..."
  cd "$PROJECT_PATH"
  sudo git add .
  sudo git commit -m "Auto commit with script" || echo "Нет изменений для коммита"
}

do_push() {
  do_git
  echo ""
  echo "▶▶▶ Git push to remote repository..."
  cd "$PROJECT_PATH"
  git push origin main || echo "Ошибка при выполнении пуша в удаленый репозиторий" 
}

do_clear() {
  echo ""
  echo "▶▶▶ Очистка старых версий..."
  nix-collect-garbage --delete-old
}

do_sudo_clear() {
  echo ""
  echo "▶▶▶ Глубокая очистка с sudo..."
  sudo nix-collect-garbage -d
}

do_build() {
  echo ""
  echo "▶▶▶ Пересборка системы..."
  cd "$PROJECT_PATH"
  sudo nixos-rebuild switch --flake .#mobile
}

do_reboot() {
  echo ""
  echo "▶▶▶ Перезагрузка..."
  sudo reboot
}

# --- Разбор аргументов ---
if [[ $# -eq 0 ]]; then
  echo_table
  exit 0
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --git)         DO_GIT=true; shift ;;
    --push)        DO_PUSH=true; shift ;;
    --clear)       DO_CLEAR=true; shift ;;
    --sudo-clear)  DO_SUDO_CLEAR=true; shift ;;
    --build)       DO_BUILD=true; shift ;;
    --reboot)      DO_REBOOT=true; shift ;;
    --help)        echo_table; exit 0 ;;
    -[gGpPbBcCsSrRhH]*)
      opts="${1#-}"
      for (( i=0; i<${#opts}; i++ )); do
        c="${opts:i:1}"
        case "$c" in
          g|G) DO_GIT=true ;;
          p|P) DO_PUSH=true ;;
          c|C) DO_CLEAR=true ;;
          s|S) DO_SUDO_CLEAR=true ;;
          b|B) DO_BUILD=true ;;
          r|R) DO_REBOOT=true ;;
          h|H) echo_table; exit 0 ;;
          *) echo "Неизвестный флаг: -$c" >&2; exit 1 ;;
        esac
      done
      shift
      ;;
    -*) echo "Неизвестный флаг: $1" >&2; exit 1 ;;
     *) break ;;
  esac
done

# --- Последовательное выполнение ---
$DO_GIT        && do_git
$DO_PUSH       && do_push
$DO_CLEAR      && do_clear
$DO_SUDO_CLEAR && do_sudo_clear
$DO_BUILD      && do_build
$DO_REBOOT     && do_reboot

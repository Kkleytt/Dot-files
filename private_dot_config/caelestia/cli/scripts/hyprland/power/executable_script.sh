#!/usr/bin/env bash
# powermenu.sh — Rofi power menu
# Настройка: отредактируй LOCK_CMD, HYPR_EXIT_CMD, SHELL_RESTART_CMD при необходимости.

# --- Настройки (подправь под свою систему) ---
ROFI_CONFIG="$HOME/.config/rofi/configs/power.rasi"
LOCK_CMD="caelestia shell lock lock"                       
HYPR_EXIT_CMD="hyprctl dispatch exit"
SHELL_RESTART_CMD="$HOME/.config/caelestia/cli/scripts/caelestia/shell/script.sh restart"
ROFI_CMD="rofi -dmenu -i -matching normal -config $ROFI_CONFIG" 
# -------------------------------------------------

# Опции меню
options=(
  "Reboot"
  "Off"
  "Sleep"
  "Hyber"
  "Lock"
  "Exit"
  "Shell"
)

# Показываем меню
choice="$(printf '%s\n' "${options[@]}" | eval "$ROFI_CMD")"

# Если ничего не выбрано — выйти
[ -z "$choice" ] && exit 0

# Вспомогательная функция подтверждения через rofi
confirm() {
  local msg="${1:-Are you sure?}"
  printf "Далее\nОтмена" | eval "$ROFI_CMD"
}

# Выполнение действий
case "$choice" in
  "Reboot")
    ans="$(confirm "Перезапустить систему?")"
    if [[ "$ans" == "Далее" ]]; then
      systemctl reboot
    fi
    ;;

  "Off")
    ans="$(confirm "Выключить систему?")"
    if [[ "$ans" == "Далее" ]]; then
      systemctl poweroff
    fi
    ;;

  "Sleep")
    ans="$(confirm "Перевести в спящий режим?")"
    if [[ "$ans" == "Далее" ]]; then
      systemctl suspend
    fi
    ;;

  "Hyber")
    ans="$(confirm "Гибернация (hibernate)?")"
    if [[ "$ans" == "Далее" ]]; then
      systemctl hibernate
    fi
    ;;

  "Lock")
    # Блокировка не требует подтверждения
    ans="$(confirm "Заблокировать (lock)?")"
    if [[ "$ans" == "Далее" ]]; then
      eval "$LOCK_CMD"
    fi
    ;;

  "Exit")
    ans="$(confirm "Выйти из Hyprland?")"
    if [[ "$ans" == "Далее" ]]; then
      # Выполняем команду выхода
      eval "$HYPR_EXIT_CMD"
    fi
    ;;

  "Shell")
    ans="$(confirm "Перезапустить оболочку (exec \$SHELL)?")"
    if [[ "$ans" == "Далее" ]]; then
      eval "$SHELL_RESTART_CMD"
    fi
    ;;
  *) exit 0 ;;
esac

exit 0

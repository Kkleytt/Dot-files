#!/usr/bin/env bash
set -euo pipefail

# === Настройки ===
SHELL="$1"
BASE_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers (copy 1)}"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
iDIR="$HOME/.config/swaync/images"

# === Опциональные флаги (можно передать как аргументы) ===
RELOAD_PANELS="${RELOAD_PANELS:-true}"  # true/false — перезапускать ли панели
ENABLE_SDDM="${ENABLE_SDDM:-false}"     # true/false — предлагать ли SDDM

# === Проверки ===
if [[ ! -d "$BASE_DIR" ]]; then
  notify-send -i "${iDIR}/error.png" "Wallpaper dir missing" "Create: $BASE_DIR"
  exit 1
fi

if ! command -v bc &>/dev/null; then
  notify-send -i "${iDIR}/error.png" "bc missing" "Install package 'bc'"
  exit 1
fi

if ! command -v rofi &>/dev/null; then
  notify-send -i "${iDIR}/error.png" "rofi missing" "Install rofi"
  exit 1
fi

# === Монитор и масштаб ===
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
if [[ -z "$focused_monitor" ]]; then
  notify-send -i "${iDIR}/error.png" "E-R-R-O-R" "No focused monitor"
  exit 1
fi

scale_factor=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .scale')
monitor_height=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .height')
icon_size=$(echo "scale=1; ($monitor_height * 3) / ($scale_factor * 150)" | bc)
adjusted_icon_size=$(awk -v s="$icon_size" 'BEGIN { if (s < 15) s = 20; if (s > 25) s = 25; print int(s) }')

# === Rofi theme ===
ROFI_THEME="$HOME/.config/rofi/config-wallpaper.rasi"
ROFI_OVERRIDE="
element-icon { size: ${adjusted_icon_size}%; }
configuration { columns: 4; }
"

# === Иконки ===
FOLDER_ICON="$HOME/.local/share/icons/folder.svg"
BACK_ICON="$HOME/.local/share/icons/back.svg"

# === Функции ===

reload_shell() {
  local shell="$1"

  if [[ "$RELOAD_PANELS" == "true" ]]; then
    ~/.config/hypr/scripts/HideBar.sh "$shell" "reload"
  fi
}

apply_wallpaper() {
  local image_path="$1"
  echo "Applying: $image_path"

  # Убиваем старые процессы
  pkill -f swaybg 2>/dev/null || true
  pkill -f hyprpaper 2>/dev/null || true
  pkill -f swww 2>/dev/null || true

  # Запускаем swww-daemon, если не запущен
  if ! pgrep -x "swww-daemon" >/dev/null; then
    swww-daemon --format xrgb &
    sleep 0.3
  fi

  # Применяем
  swww img -o "$focused_monitor" "$image_path" \
    --transition-fps 60 \
    --transition-type any \
    --transition-duration 2 \
    --transition-bezier ".43,1.19,1,.4"

  # Генерация цветовой схемы
  wal -i "$image_path"

  # Перезапуск панелей
  reload_shell "$SHELL"

  # Запуск дополнительных скриптов
  if [ "$SHELL" == "caelestia" ]; then
    echo "Applying Caelestia wallpaper ..."
    caelestia wallpaper -f "$image_path"
  fi

  # Доп. скрипты
  #"$SCRIPTSDIR/WallustSwww.sh" || true
  #sleep 1
  #"$SCRIPTSDIR/Refresh.sh" || true

  # Опционально: SDDM
  if [[ "$ENABLE_SDDM" == "true" ]]; then
    "$SCRIPTSDIR/sddm_wallpaper.sh" --normal &>/dev/null || true
  fi
}

navigate_directory() {
  local current_dir="$1"
  local parent_dir="$(dirname "$current_dir")"

  {
    # Кнопка "Назад", если не в корне
    if [[ "$current_dir" != "$BASE_DIR" ]]; then
      printf "Назад\0icon\x1f%s\n" "$BACK_ICON"
    fi

    # Папки: исключаем скрытые (начинаются с .)
    find "$current_dir" -mindepth 1 -maxdepth 1 -type d ! -name ".*" | sort | while read -r dir; do
      printf "%s\0icon\x1f%s\n" "$(basename "$dir")" "$FOLDER_ICON"
    done

    # Изображения: только поддерживаемые расширения + не скрытые
    find "$current_dir" -mindepth 1 -maxdepth 1 -type f ! -name ".*" \( \
      -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o \
      -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.webp" \) | sort | while read -r file; do
      printf "%s\0icon\x1f%s\n" "$(basename "$file")" "$file"
    done
  } | rofi -dmenu -show-icons -config "$ROFI_THEME" -theme-str "$ROFI_OVERRIDE" -p "Wallpaper" \
    | { read -r selection || exit 0

        [[ -z "$selection" ]] && exit 0

        if [[ "$selection" == "Назад" ]]; then
          navigate_directory "$parent_dir"
          return
        fi

        local full_path="$current_dir/$selection"

        if [[ -d "$full_path" ]]; then
          navigate_directory "$full_path"
        elif [[ -f "$full_path" ]]; then
            caelestia wallpaper -f "$full_path"
            #apply_wallpaper "$full_path"
        fi
      }
}

# === Запуск ===
navigate_directory "$BASE_DIR"
#!/usr/bin/env bash
set -euo pipefail

# === Папка для скринов ===
DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"
STAMP="$(date +'%Y-%m-%d_%H-%M-%S').png"
OUT="$DIR/$STAMP"

# === Уведомления ===
note() { notify-send "$1" "$2"; }

# === Аргументы ===
MODE="${1:-screen}"       # screen | window | area
EDIT="${2:-edit}"         # edit | no_edit

# === Функция скриншота ===
take_screenshot() {
  case "$MODE" in
    screen)
      if command -v grimblast &>/dev/null; then
        grimblast save screen "$OUT"
      else
        grim "$OUT"
      fi
      ;;
    window)
      read -r X Y W H < <(
        hyprctl -j activewindow |
        jq -r '[.at[0],.at[1],.size[0],.size[1]]|@sh' | tr -d \'
      )
      GEO="${X},${Y} ${W}x${H}"
      grim -g "$GEO" "$OUT"
      ;;
    area)
      grim -g "$(slurp)" "$OUT"
      ;;
    *)
      echo "Usage: $0 {screen|window|area} {edit|no_edit}" >&2
      exit 1
      ;;
  esac
}

# === 1. Делаем скриншот ===
take_screenshot

# === 2. Редактирование с защитой от пустого файла ===
if [[ "$EDIT" == "edit" ]]; then
  # Создаём временный файл
  tmpfile="$(mktemp --suffix=.png)"

  # Запускаем satty
  if satty -f "$OUT" -o "$tmpfile"; then
    # Проверяем, существует ли файл и не пустой ли он
    if [[ -s "$tmpfile" ]]; then
      mv "$tmpfile" "$OUT"
    else
      # satty создал пустой файл → оставляем оригинал
      rm -f "$tmpfile"
      note "Редактирование отменено" "Сохранён оригинальный скриншот"
    fi
  else
    # satty завершился с ошибкой → оставляем оригинал
    rm -f "$tmpfile"
    note "Редактирование не удалось" "Сохранён оригинальный скриншот"
  fi
fi

# === 3. Буфер обмена ===
if [[ -s "$OUT" ]]; then
  wl-copy < "$OUT"
else
  # На всякий случай — если что-то пошло не так
  note "Ошибка" "Скриншот пустой или не создан"
  exit 1
fi

# === 4. Уведомление ===
note "Скриншот сохранён" "$STAMP"

# === 5. Путь в stdout ===
echo "$OUT"
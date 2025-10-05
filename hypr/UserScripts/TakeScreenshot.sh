#!/usr/bin/env bash
set -euo pipefail

# === Папка для скринов ===
DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"
STAMP="$(date +'%Y-%m-%d_%H-%M-%S').png"
OUT="$DIR/$STAMP"

# === Уведомления (замена notify-wrap на notify-send) ===
collapse() { echo ""; }
note() { notify-send "$1" "$2"; }

# === Аргументы ===
MODE="${1:-screen}"       # screen | window | area
EDIT="${2:-no_edit}"      # edit | no_edit

# === 0. Снятие уведомлений ===
collapse
sleep 0.6

# === Функция скриншота ===
take_screenshot() {
  case "$MODE" in
    screen)
      if command -v grimblast &>/dev/null; then
        grimblast save screen $OUT
      else
        grim $OUT
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

# === 2. Редактирование ===
if [[ "$EDIT" == "edit" ]]; then
  tmpfile="$(mktemp --suffix=.png)"
  satty -f "$OUT" -o "$tmpfile"
  mv "$tmpfile" "$OUT"
fi

# === 3. Буфер обмена ===
wl-copy < "$OUT"


# === 4. Уведомление ===
note "Скриншот сохранён" "$STAMP"

# === 5. Путь в stdout ===
echo $OUT

#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYHINTS_DIR="$SCRIPT_DIR/keyhints"

if [[ ! -d "$KEYHINTS_DIR" ]]; then
  echo "Ошибка: $KEYHINTS_DIR не найдена!" >&2
  exit 1
fi

# Получаем список тем: basename без .txt, с иконками (если есть)
mapfile -t THEME_FILES < <(find "$KEYHINTS_DIR" -maxdepth 1 -name "*.txt" -printf "%f\n" | sort)

if [[ ${#THEME_FILES[@]} -eq 0 ]]; then
  echo "Нет файлов *.txt в $KEYHINTS_DIR" >&2
  exit 1
fi

# Убираем расширение .txt → получаем "имя с иконкой"
THEMES=()
for f in "${THEME_FILES[@]}"; do
  THEMES+=("${f%.txt}")
done

# Убиваем старые процессы
pkill -f "rofi.*cheatsheet\|yad.*KooL Cheat" 2>/dev/null

# Выбор темы через Rofi (иконка уже в строке!)
CHOSEN_DISPLAY=$(printf '%s\n' "${THEMES[@]}" | rofi -dmenu -i )

# Если ничего не выбрано — выходим
[[ -z "$CHOSEN_DISPLAY" ]] && exit 0

# Восстанавливаем имя файла: добавляем .txt
HINT_FILE="$KEYHINTS_DIR/$CHOSEN_DISPLAY.txt"

if [[ ! -f "$HINT_FILE" ]]; then
  yad --text="Файл не найден: $HINT_FILE" --button=OK
  exit 1
fi

# Читаем файл: делим по первому ';', игнорируем пробелы вокруг
declare -a ROWS
while IFS= read -r line; do
  line="${line//$'\r'/}"
  [[ -z "$line" ]] && continue

  if [[ "$line" == *";"* ]]; then
    key="${line%%;*}"
    desc="${line#*;}"
    # Убираем начальные/конечные пробелы
    key="$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    desc="$(echo "$desc" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    ROWS+=("$key     " "$desc")
  else
    ROWS+=("$line" "")
  fi
done < "$HINT_FILE"

# Показываем в yad
GDK_BACKEND=wayland yad \
  --center \
  --title="KooL Quick Cheat Sheet" \
  --no-buttons \
  --list \
  --column=Комбинация: \
  --column=Описание: \
  --timeout-indicator=bottom \
  "${ROWS[@]}"
#!/bin/bash
# /* ---- 💫 Emoji Picker (Dynamic from CLDR) | https://github.com/JaKooLit 💫 ---- */

# Настройки
EMOJI_JSON="$HOME/.config/hypr/scripts/annotations.json"
msg="Выберите эмодзи"
rofi_theme="$HOME/.config/rofi/config-emoji.rasi"  # Укажи свой путь при необходимости

# Проверки
if [[ ! -f "$EMOJI_JSON" ]]; then
  notify-send "❌ Emoji" "Файл $EMOJI_JSON не найден!"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "Установите jq: sudo apt install jq" >&2
  exit 1
fi

if ! command -v rofi &> /dev/null; then
  echo "Установите rofi" >&2
  exit 1
fi


# --- Генерация данных из annotations.json ---
# Извлекаем эмодзи и первое осмысленное название (tts или default)
generate_data() {
  jq -r '
    .annotations.annotations
    | to_entries[]
    | select(.key | length > 0)
    | .key as $emoji
    | (.value.tts[0] // .value.default[0] // "Без названия")
    | "\($emoji) \(.)"
  ' "$EMOJI_JSON"
}

# --- Конец данных ---

# Передаём сгенерированные данные в Rofi по аналогии с шаблоном
generate_data | \
rofi -i -dmenu -mesg "$msg" -config "$rofi_theme" | \
awk '{print $1}' | \
head -n 1 | \
tr -d '\n' | \
wl-copy || xclip -selection clipboard

# Выход
exit 0
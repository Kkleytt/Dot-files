#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  
# Поиск через веб-браузер с помощью Rofi

# Путь к конфигу (временно не используется, но можно расширить)
config_file="$HOME/.config/hypr/UserConfigs/01-UserDefaults.conf"

# Тема Rofi и сообщение
rofi_theme="$HOME/.config/rofi/config-search.rasi"
msg="🔎 Введите поисковый запрос"

# Убиваем предыдущий экземпляр rofi
if pgrep -x "rofi" > /dev/null; then
    pkill rofi
fi

# Показываем поле ввода (mode: combi или text)
query=$(rofi -dmenu \
    -p "Поиск" \
    -theme "$rofi_theme" \
    -no-fixed-num-lines 
)

# Если пользователь ввёл запрос — выполняем поиск
if [[ -n "$query" ]]; then
    # Кодируем запрос для URL (заменяем пробелы на + и т.д.)
    encoded_query=$(printf '%s' "$query" | jq -sRr @uri)
    
    # Формируем URL (Google по умолчанию)
    url="https://www.google.com/search?q=$encoded_query"
    
    # Открываем в стандартном браузере
    xdg-open "$url" &> /dev/null || {
        notify-send "🌐 Ошибка" "Не удалось открыть браузер."
    }
else
    exit 0
fi
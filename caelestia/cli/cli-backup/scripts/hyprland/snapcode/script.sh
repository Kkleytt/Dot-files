#!/usr/bin/env bash

# 1) Получаем выделенный текст
text="$(wl-paste --primary)"
[[ -z "$text" ]] && notify-send "CodeShot" "Нет выделенного текста!" && exit 1

# 2) Список: "видимое\0теги"
# Используем ANSI-C quoting ($'...') чтобы \0 был настоящим NUL
languages=$' Python\0py python snake green\n
 JavaScript\0js javascript node web\n
🦀 Rust\0rs rust cargo system\n
⚙️ C++\0cpp c++ cpp code\n
#️⃣ CSharp\0c# csharp dotnet\n Nix\0nix nixos config\n Bash\0sh bash shell script\n📝 Markdown\0md markdown docs\n📄 Plain Text\0plain text default'

# 3) Выбор через rofi
# -display-columns 1: показываем только первую колонку (до NUL), но поиск идёт по всем колонкам
# -matching fuzzy (опционально): удобнее искать по тегам
choice=$(printf '%b\n' "$languages" | rofi -dmenu -display-columns 1 -matching fuzzy -p "Выбери язык:")

# Если пользователь закрыл окно
[[ -z "$choice" ]] && language="plain" || language=$(printf '%s' "$choice" | awk -F '\x00' '{print $2}' | awk '{print $1}')

# 4) Генерация скриншота silicon
echo "$text" | silicon -c -l "$language"
notify-send "CodeShot" "Скриншот кода ($language) создан и скопирован!"

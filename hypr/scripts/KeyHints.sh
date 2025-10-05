#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##

# GDK BACKEND. Change to either wayland or x11 if having issues
BACKEND=wayland

# Check if rofi or yad is running and kill them if they are
if pidof rofi > /dev/null; then
  pkill rofi
fi

if pidof yad > /dev/null; then
  pkill yad
fi

# Launch yad with calculated width and height
GDK_BACKEND=$BACKEND yad \
    --center \
    --title="KooL Quick Cheat Sheet" \
    --no-buttons \
    --list \
    --column=Key: \
    --column=Description: \
    --timeout-indicator=bottom \
"Esc" "Закрыть это окно" \
"Shift + Alt" "Смена языка" \
"🪟" "Запустить Rofi лаунчер" \
"" "" \
"🪟 + Return" "Открыть терминал" \
"🪟 + Return + Alt" "Открыть плавающий терминал" \
"🪟 + Return + Ctrl" "Открыть дополнительный терминал" \
"" "" \
"🪟 + Shift + B" "Запустить браузер Firefox" \
"🪟 + Shift + B + Alt" "Запустить браузер Zen" \
"🪟 + Shift + B + Ctrl" "Запустить поисковик Google" \
"" "" \
"🪟 + Shift + C" "Запустить VsCode" \
"🪟 + Shift + C + Alt" "Запустить редактор кода Zen" \
"🪟 + Shift + C + Ctrl" "Запустить текстовый редактор" \
"" "" \
"🪟 + Shift + I" "Запустить ToDo заметки Planify" \
"🪟 + Shift + I + Alt" "Запустить AppFlowy" \
"🪟 + Shift + I + Ctrl" "Запустить Obsidian" \
"" "" \
"🪟 + Shift + E" "Запустить файловый менеджер" \
"🪟 + Shift + E + Alt" "Запустить менеджер паролей" \
"🪟 + Shift + E + Ctrl" "Запустить менеджер пакетов Flatpak" \
"" "" \
"🪟 + Shift + T" "Запустить Telegram" \
"🪟 + Shift + T + Alt" "Запустить Discord" \
"🪟 + Shift + T + Ctrl" "Запустить Ferdium" \
"🪟 + Shift + M" "Запустить Яндекс Музыку" \
"" "" \
"🪟 + Shift + V" "Буфер обмена" \
"🪟 + Shift + V + Alt" "Выбор Emoji стикеров" \
"🪟 + Shift + V + Ctrl" "Список сочетаний клавиш" \
"🪟 + Shift + W" "Выбор обоев на рабочий стол" \
"🪟 + Shift + W + Alt" "Выбор темы оформления Rofi" \
"" "" \
"🪟 + Shift + O" "Выбор прозрачности окон" \
"🪟 + Shift + O + Alt" "Выбор размытия окон" \
"🪟 + Shift + O + Ctrl" "Вкл/Выкл отображения Waybar" \
"🪟 + Shift + G" "Вкл/Выкл всех анимаций Hyprland" \
"🪟 + Shift + G + Alt" "Выбор анимаций Hyprland" \
"" "" \
"Fn + Prtscr" "Скриншот экрана" \
"Fn + Prtscr + Shift" "Скриншот экрана + Редактирование" \
"Fn + Prtscr + Alt" "Скриншот активного окна" \
"Fn + Prtscr + Alt + Shift" "Скриншот активного окна + Редактирование" \
"Fn + Prtscr + Ctrl" "Скриншот выделенной области" \
"Fn + Prtscr + Ctrl + Shift" "Скриншот выделенной области + Редактирование" \
"" "" \
"🪟 + R" "Запись экрана" \
"🪟 + R + Alt" "Запись активного окна" \
"🪟 + R + Ctrl" "Запись выделенной области" \
"" "" \
"🪟 + [1-9]" "Создание и переход в рабочее пространство" \
"🪟 + Shift + [1-9]" "Переместить окно в рабочее пространство" \
"🪟 + Tab" "Переключиться на 1 рабочее пространство вперед" \
"🪟 + Shift + Tab" "Переключиться на 1 рабочее пространство назад" \
"🪟 + Shift + ]" "Переместить окно на 1 рабочее пространство вперед" \
"🪟 + Shift + [" "Переместить окно на 1 рабочее пространство назад" \
"" "" \
"🪟 + F" "Полноэкранный режим" \
"🪟 + F + Alt" "Нативный полноэкранный режим (Видно Waybar)" \
"🪟 + F + Ctrl" "Плавающий режим" \
"🪟 + Q" "Закрыть окно" \
"🪟 + Q + Ctrl" "Убить активное окно" \
"" "" \
"🪟 + L" "Заблокировать устройство" \
"🪟 + L + Alt" "Выбор сценария выключения устройства" \
"🪟 + L + Ctrl" "Панель уведомлений" \
"🪟 + Del + Ctrl" "Выход из Hyprland" \
"" "" \
"🪟 + Shift + ➡️/⬆️/⬅️/⬇️" "Перемещение окна по рабочему пространству" \
"🪟 + Alt + ➡️/⬆️/⬅️/⬇️" "Сдвиг окна по рабочему пространству" \
"🪟 + Ctrl + ➡️/⬆️/⬅️/⬇️" "Изменение размера окна" \
"🪟 + ➡️/⬆️/⬅️/⬇️" "Перемещение фокуса на окно" \
"" "" \
"🪟 + ПКМ" "Изменение размера окна" \
"🪟 + ЛКМ" "Перемещение окна по рабочему пространству"
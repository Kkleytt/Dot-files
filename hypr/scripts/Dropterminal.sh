#!/usr/bin/env bash
set -euo pipefail

# Терминал
TERM_CMD="${term:-${TERMINAL:-kitty}}"

launch_dropterm() {
  case "$(basename "${TERM_CMD%% *}")" in
    kitty)      exec kitty --class dropterm ;;
    alacritty)  exec alacritty --class dropterm ;;
    wezterm)    exec wezterm start --class dropterm ;;
    foot|footclient) exec foot -a dropterm ;;
    *)          exec $TERM_CMD ;;  # fallback
  esac
}

# 1. Если dropterminal уже активен — скрыть и выйти
if hyprctl activeworkspace -j | jq -e '.name=="special:dropterm"' >/dev/null 2>&1; then
  hyprctl dispatch togglespecialworkspace dropterm
  exit 0
fi

# 2. Проверить, есть ли уже клиент с нужным тегом/классом
has_dropterm_client() {
  hyprctl clients -j | jq -e '
  map(select(
  .class=="dropterm" or 
  .initialClass=="dropterm" or 
  .app_id=="dropterm"
  )) | length>0
  ' >/dev/null 2>&1
}

# 3. Если клиент уже есть — просто показать спец-воркспейс
if has_dropterm_client; then
  echo "Client found"
  hyprctl dispatch togglespecialworkspace dropterm
  exit 0
fi

# 4. Иначе: показать спец-воркспейс И запустить терминал
echo "Client not found"
hyprctl dispatch togglespecialworkspace dropterm

# Запускаем терминал в фоне
(launch_dropterm) &

# ⏳ Ждём до 1 секунды, пока клиент появится в hyprctl (защита от race condition)
for _ in {1..10}; do
  sleep 0.1
  if has_dropterm_client; then
    exit 0
  fi
done

# Если за 1 сек не появился — всё равно выходим (возможно, ошибка запуска)
exit 0
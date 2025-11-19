#!/usr/bin/env bash
set -euo pipefail

# Определи команду терминала: берём $term, иначе $TERMINAL, иначе kitty
TERM_CMD="${term:-${TERMINAL:-kitty}}"

launch_dropterm() {
  case "$(basename "${TERM_CMD%% *}")" in
    kitty)      exec kitty --class dropterm ;;
    alacritty)  exec alacritty --class dropterm ;;
    wezterm)    exec wezterm start --class dropterm ;;
    foot|footclient) exec foot -a dropterm ;;
    *)          exec $TERM_CMD ;;  # как есть (если не поддерживает класс — настроь rules по своему app_id)
  esac
}

# Уже открыт спец‑воркспейс? Тогда спрячем
if hyprctl activeworkspace -j | jq -e '.name=="special:dropterm"' >/dev/null 2>&1; then
  hyprctl dispatch togglespecialworkspace dropterm
  exit 0
fi

# Есть ли уже клиент dropterm?
if hyprctl clients -j | jq -e 'map(select(.class=="dropterm" or .initialClass=="dropterm" or .app_id=="dropterm")) | length>0' >/dev/null 2>&1; then
  # Просто показать
  hyprctl dispatch togglespecialworkspace dropterm
else
  # Показать спец‑воркспейс и запустить терминал в нём
  hyprctl dispatch togglespecialworkspace dropterm
  (launch_dropterm) &
fi

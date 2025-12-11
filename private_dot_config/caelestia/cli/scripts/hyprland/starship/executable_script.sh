#!/usr/bin/env bash
# scripts/hyprland/starship/script.sh

# === Compact: выключаем ненужное ===
send_notify() {
  local body="$1"
  local icon="$2"
  local sound="$3"

  local FIFO="$HOME/.cache/caelestia/osd.fifo"

  # Формируем JSON одной строкой
  local json
  json=$(printf '{"group":"starship","title":"Starship","body":"%s","icon":"%s","timeout":2500,"sound":"%s","urgency":"normal"}\n' \
        "$body" "$icon" "$sound")

  # Записываем в FIFO
  printf '%s' "$json" > "$FIFO"
}

compact() {
  starship toggle os &&
  starship toggle username &&
  starship toggle hostname &&
  starship toggle git_branch &&
  starship toggle git_commit &&
  starship toggle git_metrics &&
  starship toggle git_status &&
  starship toggle cmd_duration &&
  starship toggle status &&
  starship toggle battery &&
  starship toggle time &&
  starship toggle python &&
  starship toggle docker_context &&
  starship toggle nodejs &&
  starship toggle rust &&
  starship toggle golang &&
  starship toggle c &&
  starship toggle kotlin &&
  starship toggle nix_shell &&
  
  send_notify "Переключен компактный режим" "info" "pop"
  
  exit 0
}

# === Использование ===
method="${1:-compact}"

case "$method" in
  compact)       compact            ;;
  *)             echo "Error args" ;;
esac

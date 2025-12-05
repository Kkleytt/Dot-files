#!/usr/bin/env bash
# /scripts/hyprland/decorate/script.sh
set -euo pipefail

send_notify() {
  local body="$1"
  local icon="$2"
  local sound="${3:-"system"}"

  local FIFO="$HOME/.cache/caelestia/osd.fifo"

  # Формируем JSON одной строкой
  local json
  json=$(printf '{"group":"hyprland-decoration","title":"Decoration","body":"%s","icon":"%s","timeout":2500,"sound":"%s","urgency":"normal"}\n' \
        "$body" "$icon" "$sound")

  # Записываем в FIFO
  printf '%s' "$json" > "$FIFO"
}

change_blur() {
  local notify="$1"
  local state=$(hyprctl -j getoption decoration:blur:passes | jq ".int")

	if [ "${state}" == "2" ]; then
		hyprctl keyword decoration:blur:size 1
		hyprctl keyword decoration:blur:passes 1
    [[ "$notify" == true ]] && send_notify "Less blur" "blur-off" "toggle"
	else
		hyprctl keyword decoration:blur:size 5
		hyprctl keyword decoration:blur:passes 2
		[[ "$notify" == true ]] && send_notify "Normal blur" "blur" "toggle"
	fi
}

change_opacity() {
  local notify="$1"

  hyprctl dispatch setprop active opaque toggle
  [[ "$notify" == true ]] && send_notify "Change opacity" "opacity" "toggle"
}

change_layout() {
  local notify="$1"

  current=$(hyprctl -j getoption general:layout | jq -r '.str')
  echo "$current"

  case "$current" in
    dwindle)
      hyprctl keyword general:layout master
      [[ "$notify" == true ]] && send_notify "Master layout" "layout" "toggle" ;;
    master)
      hyprctl keyword general:layout dwindle
      [[ "$notify" == true ]] && send_notify "Dwindle layout" "layout" "toggle" ;;
    *)
      hyprctl keyword general:layout dwindle
      [[ "$notify" == true ]] && send_notify "Dwindle layout" "layout" "toggle" ;;
  esac
}

game_mode() {
  local notify="$1"
  
  local STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/hypr_gamemode.state"
  local WALLPAPER_FILE="$HOME/.config/caelestia/theme/current/wallpaper/current"

  mkdir -p "${XDG_RUNTIME_DIR:-/tmp}"
  echo "$STATE_FILE"

  # --- Вспомогательные функции ---
  get_option() {
    hyprctl getoption "$1" -j | jq -r '.int // .float // .str'
  }

  save_current_settings() {
    echo "animations_enabled=$(get_option animations:enabled)" > "$STATE_FILE"
    echo "shadow_enabled=$(get_option decoration:shadow:enabled)" >> "$STATE_FILE"
    echo "blur_enabled=$(get_option decoration:blur:enabled)" >> "$STATE_FILE"
    echo "gaps_in=$(get_option general:gaps_in)" >> "$STATE_FILE"
    echo "gaps_out=$(get_option general:gaps_out)" >> "$STATE_FILE"
    echo "border_size=$(get_option general:border_size)" >> "$STATE_FILE"
    echo "rounding=$(get_option decoration:rounding)" >> "$STATE_FILE"
    echo "gamemode=1" >> "$STATE_FILE"
  }

  apply_settings_from_file() {
    if [ ! -f "$STATE_FILE" ]; then
      return 1
    fi
    while IFS='=' read -r key value; do
      case "$key" in
        animations_enabled)     hyprctl keyword animations:enabled "$value" ;;
        shadow_enabled)         hyprctl keyword decoration:shadow:enabled "$value" ;;
        blur_enabled)           hyprctl keyword decoration:blur:enabled "$value" ;;
        gaps_in)                hyprctl keyword general:gaps_in "$value" ;;
        gaps_out)               hyprctl keyword general:gaps_out "$value" ;;
        border_size)            hyprctl keyword general:border_size "$value" ;;
        rounding)               hyprctl keyword decoration:rounding "$value" ;;
      esac
    done < "$STATE_FILE"
  }

  close_applications() {
    caelestia-shell kill &>/dev/null


    local _ps=(waybar qs rofi swaync ags hyprpanel)
    for _prs in "${_ps[@]}"; do
      if pidof "${_prs}" >/dev/null; then
        pkill "${_prs}"
      fi
    done
    for pid in $(pidof waybar rofi swaync ags swaybg); do
      kill -SIGUSR1 "$pid"
    done
  }

  if [ -f "$STATE_FILE" ] && grep -q "^gamemode=1$" "$STATE_FILE"; then
    apply_settings_from_file
    rm -f "$STATE_FILE"

    caelestia shell -d
    [[ "$notify" == true ]] && send_notify "Gamemode disabled" "gamepad-off" "toggle"
  else
    save_current_settings
    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:enabled 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0"
	
    close_applications
  fi
}


# === Аргументы ===
method="${1:-opacity}"      # Стандартный метод создания скриншота
notify="${2:-true}"         # Уведомления

# === Запуск ===
case "$method" in
  opacity)                  change_opacity    "$notify"     ;;
  blur)                     change_blur       "$notify"     ;;
  layout)                   change_layout     "$notify"     ;;
  game)                     game_mode         "$notify"     ;;
  *)                        echo              "Error args"  ;;
esac

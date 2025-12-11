#!/usr/bin/env bash
# scripts/caelestia/lock/script.sh

# Стандартные значения
CONFIG_PATH="$HOME/.config/caelestia/shell.json" # Путь к файлу конфигурации Caelestia

send_notify() {
  local body="$1"
  local icon="$2"
  local sound="$3"

  local FIFO="$HOME/.cache/caelestia/osd.fifo"

  # Формируем JSON одной строкой
  local json
  json=$(printf '{"group":"caelestia-panels","title":"Caelestia","body":"%s","icon":"%s","timeout":2500,"sound":"%s","urgency":"normal"}\n' \
        "$body" "$icon" "$sound")

  # Записываем в FIFO
  printf '%s' "$json" > "$FIFO"
}

toggle() {
  local panel="$1"

  caelestia shell drawers toggle "$panel"
}

bar() {
  get_config_value() {
    local config_path="$1"
    local key="$2"

    if [[ -f "$config_path" ]]; then
      jq -r "$key" "$config_path" 2>/dev/null
    else
      echo "Error: config not found" >&2
      return 1
    fi
  }

  change_bool() {
    local config_path="$1"
    local key="$2"
    local value="$3"
    local current

    if ! command -v jq >/dev/null 2>&1; then
      echo "Error: 'jq' is required" >&2
      return 1
    fi

    if [[ "$value" == "toggle" ]]; then
      current=$(get_config_value "$config_path" "$key")
      echo "$current"
    elif [[ "$value" == "disable" ]]; then
      current="true"
    else
      current="false"
    fi

    case "$current" in
      true) jq "$key = false" "$config_path" > "$config_path.tmp"; mv "$config_path.tmp" "$config_path" ;;
      false) jq "$key = true" "$config_path" > "$config_path.tmp"; mv "$config_path.tmp" "$config_path" ;;
      *) jq "$key = true" "$config_path" > "$config_path.tmp"; mv "$config_path.tmp" "$config_path" ;;
    esac
  }

  hide(){
    change_bool "$CONFIG_PATH" '.bar.persistent' "disable" "$1"
    [[ "$notify" == true ]] && send_notify "Hide bar" "hide" "toggle"
  }
  show(){
    change_bool "$CONFIG_PATH" '.bar.persistent' "enable"
    [[ "$notify" == true ]] && send_notify "Unhide bar" "unhide" "toggle"
  }
  toggle_hide(){
    local current=$(change_bool "$CONFIG_PATH" '.bar.persistent' "toggle")

    [[ "$current" == "true" ]] && [[ "$1" == true ]] && send_notify "Hide bar" "hide" "toggle"
    [[ "$current" == "false" ]] && [[ "$1" == true ]] &&send_notify "Unhide bar" "unhide" "toggle"
    exit 0
  }

  move() {
    change_bool "$CONFIG_PATH" '.bar.popouts.statusIcons' "enable" "$1"
    change_bool "$CONFIG_PATH" '.bar.popouts.tray' "enable" "$1"
    send_notify "Moveble bar" "direction" "toggle"
  }
  unmove() {
    change_bool "$CONFIG_PATH" '.bar.popouts.statusIcons' "disable" "$1"
    change_bool "$CONFIG_PATH" '.bar.popouts.tray' "disable" "$1"
    send_notify "Unmoveble bar" "direction-off" "toggle"
  }
  toggle_move() {
    local current=$(change_bool "$CONFIG_PATH" '.bar.popouts.statusIcons' "toggle")
    change_bool "$CONFIG_PATH" '.bar.popouts.tray' "toggle"

    if [[ "$current" == "false" ]] && [[ "$1" == true ]]; then
      send_notify "Moveble bar" "direction" "toggle"
    elif [[ "$current" == "true" ]] && [[ "$1" == true ]]; then
      send_notify "Unmoveble bar" "direction-off" "toggle"
    fi
    
    exit 0
  }

  local method="$1"
  local notify="$2"

  case "$method" in
    hide)           hide "$notify" ;;
    show)           show "$notify" ;;
    toggle_hide)    toggle_hide "$notify" ;;
    move)           move "$notify" ;;
    unmove)         unmove "$notify" ;;
    toggle_move)    toggle_move "$notify" ;;
    *)              echo "Error args" ;;
  esac
}

# Аргументы
method="${1:-sidebar}"      # Стандартный метод управления панелями
arg_1="${2:-toggle_hide}"   # Стандартный метод управления баром
notify="${3:-true}"         # Уведомления

case "$1" in
  launcher)                 toggle  "launcher"        "$notify" ;;
  sidebar)                  toggle  "sidebar"         "$notify" ;;
  dashboard)                toggle  "dashboard"       "$notify" ;;
  session)                  toggle  "session"         "$notify" ;;
  bar)                      bar     "$arg_1"          "$notify" ;;
  *)                        echo    "Error args"                ;;
esac
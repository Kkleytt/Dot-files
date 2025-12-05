#!/usr/bin/env bash


start_app() {
  local app="$1"
  local dir="$2"

  cd "$dir"
  source ".venv/bin/activate"
  pgrep -x rofi >/dev/null && pkill rofi || "$app"
}

appName="${1:-wallpapers}"
appDir="${2:-"$HOME/.config/caelestia/cli/scripts/python"}"

# Start Python Application
start_app "$appName" "$appDir"
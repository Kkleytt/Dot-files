#!/bin/sh


check_waybar() {
    pkill -SIGUSR1 waybar
};

check_hyprpanel() {
    if pgrep hyprpanel >/dev/null; then
        pkill hyprpanel
    else
        pkill swaync &
        hyprpanel &
    fi
};

check_caelestia() {
    local mode="$1"
    local config_file="$HOME/.config/caelestia/shell.json"

    if [[ "$mode" == "shadow" ]]; then
        # Toggle "persistent" in config.json only
        if [[ -f "$config_file" ]]; then
            # Ensure jq is available
            if ! command -v jq >/dev/null 2>&1; then
                echo "Error: 'jq' is required to modify JSON config." >&2
                return 1
            fi

            # Read current value
            current=$(jq -r '.bar.persistent' "$config_file" 2>/dev/null)

            echo "Current value: $current"

            if [[ "$current" == "true" ]]; then
                jq '.bar.persistent = false' "$config_file" > "$config_file.tmp" && mv "$config_file.tmp" "$config_file"
            elif [[ "$current" == "false" ]]; then
                jq '.bar.persistent = true' "$config_file" > "$config_file.tmp" && mv "$config_file.tmp" "$config_file"
            else
                # If key is missing or invalid, set to true by default
                jq '.bar.persistent |= (if . == null then true else . end)' "$config_file" > "$config_file.tmp" && mv "$config_file.tmp" "$config_file"
            fi
        else
            echo "Config file not found: $config_file" >&2
        fi
        return 0
    elif [[ "$mode" == "reload" ]]; then
        echo "Reloading Caelestia shell ..."
        caelestia-shell kill
        sleep 2
        caelestia-shell -d
    elif [[ "$mode" == "off" ]]; then
        echo "Killing Caelestia shell ..."
        caelestia-shell kill
    elif [[ "$mode" == "on" ]]; then
        echo "Starting Caelestia shell ..."
        caelestia-shell -d
    else
        echo "Unknown method. Usage: $0 {reload|off|on|shadow}" >&2
    fi
}
    

bar="$1"
mode="$2"

if [ "$bar" = "waybar" ]; then
    check_waybar "$mode"
elif [ "$bar" = "hyprpanel" ]; then
    check_hyprpanel "$mode"
elif [ "$bar" == "caelestia" ]; then
    check_caelestia "$mode"
else
    echo "Usage: $0 {waybar|hyprpanel|caelestia} {reload|off|on|shadow}" >&2
    exit 1
fi
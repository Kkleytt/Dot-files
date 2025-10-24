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
    local shadow="$1"
    local config_file="$HOME/.config/caelestia/shell.json"

    if [[ "$shadow" == "1" ]]; then
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
    fi

    # Normal toggle: launch or kill
    if pgrep -f "quickshell-wrapped" >/dev/null; then
        caelestia-shell kill
    else
        caelestia-shell
    fi
}
    



bar="$1"
shadow="$2"

if [ "$bar" = "waybar" ]; then
    check_waybar
elif [ "$bar" = "hyprpanel" ]; then
    check_hyprpanel
elif [ "$bar" == "caelestia" ]; then
    check_caelestia "$shadow"
else
    echo "Usage: $0 {waybar|hyprpanel|caelestia} & $1 {1|0}" >&2
    exit 1
fi
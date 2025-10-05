#!/bin/bash

# WALLPAPERS PATH
terminal=kitty
wallDIR="$HOME/Libraries/Pictures/Wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"

# Directory for swaync
iDIR="$HOME/.config/swaync/images"
iDIRi="$HOME/.config/swaync/icons"

# swww transition config
FPS=60
TYPE="any"
DURATION=2
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

# Check if package bc exists
if ! command -v bc &>/dev/null; then
  notify-send -i "$iDIR/error.png" "bc missing" "Install package bc first"
  exit 1
fi

# Variables
rofi_theme="$HOME/.config/rofi/config-wallpaper.rasi"
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

# Ensure focused_monitor is detected
if [[ -z "$focused_monitor" ]]; then
  notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Could not detect focused monitor"
  exit 1
fi

# Monitor details
scale_factor=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .scale')
monitor_height=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .height')

icon_size=$(echo "scale=1; ($monitor_height * 3) / ($scale_factor * 150)" | bc)
adjusted_icon_size=$(echo "$icon_size" | awk '{if ($1 < 15) $1 = 20; if ($1 > 25) $1 = 25; print $1}')
rofi_override="element-icon{size:${adjusted_icon_size}%;}"

BASE_DIR="$HOME/Libraries/Pictures/Wallpapers"
FOLDER_ICON="$HOME/.local/share/icons/folder.svg"
BACK_ICON="$HOME/.local/share/icons/back.svg"

# Настройки превью
ICON_SIZE=25
COLUMNS=5
ROFI_THEME="$HOME/.config/rofi/config-wallpaper.rasi"
ROFI_OVERRIDE="
element-icon { size: ${ICON_SIZE}%; }
configuration { columns: 4; }
element { width: $((100 / COLUMNS))%; }
"

modify_startup_config() {
  local selected_file="$1"
  local startup_config="$HOME/.config/hypr/UserConfigs/Startup_Apps.conf"

  # Check if it's a live wallpaper (video)
  if [[ "$selected_file" =~ \.(mp4|mkv|mov|webm)$ ]]; then
    # For video wallpapers:
    sed -i '/^\s*exec-once\s*=\s*swww-daemon\s*--format\s*xrgb\s*$/s/^/\#/' "$startup_config"
    sed -i '/^\s*#\s*exec-once\s*=\s*mpvpaper\s*.*$/s/^#\s*//;' "$startup_config"

    # Update the livewallpaper variable with the selected video path (using $HOME)
    selected_file="${selected_file/#$HOME/\$HOME}" # Replace /home/user with $HOME
    sed -i "s|^\$livewallpaper=.*|\$livewallpaper=\"$selected_file\"|" "$startup_config"

    echo "Configured for live wallpaper (video)."
  else
    # For image wallpapers:
    sed -i '/^\s*#\s*exec-once\s*=\s*swww-daemon\s*--format\s*xrgb\s*$/s/^\s*#\s*//;' "$startup_config"

    sed -i '/^\s*exec-once\s*=\s*mpvpaper\s*.*$/s/^/\#/' "$startup_config"

    echo "Configured for static wallpaper (image)."
  fi
}

# STEP 3. Kill Programs For Change Wallpapaer
kill_wallpaper_for_video() {
  swww kill 2>/dev/null
  pkill mpvpaper 2>/dev/null
  pkill swaybg 2>/dev/null
  pkill hyprpaper 2>/dev/null
}
kill_wallpaper_for_image() {
  pkill mpvpaper 2>/dev/null
  pkill swaybg 2>/dev/null
  pkill hyprpaper 2>/dev/null
  pkill hyprpanel 2>/dev/null
}


# STEP 4. Set Wallpapers on Desktop Space
set_sddm_wallpaper() {
  sleep 1
  sddm_simple="/usr/share/sddm/themes/simple_sddm_2"

  if [ -d "$sddm_simple" ]; then

    # Check if yad is running to avoid multiple notifications
    if pidof yad >/dev/null; then
      killall yad
    fi

    if yad --info --text="Set current wallpaper as SDDM background?\n\nNOTE: This only applies to SIMPLE SDDM v2 Theme" \
      --text-align=left \
      --title="SDDM Background" \
      --timeout=5 \
      --timeout-indicator=right \
      --button="yes:0" \
      --button="no:1"; then

      # Check if terminal exists
      if ! command -v "$terminal" &>/dev/null; then
        notify-send -i "$iDIR/error.png" "Missing $terminal" "Install $terminal to enable setting of wallpaper background"
        exit 1
      fi
	  
	  exec $SCRIPTSDIR/sddm_wallpaper.sh --normal
    
    fi
  fi
}


# STEP 2. Apply Image Wallpaper
apply_image_wallpaper() {
  local image_path="$1"

  kill_wallpaper_for_image

  if ! pgrep -x "swww-daemon" >/dev/null; then
    echo "Starting swww-daemon..."
    swww-daemon --format xrgb &
  fi

  swww img -o "$focused_monitor" "$image_path" $SWWW_PARAMS
  wal -i "$image_path"

  # Run additional scripts
  "$SCRIPTSDIR/WallustSwww.sh"
  sleep 2
  "$SCRIPTSDIR/Refresh.sh"
  sleep 1

  hyprpanel

  set_sddm_wallpaper
}
apply_video_wallpaper() {
  local video_path="$1"

  # Check if mpvpaper is installed
  if ! command -v mpvpaper &>/dev/null; then
    notify-send -i "$iDIR/error.png" "E-R-R-O-R" "mpvpaper not found"
    return 1
  fi
  kill_wallpaper_for_video

  # Apply video wallpaper using mpvpaper
  mpvpaper '*' -o "load-scripts=no no-audio --loop" "$video_path" &
}


# STEP 1. Print Rofi Menu
prompt_selection() {
    local current_dir="$1"
    local parent_dir="$(dirname "$current_dir")"

    local random_file_path=""
    if [[ "$current_dir" == "$BASE_DIR" ]]; then
        mapfile -t all_files < <(find "$BASE_DIR" -type f \( \
            -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o \
            -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.webp" -o \
            -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.webm" \))
        if [[ ${#all_files[@]} -gt 0 ]]; then
            random_file_path="${all_files[RANDOM % ${#all_files[@]}]}"
        fi
    fi
    {

        # Если мы в корне — добавляем Random первым пунктом, иначе кнопка - Назад
        if [[ "$current_dir" == "$BASE_DIR" ]]; then
            printf "Random\0icon\x1f%s\n" "$random_file_path"
        else
            printf "Назад\0icon\x1f%s\n" "$BACK_ICON"
        fi

        # Папки
        find "$current_dir" -mindepth 1 -maxdepth 1 -type d | sort | while read -r dir; do
            printf "%s\0icon\x1f%s\n" "$(basename "$dir")" "$FOLDER_ICON"
        done

        # Файлы
        find "$current_dir" -mindepth 1 -maxdepth 1 -type f \( \
            -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o \
            -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.webp" -o \
            -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.webm" \) | sort | while read -r file; do
            printf "%s\0icon\x1f%s\n" "$(basename "$file")" "$file"
        done
    } | rofi -dmenu -show-icons -config "$ROFI_THEME" -theme-str "$ROFI_OVERRIDE" -p "Select Wallpaper" \
      | { read -r selection || exit 0

        [[ -z "$selection" ]] && return

        if [[ "$selection" == "Назад" ]]; then
            prompt_selection "$parent_dir"
            return
        fi

        if [[ "$selection" == "Random" ]]; then
            echo $current_dir
            echo $random_file_path
            if [[ "$random_file_path" =~ \.(mp4|mkv|mov|webm|MP4|MKV|MOV|WEBM)$ ]]; then
                apply_video_wallpaper "$random_file_path"
            else
                apply_image_wallpaper "$random_file_path"
            fi
            return
        fi

        local full_path="$current_dir/$selection"

        if [ -d "$full_path" ]; then
            prompt_selection "$full_path"
        elif [ -f "$full_path" ]; then
            modify_startup_config "$selected_file"

            if [[ "$full_path" =~ \.(mp4|mkv|mov|webm|MP4|MKV|MOV|WEBM)$ ]]; then
                apply_video_wallpaper "$full_path"
            else
                apply_image_wallpaper "$full_path"
            fi
        fi
      }
}

prompt_selection "$BASE_DIR"

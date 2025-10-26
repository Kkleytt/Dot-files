#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_FILE="$HOME/.local/state/caelestia/wallpaper/current"
PALETTE_FILE="$HOME/.config/hypr/scheme/current.conf"       # Актуальна палитра цветов (в формате RGB)
KITTY_THEME="$HOME/.config/kitty/current-theme.conf"        # Файл с палитрой для Kitty
ROFI_COLORS="$HOME/.cache/wal/colors-rofi-dark.rasi"        # Файл с палитрой для Rofi

mkdir -p "$(dirname "$KITTY_THEME")" "$(dirname "$ROFI_COLORS")"

# === Функция: извлечь цвет из палитры ===
get_color() {
  local var_name="$1"
  local default="$2"
  local value

  # Ищем строку: "$var_name = значение"
  value=$(awk -F ' *= *' -v key="\$${var_name}" '
    $1 == key && NF >= 2 {
      gsub(/^[ \t]+|[ \t]+$/, "", $2)
      gsub(/[^0-9a-fA-F]/, "", $2)
      if (length($2) == 6) {
        print $2
        exit
      }
    }
  ' "$PALETTE_FILE")

  if [[ -n "$value" ]]; then
    echo "#$value"
  else
    echo "$default"
  fi
}

# === Функция: генерация темы для Kitty ===
generate_kitty_theme() {
  if [[ ! -f "$PALETTE_FILE" ]]; then
    echo "Palette file not found: $PALETTE_FILE" >&2
    return 1
  fi

  awk '
    function to_hex(val) {
      gsub(/[^0-9a-fA-F]/, "", val)
      if (length(val) == 6) return "#" val
      return "#000000"
    }
    /^[$]background/      { bg = to_hex($3) }
    /^[$]onBackground/    { fg = to_hex($3) }
    /^[$]term4/          { cursor = to_hex($3) }
    /^[$]term0/           { c0 = to_hex($3) }
    /^[$]term1/           { c1 = to_hex($3) }
    /^[$]term2/           { c2 = to_hex($3) }
    /^[$]term3/           { c3 = to_hex($3) }
    /^[$]term4/           { c4 = to_hex($3) }
    /^[$]term5/           { c5 = to_hex($3) }
    /^[$]term6/           { c6 = to_hex($3) }
    /^[$]term7/           { c7 = to_hex($3) }
    /^[$]term8/           { c8 = to_hex($3) }
    /^[$]term9/           { c9 = to_hex($3) }
    /^[$]term10/          { c10 = to_hex($3) }
    /^[$]term11/          { c11 = to_hex($3) }
    /^[$]term12/          { c12 = to_hex($3) }
    /^[$]term13/          { c13 = to_hex($3) }
    /^[$]term14/          { c14 = to_hex($3) }
    /^[$]term15/          { c15 = to_hex($3) }
    END {
      if (bg == "") bg = "#12140d"
      if (fg == "") fg = "#e3e3d7"
      if (cursor == "") cursor = fg
      print "background " bg
      print "foreground " fg
      print "cursor " cursor
      print "selection_background " fg
      print "color0 " (c0 ? c0 : bg)
      print "color1 " (c1 ? c1 : "#ff0000")
      print "color2 " (c2 ? c2 : "#00ff00")
      print "color3 " (c3 ? c3 : "#ffff00")
      print "color4 " (c4 ? c4 : "#0000ff")
      print "color5 " (c5 ? c5 : "#ff00ff")
      print "color6 " (c6 ? c6 : "#00ffff")
      print "color7 " (c7 ? c7 : fg)
      print "color8 " (c8 ? c8 : "#888888")
      print "color9 " (c9 ? c9 : "#ff5555")
      print "color10 " (c10 ? c10 : "#55ff55")
      print "color11 " (c11 ? c11 : "#ffff55")
      print "color12 " (c12 ? c12 : "#5555ff")
      print "color13 " (c13 ? c13 : "#ff55ff")
      print "color14 " (c14 ? c14 : "#55ffff")
      print "color15 " (c15 ? c15 : "#ffffff")
    }
  ' "$PALETTE_FILE" > "$KITTY_THEME.tmp" && mv "$KITTY_THEME.tmp" "$KITTY_THEME"

  echo "✅ Kitty theme updated at $(date)"
  
  # Обновляем все открытые окна Kitty
  if command -v kitty >/dev/null; then
    kitty @ set-colors --all "$KITTY_THEME" 2>/dev/null || true
  fi
}

# === ФУНКЦИЯ: ГЕНЕРАЦИЯ Rofi ЦВЕТОВ ===
generate_rofi_colors() {
  local bg fg border active_bg urgent_bg

  bg=$(get_color "background" "#12140d")
  fg=$(get_color "onBackground" "#e3e3d7")
  border=$(get_color "outlineVariant" "#45483c")
  active_bg=$(get_color "surfaceContainerHigh" "#292b23")
  urgent_bg=$(get_color "primary" "#bacf82")

  date=$(date +%Y-%m-%d)

  # Записываем colors.rasi
  cat > "$ROFI_COLORS" <<EOF
    /* Auto-generated from Caelestia palette ${date} */
    * {
        active-background:   ${active_bg};
        active-foreground:   @foreground;
        normal-background:   @background;
        normal-foreground:   @foreground;
        urgent-background:   ${urgent_bg};
        urgent-foreground:   @foreground;

        alternate-active-background: @background;
        alternate-active-foreground: @foreground;
        alternate-normal-background: @background;
        alternate-normal-foreground: @foreground;
        alternate-urgent-background: @background;
        alternate-urgent-foreground: @foreground;

        selected-active-background:   ${urgent_bg};
        selected-active-foreground:   @foreground;
        selected-normal-background:   ${active_bg};
        selected-normal-foreground:   @foreground;
        selected-urgent-background:   ${bg};
        selected-urgent-foreground:   @foreground;

        background-color: @background;
        background: ${bg};
        foreground: ${fg};
        border-color: ${bg};
        spacing: 2;
    }

    #window {
        background-color: @background;
        border: 0;
        padding: 2.5ch;
    }

    #mainbox {
        border: 0;
        padding: 0;
    }

    #message {
        border: 2px 0px 0px;
        border-color: @border-color;
        padding: 1px;
    }

    #textbox {
        text-color: @foreground;
    }

    #inputbar {
        children:   [ prompt,textbox-prompt-colon,entry,case-indicator ];
    }

    #textbox-prompt-colon {
        expand: false;
        str: ":";
        margin: 0px 0.3em 0em 0em;
        text-color: @normal-foreground;
    }

    #listview {
        fixed-height: 0;
        border: 2px 0px 0px;
        border-color: @border-color;
        spacing: 2px;
        scrollbar: true;
        padding: 2px 0px 0px;
    }

    #element {
        border: 0;
        padding: 1px;
    }

    #element-text, element-icon {
        background-color: inherit;
        text-color:       inherit;
    }

    #element.normal.normal {
        background-color: @normal-background;
        text-color: @normal-foreground;
    }

    #element.normal.urgent {
        background-color: @urgent-background;
        text-color: @urgent-foreground;
    }

    #element.normal.active {
        background-color: @active-background;
        text-color: @active-foreground;
    }

    #element.selected.normal {
        background-color: @selected-normal-background;
        text-color: @selected-normal-foreground;
    }

    #element.selected.urgent {
        background-color: @selected-urgent-background;
        text-color: @selected-urgent-foreground;
    }

    #element.selected.active {
        background-color: @selected-active-background;
        text-color: @selected-active-foreground;
    }

    #element.alternate.normal {
        background-color: @alternate-normal-background;
        text-color: @alternate-normal-foreground;
    }

    #element.alternate.urgent {
        background-color: @alternate-urgent-background;
        text-color: @alternate-urgent-foreground;
    }

    #element.alternate.active {
        background-color: @alternate-active-background;
        text-color: @alternate-active-foreground;
    }

    #scrollbar {
        width: 4px;
        border: 0;
        handle-width: 8px;
        padding: 0;
    }

    #sidebar {
        border: 2px 0px 0px;
        border-color: @border-color;
    }

    #button {
        text-color: @normal-foreground;
    }

    #button.selected {
        background-color: @selected-normal-background;
        text-color: @selected-normal-foreground;
    }

    #inputbar {
        spacing: 0;
        text-color: @normal-foreground;
        padding: 1px;
    }

    #case-indicator {
        spacing: 0;
        text-color: @normal-foreground;
    }

    #entry {
        spacing: 0;
        text-color: @normal-foreground;
    }

    #prompt {
        spacing: 0;
        text-color: @normal-foreground;
    }
EOF
  echo "🎨 Rofi colors updated"
  cp "$WALLPAPER_FILE" "$HOME/.config/rofi/.current_wallpaper"
  echo "🖼️ Rofi wallpaper updated"
}

# === Основная функция обновления ===
update_themes() {
  if [[ ! -f "$PALETTE_FILE" ]]; then
    echo "Palette not found: $PALETTE_FILE" >&2
    return 1
  fi

  generate_kitty_theme
  generate_rofi_colors

  # Обновляем открытые окна Kitty
  kitty @ set-colors --all "$KITTY_THEME" 2>/dev/null || true
}

# === Запуск при старте + наблюдение ===
if [[ -f "$PALETTE_FILE" ]]; then
  update_themes
fi

while true; do
  inotifywait -e modify,move,create,delete "$PALETTE_FILE" >/dev/null 2>&1 && \
    update_themes
done
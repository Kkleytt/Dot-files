import json
import os
import re
import shutil
from pathlib import Path

import config as cfg
from generator import get_caelestia_palette

# Кэш палитры в памяти (один на весь процесс)
_PALETTE_CACHE: dict[str, str] = {}

def hyprland_parser():
    def parse_hypr_config(path):
        raw_vars = {}
        with open(path, "read", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue

                # Удаляем комментарии в конце строки
                line = line.split("#")[0].strip()

                match = re.match(r'^\$([a-zA-Z0-9_]+)\s*=\s*(.+)$', line)
                if match:
                    key, value = match.groups()
                    value = value.strip().strip('"').strip("'")
                    raw_vars[key] = value

        return raw_vars

    def resolve_variables(raw_vars):
        resolved = {}
        env = os.environ.copy()

        def expand(value, depth=0):
            if depth > 10:
                return value

            pattern = re.compile(r'\$(\w+)|\${(\w+)}')
            def replacer(match):
                var_name = match.group(1) or match.group(2)
                replacement = resolved.get(var_name) or raw_vars.get(var_name) or env.get(var_name, "")
                return replacement

            new_value = pattern.sub(replacer, value)
            if new_value != value:
                return expand(new_value, depth + 1)
            return new_value.strip()

        for key in raw_vars:
            resolved[key] = expand(raw_vars[key])
            
        return resolved

    def save_json(data, path):
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        print(f"[ ✅️ ] JSON saved to: {path}\n")

    raw = parse_hypr_config(cfg.HYPRLAND_VARIABLES_PATH)
    resolved = resolve_variables(raw)
    save_json(resolved, cfg.HYPRLAND_VARIABLES_JSON_PATH)

def wallpaper_parser():
    try:
        # читаем строку с путём к обоям
        path = cfg.CAELESTIA_WALLPAPER_PATH.read_text(encoding="utf-8").strip()
        src = Path(path)

        if not src.exists():
            print(f"❌ Wallpaper file not found: {src}")
            return

        # копируем файл
        shutil.copy(src, cfg.GLOBAL_WALLPAPER_FILE)
        shutil.copy(cfg.CAELESTIA_WALLPAPER_PATH, cfg.GLOBAL_WALLPAPER_PATH)
        print(f"✅ Wallpaper copied to: {cfg.GLOBAL_WALLPAPER_FILE}")
        print(f"✅ Wallpaper path copied to: {cfg.GLOBAL_WALLPAPER_PATH}")

    except Exception as e:
        print(f"⚠️ Error: {e}")

def pallete_parser():
    def get_color(var_name: str, default: str = "#ffffff", *, update: bool = False, image_path: Path | None = None) -> str:
        global _PALETTE_CACHE

        # Специальный режим — пересоздать палитру из фото
        if update and image_path and image_path.exists():
            # new_palette = get_image_palette(image_path)
            new_palette = get_caelestia_palette()
            _PALETTE_CACHE = new_palette  # обновляем кэш

            # Можно сразу сохранить на диск, если хочешь
            # (Path("/tmp/latest_palette.json").write_text(json.dumps(new_palette, indent=2)))

        # Если кэш пустой — пробуем загрузить из старого файла (обратная совместимость)
        if not _PALETTE_CACHE and Path("CAELESTIA_COLORS_PATH").exists():  # замени на свою переменную
            # твой старый код парсинга файла — оставляем как fallback
            pattern = re.compile(rf"^\${var_name}\s*=\s*(.+)$")
            with cfg.CAELESTIA_COLORS_PATH.open(encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith("#"):
                        continue
                    m = pattern.match(line)
                    if m:
                        hexval = re.sub(r"[^0-9a-fA-F]", "", m.group(1).strip())
                        if len(hexval) == 6:
                            return f"#{hexval.lower()}"
                        break

        # Возвращаем из кэша или дефолт
        return _PALETTE_CACHE.get(var_name, default)
    
    def example_colors():
        lines = [
            "",
            f"primary_paletteKeyColor         = {get_color("primary_paletteKeyColor", "#ad634d")}",
            f"secondary_paletteKeyColor       = {get_color("secondary_paletteKeyColor", "#926f65")}",
            f"tertiary_paletteKeyColor        = {get_color("tertiary_paletteKeyColor", "#857645")}",
            f"neutral_paletteKeyColor         = {get_color("neutral_paletteKeyColor", "#827470")}",
            f"neutral_variant_paletteKeyColor = {get_color("neutral_variant_paletteKeyColor", "#85736e")}",
            f"background                      = {get_color("background", "#1a110f")}",
            f"onBackground                    = {get_color("onBackground", "#f1dfda")}",
            f"surface                         = {get_color("surface", "#1a110f")}",
            f"surfaceDim                      = {get_color("surfaceDim", "#1a110f")}",
            f"surfaceBright                   = {get_color("surfaceBright", "#423734")}",
            f"surfaceContainerLowest          = {get_color("surfaceContainerLowest", "#140c0a")}",
            f"surfaceContainerLow             = {get_color("surfaceContainerLow", "#231917")}",
            f"surfaceContainer                = {get_color("surfaceContainer", "#271d1b")}",
            f"surfaceContainerHigh            = {get_color("surfaceContainerHigh", "#322825")}",
            f"surfaceContainerHighest         = {get_color("surfaceContainerHighest", "#3d322f")}",
            f"onSurface                       = {get_color("onSurface", "#f1dfda")}",
            f"surfaceVariant                  = {get_color("surfaceVariant", "#53433f")}",
            f"onSurfaceVariant                = {get_color("onSurfaceVariant", "#d8c2bc")}",
            f"inverseSurface                  = {get_color("inverseSurface", "#f1dfda")}",
            f"inverseOnSurface                = {get_color("inverseOnSurface", "#392e2b")}",
            f"outline                         = {get_color("outline", "#a08c87")}",
            f"outlineVariant                  = {get_color("outlineVariant", "#53433f")}",
            f"shadow                          = {get_color("shadow", "#000000")}",
            f"scrim                           = {get_color("scrim", "#000000")}",
            f"surfaceTint                     = {get_color("surfaceTint", "#ffb59f")}",
            f"primary                         = {get_color("primary", "#ffb59f")}",
            f"onPrimary                       = {get_color("onPrimary", "#561f0e")}",
            f"primaryContainer                = {get_color("primaryContainer", "#723522")}",
            f"onPrimaryContainer              = {get_color("onPrimaryContainer", "#ffdbd1")}",
            f"inversePrimary                  = {get_color("inversePrimary", "#8f4c37")}",
            f"secondary                       = {get_color("secondary", "#e7bdb2")}",
            f"onSecondary                     = {get_color("onSecondary", "#442a22")}",
            f"secondaryContainer              = {get_color("secondaryContainer", "#604239")}",
            f"onSecondaryContainer            = {get_color("onSecondaryContainer", "#ffdbd1")}",
            f"tertiary                        = {get_color("tertiary", "#d8c68d")}",
            f"onTertiary                      = {get_color("onTertiary", "#3a2f05")}",
            f"tertiaryContainer               = {get_color("tertiaryContainer", "#a0905c")}",
            f"onTertiaryContainer             = {get_color("onTertiaryContainer", "#000000")}",
            f"error                           = {get_color("error", "#ffb4ab")}",
            f"onError                         = {get_color("onError", "#690005")}",
            f"errorContainer                  = {get_color("errorContainer", "#93000a")}",
            f"onErrorContainer                = {get_color("onErrorContainer", "#ffdad6")}",
            f"primaryFixed                    = {get_color("primaryFixed", "#ffdbd1")}",
            f"primaryFixedDim                 = {get_color("primaryFixedDim", "#ffb59f")}",
            f"onPrimaryFixed                  = {get_color("onPrimaryFixed", "#3a0b00")}",
            f"onPrimaryFixedVariant           = {get_color("onPrimaryFixedVariant", "#723522")}",
            f"secondaryFixed                  = {get_color("secondaryFixed", "#ffdbd1")}",
            f"secondaryFixedDim               = {get_color("secondaryFixedDim", "#e7bdb2")}",
            f"onSecondaryFixed                = {get_color("onSecondaryFixed", "#2c150f")}",
            f"onSecondaryFixedVariant         = {get_color("onSecondaryFixedVariant", "#5d4037")}",
            f"tertiaryFixed                   = {get_color("tertiaryFixed", "#f5e1a7")}",
            f"tertiaryFixedDim                = {get_color("tertiaryFixedDim", "#d8c68d")}",
            f"onTertiaryFixed                 = {get_color("onTertiaryFixed", "#231b00")}",
            f"onTertiaryFixedVariant          = {get_color("onTertiaryFixedVariant", "#524619")}",
            f"term0                           = {get_color("term0", "#353433")}",
            f"term1                           = {get_color("term1", "#ff572a")}",
            f"term2                           = {get_color("term2", "#ffbe97")}",
            f"term3                           = {get_color("term3", "#ffdfd2")}",
            f"term4                           = {get_color("term4", "#b9ab66")}",
            f"term5                           = {get_color("term5", "#f29082")}",
            f"term6                           = {get_color("term6", "#ffbb85")}",
            f"term7                           = {get_color("term7", "#efd2c7")}",
            f"term8                           = {get_color("term8", "#b49e96")}",
            f"term9                           = {get_color("term9", "#ff8766")}",
            f"term10                          = {get_color("term10", "#ffd5bd")}",
            f"term11                          = {get_color("term11", "#fff1ec")}",
            f"term12                          = {get_color("term12", "#dcbc93")}",
            f"term13                          = {get_color("term13", "#ffa99a")}",
            f"term14                          = {get_color("term14", "#ffd2b4")}",
            f"term15                          = {get_color("term15", "#ffffff")}",
            f"rosewater                       = {get_color("rosewater", "#ffeeea")}",
            f"flamingo                        = {get_color("flamingo", "#ffdad1")}",
            f"pink                            = {get_color("pink", "#ffd3ce")}",
            f"mauve                           = {get_color("mauve", "#ffa9aa")}",
            f"red                             = {get_color("red", "#ff9886")}",
            f"maroon                          = {get_color("maroon", "#faab9b")}",
            f"peach                           = {get_color("peach", "#ffbfa9")}",
            f"yellow                          = {get_color("yellow", "#ffeeee")}",
            f"green                           = {get_color("green", "#ffd8bd")}",
            f"teal                            = {get_color("teal", "#ffdb94")}",
            f"sky                             = {get_color("sky", "#e1df87")}",
            f"sapphire                        = {get_color("sapphire", "#f2b2f2")}",
            f"blue                            = {get_color("blue", "#ffa2bd")}",
            f"lavender                        = {get_color("lavender", "#ffbbc2")}",
            f"klink                           = {get_color("klink", "#bf6ba0")}",
            f"klinkSelection                  = {get_color("klinkSelection", "#bf6ba0")}",
            f"kvisited                        = {get_color("kvisited", "#cf5c5c")}",
            f"kvisitedSelection               = {get_color("kvisitedSelection", "#cf5c5c")}",
            f"knegative                       = {get_color("knegative", "#ea5735")}",
            f"knegativeSelection              = {get_color("knegativeSelection", "#ea5735")}",
            f"kneutral                        = {get_color("kneutral", "#ff8a5f")}",
            f"kneutralSelection               = {get_color("kneutralSelection", "#ff8a60")}",
            f"kpositive                       = {get_color("kpositive", "#f98e1b")}",
            f"kpositiveSelection              = {get_color("kpositiveSelection", "#f98e1b")}",
            f"text                            = {get_color("text", "#f1dfda")}",
            f"subtext1                        = {get_color("subtext1", "#d8c2bc")}",
            f"subtext0                        = {get_color("subtext0", "#a08c87")}",
            f"overlay2                        = {get_color("overlay2", "#8c7a75")}",
            f"overlay1                        = {get_color("overlay1", "#786763")}",
            f"overlay0                        = {get_color("overlay0", "#655652")}",
            f"surface2                        = {get_color("surface2", "#534542")}",
            f"surface1                        = {get_color("surface1", "#413431")}",
            f"surface0                        = {get_color("surface0", "#2d2220")}",
            f"base                            = {get_color("base", "#1a110f")}",
            f"mantle                          = {get_color("mantle", "#1a110f")}",
            f"crust                           = {get_color("crust", "#19100e")}",
            f"success                         = {get_color("success", "#B5CCBA")}",
            f"onSuccess                       = {get_color("onSuccess", "#213528")}",
            f"successContainer                = {get_color("successContainer", "#374B3E")}",
            f"onSuccessContainer              = {get_color("onSuccessContainer", "#D1E9D6")}"
        ]
        cfg.TEMPLATE_COLORS_PATH.write_text("\n".join(lines), encoding="utf-8")
        print(f"✅ Template colors palette updated: {cfg.TEMPLATE_COLORS_PATH}")
    
    def hyprland_colors():
        with open(cfg.CAELESTIA_COLORS_PATH, "read", encoding="utf-8") as f:
            content = f.read()

        # Выдираем только $name = hex и чистим до идеала
        lines = []
        for line in content.splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            match = re.match(r"^\$(\w+)\s*=\s*(.*)", line)
            if match:
                key = "$" + match.group(1)      # оставляем оригинальное имя переменной
                value = match.group(2).replace("#", "").replace("0x", "").strip().lower()
                value = value.zfill(6)[-6:]     # строго 6 символов
                lines.append(f"{key} = {value}")

        result = "\n".join(lines) + "\n"

        with open(cfg.HYPRLAND_COLOR_PATH, "w", encoding="utf-8", newline="\n") as f:
            f.write(result)  

        print(f"✅ Hyprland colors palette updated: {cfg.HYPRLAND_COLOR_PATH}")
        
    def kitty_colors():
        kitty_lines = [
            f"background {get_color("background", "#12140d")}",
            f"selection_background {get_color("onBackground", "#e3e3d7")}",
            f"foreground {get_color("onBackground", "#e3e3d7")}",
            f"cursor {get_color("term4", "#e3e3d7")}",
            f"color0 {get_color('term0', "#12140d")}",
            f"color1 {get_color('term1', '#ff0000')}",
            f"color2 {get_color('term2', '#00ff00')}",
            f"color3 {get_color('term3', '#ffff00')}",
            f"color4 {get_color('term4', '#0000ff')}",
            f"color5 {get_color('term5', '#ff00ff')}",
            f"color6 {get_color('term6', '#00ffff')}",
            f"color7 {get_color('term7', "#e3e3d7")}",
            f"color8 {get_color('term8', '#888888')}",
            f"color9 {get_color('term9', '#ff5555')}",
            f"color10 {get_color('term10', '#55ff55')}",
            f"color11 {get_color('term11', '#ffff55')}",
            f"color12 {get_color('term12', '#5555ff')}",
            f"color13 {get_color('term13', '#ff55ff')}",
            f"color14 {get_color('term14', '#55ffff')}",
            f"color15 {get_color('term15', '#ffffff')}",
        ]

        cfg.KITTY_COLORS_PATH.parent.mkdir(parents=True, exist_ok=True)
        cfg.KITTY_COLORS_PATH.write_text("\n".join(kitty_lines), encoding="utf-8")
        print(f"✅ Kitty colors palette updated: {cfg.KITTY_COLORS_PATH}")
    
    def rofi_colors():
        lines = [
            "* {",
            f"    active-background:   {get_color("surfaceContainerHigh", "#e3e3d7")};",
            f"    active-foreground:   {get_color("onBackground", "#e3e3d7")};",
            f"    normal-background:   {get_color("background", "#12140d")};",
            f"    normal-foreground:   {get_color("onBackground", "#e3e3d7")};",
            f"    urgent-background:   {get_color("primary", "#ff5555")};",
            f"    urgent-foreground:   {get_color("onBackground", "#e3e3d7")};",
            f"    alternate-active-background: {get_color("background", "#12140d")};",
            f"    alternate-active-foreground: {get_color("onBackground", "#e3e3d7")};",
            f"    alternate-normal-background: {get_color("background", "#12140d")};",
            f"    alternate-normal-foreground: {get_color("onBackground", "#e3e3d7")};",
            f"    alternate-urgent-background: {get_color("background", "#12140d")};",
            f"    alternate-urgent-foreground: {get_color("onBackground", "#e3e3d7")};",
            f"    selected-active-background:   {get_color("primary", "#ff5555")};",
            f"    selected-active-foreground:   {get_color("onBackground", "#e3e3d7")};",
            f"    selected-normal-background:   {get_color("surfaceContainerHigh", "#e3e3d7")};",
            f"    selected-normal-foreground:   {get_color("onBackground", "#e3e3d7")};",
            f"    selected-urgent-background:   {get_color("background", "#12140d")};",
            f"    selected-urgent-foreground:   {get_color("onBackground", "#e3e3d7")};",
            f"    background-color: {get_color("background", "#12140d")};",
            f"    background: {get_color("background", "#12140d")};",
            f"    foreground: {get_color("onBackground", "#e3e3d7")};",
            f"    border-color: {get_color("background", "#12140d")};",
            "    spacing: 2;",
            "}", "",
            "#window { background-color: @background; border: 0; padding: 2.5ch; }", "",
            "#mainbox { border: 0; padding: 0; }", "",
            "#message { border: 2px 0px 0px; border-color: @border-color; padding: 1px; }", "",
            "#textbox { text-color: @foreground; }", "",
            "#inputbar { children:   [ prompt,textbox-prompt-colon,entry,case-indicator ]; }", "",
            "#textbox-prompt-colon { expand: false; str: \":\"; margin: 0px 0.3em 0em 0em; text-color: @normal-foreground; }", "",
            "#listview { fixed-height: 0; border: 2px 0px 0px; border-color: @border-color; spacing: 2px; scrollbar: true; padding: 2px 0px 0px; }", "",
            "#element { border: 0; padding: 1px; }", "",
            "#element-text, element-icon { background-color: inherit; text-color: inherit; }", "",
            "#element.normal.normal { background-color: @normal-background; text-color: @normal-foreground; }", "",
            "#element.normal.urgent { background-color: @urgent-background; text-color: @urgent-foreground; }", "",
            "#element.normal.active { background-color: @active-background; text-color: @active-foreground; }", "",
            "#element.selected.normal { background-color: @selected-normal-background; text-color: @selected-normal-foreground; }", "",
            "#element.selected.urgent { background-color: @selected-urgent-background; text-color: @selected-urgent-foreground; }", "",
            "#element.selected.active { background-color: @selected-active-background; text-color: @selected-active-foreground; }", "",
            "#element.alternate.normal { background-color: @alternate-normal-background; text-color: @alternate-normal-foreground; }", "",
            "#element.alternate.urgent { background-color: @alternate-urgent-background; text-color: @alternate-urgent-foreground; }", "",
            "#element.alternate.active { background-color: @alternate-active-background; text-color: @alternate-active-foreground; }", "",
            "#scrollbar { width: 4px; border: 0; handle-width: 8px; padding: 0; }", "",
            "#sidebar { border: 2px 0px 0px; border-color: @border-color; }", "",
            "#button { text-color: @normal-foreground; }", "",
            "#button.selected { background-color: @selected-normal-background; text-color: @selected-normal-foreground; }", "",
            "#inputbar { spacing: 0; text-color: @normal-foreground; padding: 1px; }", "",
            "#case-indicator { spacing: 0; text-color: @normal-foreground; }", "",
            "#entry { spacing: 0; text-color: @normal-foreground; }", "",
            "#prompt { spacing: 0; text-color: @normal-foreground; }"
        ]
        
        cfg.ROFI_COLORS_PATH.parent.mkdir(parents=True, exist_ok=True)
        cfg.ROFI_COLORS_PATH.write_text("\n".join(lines), encoding="utf-8")
        print(f"✅ Rofi colors palette updated: {cfg.ROFI_COLORS_PATH}")
        
    def wezterm_colors():
        """
        Generate a minimal wezterm colors Lua file.
        get_color(key, default) -> str (e.g. "#rrggbb")
        Writes a Lua module returning M.colors.
        Manual escaping is used (no helpers).
        Returns the Path written.
        """
        # read palette values (fall back to defaults)
        def g(k, d):
            v = get_color(k, d)
            if v is None:
                v = d
            # ensure starts with #
            if not isinstance(v, str):
                v = str(v)
            if not v.startswith("#"):
                v = "#" + v.lstrip("$#")
            return v
    
        fg = g("text", "#e2e2e2")
        bg = g("background", "#141414")
        cursor = g("primary", "#c6c6c6")
        selection_bg = g("surfaceBright", "#393939")
        selection_fg = g("onBackground", fg)
    
        ansi = [
            g("term0", "#343434"),
            g("term1", "#7d9c38"),
            g("term2", "#8cdbc2"),
            g("term3", "#acf5d5"),
            g("term4", "#97b0ad"),
            g("term5", "#92adcf"),
            g("term6", "#a8d2c8"),
            g("term7", "#d8d8d8"),
        ]
        brights = [
            g("term8", "#a2a2a2"),
            g("term9", "#8eb63f"),
            g("term10", "#89f0d2"),
            g("term11", "#e9f8ee"),
            g("term12", "#bec2c0"),
            g("term13", "#b2bfdc"),
            g("term14", "#b3e6d9"),
            g("term15", "#ffffff"),
        ]
    
        tab_bg = g("surfaceContainerLow", "#1c1c1c")
        active_bg = g("surfaceContainerHigh", "#2a2a2a")
        active_fg = g("onBackground", fg)
        inactive_bg = g("surfaceContainer", "#202020")
        inactive_fg = g("subtext1", "#c6c6c6")
        inactive_hover_bg = g("surfaceContainerHighest", "#353535")
        inactive_hover_fg = g("onSurfaceVariant", g("onSurface", fg))
        new_tab_fg = g("primaryFixed", fg)
    
        lines = []
        lines.append("-- Auto-generated wezterm color file")
        lines.append("local M = {}")
        lines.append("M.colors = {")
        lines.append('  foreground = "' + fg + '",')
        lines.append('  background = "' + bg + '",')
        lines.append('  cursor_bg = "' + cursor + '",')
        lines.append('  cursor_fg = "' + bg + '",')
        lines.append('  cursor_border = "' + cursor + '",')
        lines.append('  selection_bg = "' + selection_bg + '",')
        lines.append('  selection_fg = "' + selection_fg + '",')
        lines.append("")
        # ansi
        lines.append("  ansi = { " + ", ".join('"' + c + '"' for c in ansi) + " },")
        lines.append("  brights = { " + ", ".join('"' + c + '"' for c in brights) + " },")
        lines.append("")
        # tab_bar
        lines.append("  tab_bar = {")
        lines.append('    background = "' + tab_bg + '",')
        lines.append('    active_tab = { bg_color = "' + active_bg + '", fg_color = "' + active_fg + '" },')
        lines.append('    inactive_tab = { bg_color = "' + inactive_bg + '", fg_color = "' + inactive_fg + '" },')
        lines.append('    inactive_tab_hover = { bg_color = "' + inactive_hover_bg + '", fg_color = "' + inactive_hover_fg + '" },')
        lines.append('    new_tab = { bg_color = "' + tab_bg + '", fg_color = "' + new_tab_fg + '" },')
        lines.append("  },")
        lines.append("")
        lines.append('  scrollbar_thumb = "' + g("surface2", "#494949") + '",')
        lines.append('  split = "' + g("surfaceVariant", "#474747") + '",')
        lines.append("")
        lines.append("}")
        lines.append("")
        lines.append("return M")
    
        cfg.WEZTERM_COLORS_PATH.parent.mkdir(parents=True, exist_ok=True)
        cfg.WEZTERM_COLORS_PATH.write_text("\n".join(lines), encoding="utf-8")
        print(f"✅ Wezterm colors palette updated: {cfg.WEZTERM_COLORS_PATH}")

    
    if not cfg.CAELESTIA_COLORS_PATH.exists():
        print(f"Caelestia palette file not found: {cfg.CAELESTIA_COLORS_PATH}")
        return
    
    # Обновление палитр
    image_path = Path(cfg.CAELESTIA_WALLPAPER_PATH.read_text(encoding="utf-8"))
    get_color(var_name="background", update=True, image_path=image_path)
    example_colors()
    hyprland_colors()
    kitty_colors()
    rofi_colors()
    wezterm_colors()

if __name__ == "__main__":
    hyprland_parser()
from pathlib import Path

home: Path = Path.home()

# Global path for directories
GLOBAL_PATH: Path                     = home / ".config" / "caelestia"
THEMES_PATH: Path                     = GLOBAL_PATH / "theme" / "current"

# Paths for hyprland variables
HYPRLAND_VARIABLES_PATH: Path         = home / ".config/hypr/configs/Variables.conf"
HYPRLAND_VARIABLES_JSON_PATH: Path    = THEMES_PATH / "hyprland_vars.json"

# Paths for color palettes
CAELESTIA_COLORS_PATH: Path           = home / ".config/hypr/scheme/current.conf"
KITTY_COLORS_PATH: Path               = THEMES_PATH / "colors" / "colors-kitty.conf"
HYPRLAND_COLOR_PATH: Path             = THEMES_PATH / "colors" /"colors-hyprland.conf"
TEMPLATE_COLORS_PATH: Path            = THEMES_PATH / "colors" /"colors-example.json"    
ROFI_COLORS_PATH: Path                = THEMES_PATH / "colors" /"colors-rofi.rasi"
WEZTERM_COLORS_PATH: Path             = THEMES_PATH / "colors" / "colors-wezterm.lua"

# Paths for wallpapers
CAELESTIA_WALLPAPER_PATH: Path        = home / ".local/state/caelestia/wallpaper/path.txt"
GLOBAL_WALLPAPER_PATH: Path           = THEMES_PATH / "wallpaper" / "wallpaper-path.txt"
GLOBAL_WALLPAPER_FILE: Path           = THEMES_PATH / "wallpaper" / "wallpaper-file"
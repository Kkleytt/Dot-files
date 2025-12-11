#!/usr/bin/env python3
import os
import subprocess
import sys
import pathlib
import time
import json
from typing import (Any, Dict)

BASE_DIR: str = os.environ.get("WALLPAPER_DIR", default=os.path.expanduser(path="~/Pictures/Wallpapers"))
ROFI_THEME: str = os.path.expanduser(path="~/.config/rofi/configs/wallpaper.rasi")
ICON_FOLDER: pathlib.Path = pathlib.Path.home() / ".config" / "caelestia" / "theme" / "icons"
IMAGE_EXTS: list[str] = [".jpg", ".jpeg", ".png", ".bmp", ".tiff", ".webp"]

def run(cmd, **kwargs) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args=cmd, shell=True, check=False, text=True, capture_output=True, **kwargs)

def ensure_hyprpaper_running() -> None:
    """Проверяет, запущен ли hyprpaper, и запускает его в фоне при необходимости."""
    result: subprocess.CompletedProcess[bytes] = subprocess.run(args=["pgrep", "-x", "hyprpaper"], stdout=subprocess.DEVNULL)
    if result.returncode != 0:
        subprocess.Popen(
            args=["hyprpaper"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        # даём время на инициализацию сокета
        time.sleep(0.3)
        
def get_focused_monitor() -> Any | None:
    out: str = run(cmd="hyprctl monitors -j").stdout
    import json
    monitors: Any = json.loads(s=out)
    for m in monitors:
        if m.get("focused"):
            return m["name"]
    return None

def get_monitor_info(focused=True) -> Dict | None:
    """Возвращает словарь с данными о мониторе (scale, height, name)."""
    result: subprocess.CompletedProcess[str] = subprocess.run(args=["hyprctl", "monitors", "-j"], capture_output=True, text=True)
    monitors: Any = json.loads(s=result.stdout)
    for mon in monitors:
        if focused and mon.get("focused"):
            return mon
    return None

def calc_icon_size(monitor_height, scale_factor) -> int:
    # формула из твоего скрипта
    raw_size: Any = (monitor_height * 3) / (scale_factor * 150)
    # ограничение диапазона
    if raw_size < 15:
        return 20
    if raw_size > 25:
        return 25
    return int(raw_size)
  
def rofi_override() -> str:
    monitor_info: Any | None = get_monitor_info()
    if not monitor_info:
        return ""
    monitor_height: int | None = monitor_info["height"]
    scale_factor: int | None = monitor_info["scale"]
    size: int = calc_icon_size(monitor_height, scale_factor)
    return f"""
    element-icon {{
        size: {size}%;
    }}
    configuration {{
        columns: 4;
    }}
    """

def apply_wallpaper(path, monitor):
    ext = pathlib.Path(path).suffix.lower()
    
    ensure_hyprpaper_running()

    # run(f"hyprctl hyprpaper preload {path}")
    # run(f"hyprctl hyprpaper wallpaper {monitor}, {path}")
    run(f"caelestia wallpaper -f {path}")

def rofi_menu(current_dir):
    entries = []
    if current_dir != BASE_DIR:
        entries.append(f"Назад\0icon\x1f{ICON_FOLDER / "rofi_back.svg"}")

    for d in sorted(pathlib.Path(current_dir).iterdir()):
        if d.is_dir() and not d.name.startswith("."):
            entries.append(f"{d.name}\0icon\x1f{ICON_FOLDER / "rofi_folder.svg"}")
    for f in sorted(pathlib.Path(current_dir).iterdir()):
        if f.is_file() and not f.name.startswith("."):
            if f.suffix.lower() in IMAGE_EXTS:
                entries.append(f"{f.name}\0icon\x1f{str(f)}")

    menu_input = "\n".join(entries)
    proc = subprocess.run(
        ["rofi", "-dmenu", "-show-icons", "-config", ROFI_THEME, "-theme-str", rofi_override(), "-p", "Wallpaper"],
        input=menu_input, text=True, capture_output=True
        
    )
    return proc.stdout.strip()

def navigate(current_dir):
    selection = rofi_menu(current_dir)
    print(selection)
    if not selection:
        return
    if selection.startswith("Назад"):
        navigate(str(pathlib.Path(current_dir).parent))
        return
    full_path = os.path.join(current_dir, selection)
    if os.path.isdir(full_path):
        navigate(full_path)
    elif os.path.isfile(full_path):
        monitor = get_focused_monitor()
        if monitor:
            apply_wallpaper(full_path, monitor)
        else:
            run('notify-send "No focused monitor"')

def app():
    if not os.path.isdir(BASE_DIR):
        run(f'notify-send "Wallpaper dir missing: {BASE_DIR}"')
        sys.exit(1)
    navigate(BASE_DIR)
    
if __name__ == "__main__":
    app()

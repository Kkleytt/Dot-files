#!/usr/bin/env python3
import os
import json
import sys
from time import sleep
from pathlib import Path

import system_utils as utils

# Пути
home = Path.home()
animations_dir = home / ".config" / "hypr" / "animations"
user_configs = home / ".config" / "hypr" / "UserConfigs"

def send_notify(body: str = "", icon: str = "danger", sound: str = "error-2"):
    fifo_path = Path.home() / ".cache" / "caelestia" / "osd.fifo"

    payload = {
        "group": "rofi-animations",
        "title": "Change Animation",
        "body": body,
        "icon": icon,
        "timeout": 2500,
        "sound": sound,
        "urgency": "normal"
    }

    try:
        fd = os.open(fifo_path, os.O_WRONLY | os.O_NONBLOCK)
        with os.fdopen(fd, "w") as fifo:
            fifo.write(json.dumps(payload) + "\n")
    except BlockingIOError:
        print("Нет активного читателя FIFO — уведомление не отправлено.")
    except Exception as e:
        print(f"Ошибка отправки уведомления: {e}")

def get_animations_list():
    files = sorted(animations_dir.glob("*.conf"), key=lambda p: p.name.lower())
    return [f.stem for f in files]

def apply_animation(chosen: str):
    full_path = animations_dir / f"{chosen}.conf"
    target_path = user_configs / "UserAnimations.conf"
    if full_path.exists():
        target_path.write_text(full_path.read_text(encoding="utf-8"), encoding="utf-8")
        send_notify(
            body=chosen,
            icon="animation",
            sound="toggle"
        )

def app():
    animations = get_animations_list()
    if not animations:
        banner = utils.show_update_banner(text="Нет доступных анимаций", width=30)
        try:
            sleep(5)
        finally:
            utils.close_banner(banner)
            sys.exit(0)

    choice, code = utils.run_rofi(
        payload=animations, 
        theme="animations",
        bytes=False
    )
    
    match code:
        case 0:
            apply_animation(choice)
        case 1:
            sys.exit(0)
        case _:
            sys.exit(0)
        

if __name__ == "__main__":
    app()

import json
import os
import time
from pathlib import Path

import system_utils as utils

# Пути для работы с генерациями
FAVORITE_FILE: Path = Path(__file__).resolve().parent / "nixos_favorite.json"
FIFO_PATH: Path = Path.home() / ".cache" / "caelestia" / "osd.fifo"

# Отправка уведомления
def send_notify(body: str = "", icon: str = "danger", sound: str = "error-2", timeout: int = 2500):
    """Отправка уведомления в FIFO (как в псевдокоде)."""
    payload = {
        "group": "nixos",
        "title": "NixOS",
        "body": body,
        "icon": icon,
        "timeout": timeout,
        "sound": sound,
        "urgency": "normal"
    }
    try:
        fd = os.open(FIFO_PATH, os.O_WRONLY | os.O_NONBLOCK)
        with os.fdopen(fd, "w") as fifo:
            fifo.write(json.dumps(payload) + "\n")
    except BlockingIOError:
        print("Нет активного читателя FIFO — уведомление не отправлено.")
    except Exception as e:
        print(f"Ошибка отправки уведомления: {e}")

# Проверка статус кода Rofi
def check_rofi_code(code: int) -> None:
    match code:
        case 0:
            return
        case 1:
            exit(0)
        case _:
            print("Error Rofi keybinds")
            exit(0)
            
def load_variable(name: str|None = None, type: str = "bool") -> str|None:
    # Логика получения значения переменной из файла json
    file: Path = Path.home() / ".config" / "caelestia" / "theme" / "current" / "hyprland_vars.json"
    
def edit_variable(name: str, type: str, value: str) -> None:
    # Логика изменения значения переменной + отправку нового значения через
    # hyprland dispatch
    pass
    
def timer(status_peripherals: dict, timer: int = 10, sleep: int = 5):
    keyboard = status_peripherals.get("keyboard", False)
    mouse = status_peripherals.get("mouse", False)
    touchpad = status_peripherals.get("touchpad", False)
    touchscreen = status_peripherals.get("touchscreen", False)
    wifi = status_peripherals.get("wifi", False)
    bluetooth = status_peripherals.get("bluetooth", False)
    
    for sec in range(5):
        banner = utils.show_update_banner(
            text=f"У вас есть {sleep - sec} секунд чтобы отменить запуск. {sleep-sec} ",
            width=50
        )
        print(banner.returncode)
        check_rofi_code(banner.returncode)
        time.sleep(0.9)
        utils.close_banner(banner)
        time.sleep(0.1)
        

def keyboard(method: str = "toggle", time: int = 0) -> None:
    match method:
        case "toggle":
            status: str|None = load_variable(name="keyboard_enabled", type="bool")
            if status == "true":
                edit_variable(name="keyboard_enabled", type="bool", value="false")
            elif status == "false":
                edit_variable(name="keyboard_enabled", type="bool", value="true")
        case "enable":
            edit_variable(name="keyboard_enabled", type="bool", value="true")
        case "disable":
            edit_variable(name="keyboard_enabled", type="bool", value="false")
        case "timer":
            pass
        case "layout":
            pass
        case "brightness":
            pass
        case _:
            pass
            
def bluetooth(method: str) -> None:
    match method:
        case "Toggle":
            pass
        case "On":
            pass
        case "Off":
            pass
        case _:
            pass
    

def app(selected: str|None = None) -> None:
    if not selected: 
        peripherals = ["Keyboard", "Mouse", "Touchpad", "Touchscreen", "Wi-Fi", "Bluetooth", "Все сразу"]
        peripheral, code = utils.run_rofi(payload=peripherals, bytes=False, theme="")
        check_rofi_code(code)
    else:
        peripheral = selected
    
    if peripheral == "Все сразу":
        times = ["10", "30", "60", "120", "300"]
        time, code = utils.run_rofi(payload=times, bytes=False, theme="")
        check_rofi_code(code)
    elif peripheral == "Wi-Fi":
        methods = ["Toggle", "On", "Off"]
        time, code = utils.run_rofi(payload=methods, bytes=False, theme="")
    elif peripheral == "Bluetooth":
        methods = ["Toggle", "On", "Off"]
        time, code = utils.run_rofi(payload=methods, bytes=False, theme="")


def start():
    timer({})
    
    
if __name__ == "__main__":
    timer({})
    # app()
            
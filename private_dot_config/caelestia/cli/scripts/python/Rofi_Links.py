import json
import os
import subprocess
import sys
from pathlib import Path

import system_utils as utils

# Путь к JSON с ссылками
FIFO_PATH: Path = Path.home() / ".cache" / "caelestia" / "osd.fifo"
LINKS = Path.home() / ".config" / "caelestia" / "store" / "url_links.json"

# Отправка уведомления
def send_notify(body: str = "", icon: str = "danger", sound: str = "error-2"):
    payload = {
        "group": "links",
        "title": "Links",
        "body": body,
        "icon": icon,
        "timeout": 2500,
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

# Загрузка всех ссылок
def load_links(path: Path):
    if not path.exists():
        print(f"Config not found: {path}", file=sys.stderr)
        sys.exit(2)
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, dict):
        raise SystemExit("Invalid config format: expected top-level object")
    return data

# Главное приложение
def app():
    all_links = load_links(LINKS)

    # Список категорий (красивый порядок: сортируем по ключам)
    categories = sorted(all_links.keys())

    # Выбор категории
    choice_category, code = utils.run_rofi(payload=categories, bytes=False, theme="links-menu")
    check_rofi_code(code)
    
    # Выбор ссылки для открытия
    links: dict = all_links.get(choice_category, {})
    visual_links: list[str] = [" Назад"] + list(links.keys()) 
    url_choice, code = utils.run_rofi(payload=visual_links, bytes=False, theme="links")
    check_rofi_code(code)
    
    if url_choice == " Назад":
        app()
    
    url = links.get(url_choice)
    if not url:
        exit(1)

    # Открываем URL
    subprocess.Popen(["xdg-open", url])
    send_notify(f"Открыта ссылка - {url_choice}", "browser", "pop")
    exit(0)

if __name__ == "__main__":
    app()

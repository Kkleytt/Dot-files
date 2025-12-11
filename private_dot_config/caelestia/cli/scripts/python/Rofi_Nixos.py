import json
import os
import re
import subprocess
from pathlib import Path
from re import Pattern
from typing import Any

# Пути для работы с генерациями
FAVORITE_FILE: Path = Path(__file__).resolve().parent / "nixos_favorite.json"
FIFO_PATH: Path = Path.home() / ".cache" / "caelestia" / "osd.fifo"
ROFI_CONFIG: Path = Path.home() / ".config" / "rofi" / "configs" / "nixos.rasi"

# Отправка уведомления
def send_notify(body: str = "", icon: str = "danger", sound: str = "error-2"):
    """Отправка уведомления в FIFO (как в псевдокоде)."""
    payload = {
        "group": "nixos",
        "title": "NixOS",
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

# Получение списка строк генераций
def get_list() -> list[str]:
    GEN_RE: Pattern[str] = re.compile(r"^\s*(?P<num>\d+)\s+(?P<date>\d{4}-\d{2}-\d{2})\s+(?P<time>\d{2}:\d{2}:\d{2})\s+(?P<system>[\S]+)\s+(?P<kernel>[\S]+).*?(?P<current>\(current\))?\s*$")
    
    # Получение вывода `nixos-rebuild list-generations`
    try:
        out: str = subprocess.run(["nixos-rebuild", "list-generations"], capture_output=True, check=False, text=True).stdout or ""
    except Exception:
        return []
        
    gens: list[Any] = []
    
    for line in out.splitlines():
        m = GEN_RE.match(line)
        if m:
            d = m.groupdict()
            
            num = int(d["num"])
            date = d["date"]
            time = d["time"]
            current = "(cur)" if bool(d.get("current")) else ""
            
            gens.append(f"{current} {num} {date} {time}")
        else:
            # Попытка более гибкого парсинга: взять первые 5 "слов" и искать "(current)"
            parts = line.split()
            if not parts:
                continue
            try:                
                num = int(parts[0])
                date = parts[1] if len(parts) > 1 else ""
                time = parts[2] if len(parts) > 2 else ""
                current = "(cur)" if "True" in line else ""
                
                gens.append(f"{current} {num} {date} {time}")
            except Exception:
                continue
    # Сортируем по номеру по убыванию (новые сверху)
    return gens

# Запуск Rofi
def run_rofi(strings: list[str]) -> tuple[int, str | None]:
    cmd = [
        "rofi", "-dmenu",
        "-i", 
        "-matching", "normal",
        "-config", ROFI_CONFIG
    ]
    # rofi возвращает 0 при выборе, 1 при отмене, 10.. при custom keybindings (если настроены).
    try:
        proc = subprocess.run(cmd, input="\n".join(strings), text=True, capture_output=True)
        code = proc.returncode
        selection = proc.stdout.strip() if proc.stdout else None
        return (code, selection)
    except Exception as e:
        send_notify("NixOS", f"Ошибка запуска rofi: {e}", "danger")
        return (1, None)

# Проверка статус кода Rofi
def check_rofi_code(code: int) -> None:
    match code:
        case 0:
            return
        case 1:
            exit(0)
        case 10:
            delete_generation(0)
        case 11:
            new_generation()
        case 12:
            back_to_generation(0)
        case 13:
            delete_all_generations()  
        case 14:
            delete_trash()
        case _:
            print("Error Rofi keybinds")
            exit(0)
            
def notifcations() -> None:
    send_notify("Вставьте команду в терминал", "clipboard", "pop")
    exit(0)
    
# Удаление генерации по ее коду
def delete_generation(code: int) -> None:
    subprocess.run(["wl-copy", f"sudo nix-env -p /nix/var/nix/profiles/system --delete-generations {str(code)}"])
    notifcations()

# Возвращение к генерации по ее коду
def back_to_generation(code: int) -> None:
    subprocess.run(["wl-copy", f"sudo nix-env --profile /nix/var/nix/profiles/system --switch-generation {str(code)}"])
    notifcations()

# Создание новой генерации
def new_generation() -> None:
    subprocess.run(["wl-copy", "cd /home/kkleytt/.config/nixos && nixos-rebuild switch --flake .#mobile"])
    notifcations()
    
def delete_all_generations() -> None:
    subprocess.run(["wl-copy", "sudo nix-env --delete-generations old"])
    notifcations()
    
def delete_trash() -> None:
    subprocess.run(["wl-copy", "nix-collect-garbage"])
    notifcations()


# Главное приложение
def app() -> None:
    # Выбор генерации
    lines: list[str] = get_list()
    code, selection_generation = run_rofi(lines)
    check_rofi_code(code)
    
    # Выбор метода
    code, selection = run_rofi(["Удалить", "Откатиться", "Создать", "Очистить мусор", "Назад"])
    check_rofi_code(code)
    
    # Определение метода
    if selection == "Удалить":
        delete_generation(int(str(selection_generation).split(" ")[0]))
    elif selection == "Откатиться":
        back_to_generation(int(str(selection_generation).split(" ")[0]))
    elif selection == "Создать":
        new_generation()
    elif selection == "Очистить мусор":
        delete_trash()
    elif selection == "Назад":
        app()
    else:
        exit(0)
    
if __name__ == "__main__":
    app()

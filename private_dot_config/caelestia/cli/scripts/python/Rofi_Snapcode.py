#!/usr/bin/env python3
import json
import os
import re
import subprocess
from datetime import datetime
from pathlib import Path
from re import Match, Pattern
from typing import Any

import system_utils as utils

ROFI_CONFIG: Path = Path.home() / ".config" / "rofi" / "configs" / "snapcode.rasi"
IMAGE_DIR: Path = Path.home() / "Pictures" / "Snapcode"

# Словарь доступных языков для оформления
LANGUAGE_MAP: dict[str, str] = {
    " Python": "py python snake green",
    " JavaScript": "js javascript node web",
    " Rust": "rs rust cargo system",
    " C++": "cpp c++ cpp code",
    " CSharp": "c# csharp dotnet",
    " Nix": "nix nixos config",
    " Bash": "sh bash shell script",
    " Java": "java apps code",
    " Zig": "zig back code",
    " Docker": "dockerfile container",
    " SQL": "sql database base",
    " INI": "ini config cfg settings",
    "󰘦 Json": "json config cfg settings data",
    " YAML": "yaml",
    " TOML": "toml",
    " Markdown": "md markdown docs",
    " Text": "textile text default",
}

# Стили для применения к языкам
LANGUAGE_BACKGROUND: dict[str, Any] = {
    "py":           {"title": "Python", "theme": "1337", "bg": "#B3DAFF", "font": "JetBrainsMono Nerd Font=12", "radius": 5, "tab": 4},
    "js":           "#EBDE8A",
    "rs":           "#D97664",
    "cpp":          "#7EBBE6",
    "c#":           "#CEBBED",
    "nix":          "#A0C7E8",
    "sh":           "#8ABF65",
    "java":         "#D2925B",
    "zig":          "#E6B560",
    "dockerfile":   "#63D7F8",
    "sql":          "#E6CFA3",
    "ini":          "#F2BFE0",
    "json":         "#F2BFE0",
    "yaml":         "#F2BFE0",
    "toml":         "#F2BFE0",
    "md":           "#E0F2BF",
    "text":         "#E0F2BF"
}

# Отправка уведомления
def send_notify(title: str = "Snapcode", body: str = "", icon: str = "danger", sound: str = "error-2"):
    fifo_path = Path.home() / ".cache" / "caelestia" / "osd.fifo"

    payload = {
        "group": "snapcode",
        "title": title,
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

# Генерация имени файла
def generate_name(language: str = "Snapcode") -> str:
    return f"{datetime.now().strftime("%Y-%m-%d %H-%M-%S")}.{language}.png"

# Парсинг списка буфера обмена
def parse_cliphist_list() -> tuple[list[str], list[str], list[str]]:
    RE_FOUR_SPACES: Pattern[str] = re.compile(r"^(\d+)\s{4}(.*)$")
    RE_TAB: Pattern[str] = re.compile(r"^(\d+)\t(.*)$")
    
    
    result: subprocess.CompletedProcess[bytes] = subprocess.run(["cliphist", "list"], stdout=subprocess.PIPE, check=True)
    ids: list[str] = []
    previews: list[str] = []
    original_lines: list[str] = []

    for raw_line in result.stdout.decode(encoding="utf-8", errors="replace").splitlines():
        if not raw_line.strip():
            continue

        m: Match[str] | None = RE_FOUR_SPACES.match(raw_line)
        if not m:
            m = RE_TAB.match(raw_line)

        if m:
            cid, content = m.group(1), m.group(2)
        else:
            cid, content = "", raw_line

        preview: str = content
        preview = re.sub(r"\s{2,}", " ", preview).strip()

        ids.append(cid)
        previews.append(preview)
        original_lines.append(raw_line)

    return ids, previews, original_lines

# Получение определенной записи буфера обмена
def decode_original_to_bytes(original_line: str) -> bytes:
    proc: subprocess.CompletedProcess[bytes] = subprocess.run(
        ["cliphist", "decode"],
        input=(original_line + "\n").encode(encoding="utf-8"),
        stdout=subprocess.PIPE,
        check=True,
    )
    return proc.stdout

# Выбор записи из буфера обмена
def select_clipboard() -> str:
    # Парсинг буфера обмена
    ids, previews, original_lines = parse_cliphist_list()
    
    # Выбор нужной записи
    selected_str, code = utils.run_rofi(
        payload=previews,
        bytes=False,
        theme="clipboard"
    )
    index: int = previews.index(selected_str)
    data: bytes = decode_original_to_bytes(original_line=original_lines[index])
    return data.decode(encoding="utf-8")

# Выбор последний записи из буфера обмена
def get_last_clipboard() -> str:
    # Парсинг буфера обмена
    ids, previews, original_lines = parse_cliphist_list()

    # Парсинг последней записи 
    data: bytes = decode_original_to_bytes(original_line=original_lines[0])
    return data.decode(encoding="utf-8")

# Выбор языка
def language_select() -> tuple[str, int]:
    def build_language_lines() -> list[bytes]:
        def line(visible: str, tags: str) -> bytes:
            meta: str = f"meta\x1f{tags}"
            return visible.encode(encoding="utf-8") + b"\0" + meta.encode(encoding="utf-8")
    
        return [line(visible, tags) for visible, tags in LANGUAGE_MAP.items()]
    
    # Формирование скрытых символов
    language_lines: list[bytes] = build_language_lines()
    language_bytes: bytes = b"\n".join(language_lines)
    
    # Выбор языка
    return utils.run_rofi(payload=language_bytes, theme="snapcode")

# Создание снимка кода
def take_snapcode(text: str, language: str, save: bool = False, notify: bool = True) -> None:
    # Avaliable themes: 1337; Visual Studio Dark+; gruvbox-dark; Coldark-Dark; Coldark-Cold
    
    # Генерация дополнительных аргументов сохранения
    args: list[str] = ["--output", f"{IMAGE_DIR}/{generate_name()}"] if save else []
    
    # Генерация формата языка для применения цветовой палитры
    lang: str = LANGUAGE_MAP.get(language, "textile").split(sep=" ")[0]
    
    # Получение темы оформления для языка
    theme: dict[str, Any] = LANGUAGE_BACKGROUND.get(lang, {})
    
    # Запуск команды
    cmd: list[str] = [
        "silicon", 
        "--to-clipboard", 
        "--language", lang, 
        "--background", theme.get("bg", "#ffffff"), 
        "--theme", theme.get("theme", "1337"),
        "--font", theme.get("font", "JetBrainsMono Nerd Font"),
        "--tab-width", str(theme.get("tab", 4)),
        "--window-title", theme.get("title", "SnapCode")
    ]
    cmd += args
    
    print(cmd)
    
    subprocess.run(
        cmd,
        input=text.encode(encoding="utf-8"),
        check=True,
    )
    
    # Отправка уведомления
    if notify:
        send_notify(
            title="SnapCode", 
            body=f"Скриншот кода ({theme.get('title', 'SnapCode')})", 
            icon="screenshot_code", 
            sound="pop"
        )

# Основной цикл
def app() -> None:
    # Выбор метода (буфера, последний, выделенный)
    method, code = utils.run_rofi(payload=["Выбрать из буфера", "Последний скопированный"], bytes=False, theme="snapcode-menu")
    check_rofi_code(code)
    match method:
        case "Выбрать из буфера":
            text = select_clipboard()
        case "Последний скопированный":
            text = get_last_clipboard()
        case _:
            text = select_clipboard()
    
    # Выбор языка 
    language, code = language_select()
    check_rofi_code(code)
    
    # Выбор сохранять или нет
    save, code = utils.run_rofi(payload=["Сохранить", "Только в буфер"], bytes=False, theme="snapcode-menu")
    check_rofi_code(code)
    save_status: bool = True if save == "Сохранить" else False
    
    # Запускаем команду
    take_snapcode(
        text=text,
        language=language,
        save=save_status
    )
    
    print(f"Text - {text}", f"Language - {language}", f"Save - {save_status}")
    
    
def generate_pattern():
    text = """# Выбор языка
    def language_select() -> str:
        def build_language_lines() -> list[bytes]:
            def line(visible: str, tags: str) -> bytes:
                meta: str = f"meta\x1f{tags}"
                return visible.encode(encoding="utf-8") + b"\0" + meta.encode(encoding="utf-8")
    
            return [line(visible, tags) for visible, tags in LANGUAGE_MAP.items()]
    
        # Формирование скрытых символов
        language_lines: list[bytes] = build_language_lines()
        language_bytes: bytes = b"\n".join(language_lines)
    
        # Выбор языка
        select_language, code = utils.run_rofi(payload=language_bytes, theme="snapcode")
        return select_language"""
        
    themes = [
        "1337",
        "Coldark-Cold",
        "Coldark-Dark",
        "DarkNeon",
        "Dracula",
        "GitHub",
        "Monokai Extended",
        "Monokai Extended Bright",
        "Monokai Extended Light",
        "Monokai Extended Origin",
        "Nord",
        "OneHalfDark",
        "OneHalfLight",
        "Solarized (dark)",
        "Solarized (light)",
        "Sublime Snazzy",
        "TwoDark",
        "Visual Studio Dark+",
        "gruvbox-dark",
        "gruvbox-light",
        "zenburn"
    ]
        
    fonts = [
        "CaskaydiaCove Nerd Font",
        "FiraCode Nerd Font",
        "JetBrainsMono Nerd Font",
        "DejaVu Sans Mono",
    ]
    
    for theme in themes:
        # Запуск команды
        save_path: Path = IMAGE_DIR / "JetBrainsMono Nerd Font" / f"{theme}.png"
        save_path.parent.mkdir(parents=True, exist_ok=True)
        
        cmd: list[str] = [
            "silicon", 
            "--language", "py", 
            "--background", "#B3DAFF", 
            "--theme", theme,
            "--font", "JetBrainsMono Nerd Font",
            "--tab-width", "4",
            "--window-title", f"{theme} / JetBrainsMono Nerd Font",
            "--output", str(save_path)
        ]
        
        try:
            print(f"❌❌❌❌ Theme: {theme}; Font: JetBrainsMono Nerd Font")
            subprocess.run(
                cmd,
                input=text.encode(encoding="utf-8"),
                capture_output=False,
                check=True,
            )
        except Exception as ex:
            print(f"Error {theme} / JetBrainsMono Nerd Font - {ex}")
    

if __name__ == "__main__":
    generate_pattern()

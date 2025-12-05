#!/usr/bin/env python3
import json
import os
import subprocess
from pathlib import Path
from time import sleep
from typing import Any

ROFI_CONFIG: Path = Path.home() / ".config" / "rofi" / "configs" / "snapcode.rasi"

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

LANGUAGE_BACKGROUND: dict[str, str] = {
    "py":           "#B3DAFF",
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

def send_notify(title: str = "SnapCode", body: str = "", icon: str = "danger", sound: str = "error-2") -> None:
    fifo_path: Path = Path.home() / ".cache" / "caelestia" / "osd.fifo"

    payload: dict[str, Any] = {
        "group": "snapcode",
        "title": title,
        "body": body,
        "icon": icon,
        "timeout": 2500,
        "sound": sound,
        "urgency": "normal"
    }

    try:
        fd: int = os.open(path=fifo_path,flags= os.O_WRONLY | os.O_NONBLOCK)
        with os.fdopen(fd, "w") as fifo:
            fifo.write(json.dumps(obj=payload) + "\n")
    except BlockingIOError:
        print("Нет активного читателя FIFO — уведомление не отправлено.")
    except Exception as e:
        print(f"Ошибка отправки уведомления: {e}")


def build_language_lines() -> list[bytes]:
    def line(visible: str, tags: str) -> bytes:
        meta: str = f"meta\x1f{tags}"
        return visible.encode(encoding="utf-8") + b"\0" + meta.encode(encoding="utf-8")

    return [line(visible, tags) for visible, tags in LANGUAGE_MAP.items()]
    
def run_rofi(payload: bytes, prompt: str) -> bytes:
    proc: subprocess.CompletedProcess[bytes] = subprocess.run(
        [
            "rofi", "-dmenu", 
            "-matching", "fuzzy", 
            "-p", prompt,
            "-config", ROFI_CONFIG
        ],
        input=payload,
        stdout=subprocess.PIPE,
        check=False,
    )
    return proc.stdout
    
def get_text() -> str:
    def get_primary_selection() -> str:
        p: subprocess.CompletedProcess[bytes] = subprocess.run(["wl-paste", "--primary"], stdout=subprocess.PIPE, check=False)
        return p.stdout.decode(encoding="utf-8")
    
    def get_last_copied() -> str:
        p: subprocess.CompletedProcess[bytes] = subprocess.run(["wl-paste"], stdout=subprocess.PIPE, check=False)
        return p.stdout.decode(encoding="utf-8")
        
    def copy_selection():
        subprocess.run(["wl-copy"], check=False)
        
    # Пытаемся получить выделенный текст
    # text = get_primary_selection()
    # print(f"Stady 1: {text}")
    copy_selection()
    sleep(0.2)
    
    # Пытаемся получить последнюю запись из буфера
    text = get_last_copied()
    print(f"Stady 2: {text}")
    send_notify(title="Test", body=f"{text}", icon="danger", sound="error-2")
    
    # Отдаем данные
    if not text:
        return text
    else:
        send_notify(title="SnapCode", body="Нет данных для обработки", icon="warning", sound="error-2")
        exit(code=1)
    
def app() -> None:
    text: str = get_text()
    
    lines: list[bytes] = build_language_lines()
    payload: bytes = b"\n".join(lines)

    choice: str = run_rofi(payload=payload, prompt="Выбери язык:").decode(encoding="utf-8").strip()
    language_name: str = choice[2::1] or "Text"
    language: str = LANGUAGE_MAP.get(choice, "textile").split(sep=" ")[0]
    bg_color: str = LANGUAGE_BACKGROUND.get(language, "#ffffff")

    subprocess.run(
        [
            "silicon", "-c", "-l", language, 
            "-b", bg_color, "--theme", "1337", # List: ["1337", "Visual Studio Dark+", "gruvbox-dark", "Coldark-Dark", "Coldark-Cold"]
            "--window-title", language_name
        ],
        input=text.encode(encoding="utf-8"),
        check=True,
    )

    send_notify(title="SnapCode", body=f"Скриншот кода ({language_name})", icon="screenshot_code", sound="pop-2")

if __name__ == "__main__":
    app()

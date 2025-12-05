import subprocess
from pathlib import Path
import sys

import system_utils as utils

SCRIPT_DIR = Path(__file__).resolve().parent
KEYHINTS_DIR = SCRIPT_DIR / "keyhints"

if not KEYHINTS_DIR.exists():
    print(f"Ошибка: {KEYHINTS_DIR} не найдена!", file=sys.stderr)
    sys.exit(1)

def write_cache(filename: str, content: bytes):
    cache_dir = KEYHINTS_DIR / "cache"
    cache_dir.mkdir(parents=True, exist_ok=True)
    file_path = cache_dir / f"{filename}.cache"
    try:
        file_path.write_bytes(content)
    except Exception as e:
        print(f"Ошибка записи кэша: {e}")
    
def read_cache(filename: str) -> bytes | None:
    file_path = KEYHINTS_DIR / "cache" / f"{filename}.cache"
    if file_path.exists():
        return file_path.read_bytes()
    return None

def has_cache(filename: str) -> bool:
    file_path = KEYHINTS_DIR / "cache" / f"{filename}.cache"
    return file_path.exists()    

def parse_hint_file(filepath):
    rows = []
    current_desc = ""
    current_keys = []

    def flush_group():
        nonlocal current_desc
        if current_keys and current_desc:
            for key in current_keys:
                formatted = f"{key:<20} │ {current_desc}"
                rows.append((formatted, ""))
        elif current_keys:
            for key in current_keys:
                formatted = f"{key:<20} │"
                rows.append((formatted, ""))
        current_keys.clear()
        current_desc = ""

    with filepath.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip().replace("\r", "")
            if not line:
                flush_group()
                rows.append(("", ""))  # пустая строка для визуального разделения
                continue

            # Заголовок блока
            if line.startswith("#"):
                flush_group()
                title = line.split(";")[0].strip()
                title = title.ljust(30, " ")  # выравнивание заголовка
                rows.append((title, ""))
                continue

            # Комментарий или обозначение
            if line.startswith(";"):
                flush_group()
                label = line.lstrip(";").strip()
                if label:
                    formatted = f"    {'':<30} │ {label}"
                    rows.append((formatted, ""))
                continue

            # Строка с ; → key ; description
            if ";" in line:
                flush_group()
                key, desc = map(str.strip, line.split(";", 1))
                formatted = f"{key:<30} │ {desc}"
                if desc == "":
                    formatted = f"  {key:<28} │ {desc}"
                rows.append((formatted, ""))
                continue

            # Вложенные сочетания (без описания)
            current_keys.append(line)

    flush_group()
    return rows

def choice_theme(use_cache: bool = True):
    if has_cache("themes") and use_cache:
        content = read_cache("themes")
    else:
        theme_files = sorted(KEYHINTS_DIR.glob("*.txt"))
        if not theme_files:
            print(f"Нет файлов *.txt в {KEYHINTS_DIR}", file=sys.stderr)
            sys.exit(1)

        themes = [f.stem for f in theme_files]
        
        content = "\n".join(themes).encode("utf-8")
        write_cache("themes", content)
        
    return utils.run_rofi(
        payload=content,
        theme="keyhints-menu"
    )

def choice_keybinds(filename: str, use_cache: bool = True):
    if has_cache(filename) and use_cache:
        content = read_cache(filename)
    else:
        file_path = KEYHINTS_DIR / f"{filename}.txt"
        if not file_path.exists():
            subprocess.run(["yad", "--text", f"Файл не найден: {file_path}", "--button=OK"])
            sys.exit(1)
        
        rows = parse_hint_file(file_path)
        content = "\n".join(row[0] for row in rows).encode("utf-8")
        write_cache(filename, content)
        
    utils.run_rofi(
        payload=content,
        theme="keyhints"
    )

def app(use_cache: bool = True):
    while True:        
        theme, code = choice_theme(use_cache=use_cache)
        
        match code:
            # Esc / Cancel
            case 1:
                sys.exit(0)
            
            # Enter
            case 0:
                pass
            
            # Ctrl + U
            case 10:   
                print("Dont use cache") 
                use_cache = False
                continue
            
            # Error
            case _:
                sys.exit(0)
                
        choice_keybinds(theme, use_cache=use_cache)

        sys.exit(0)

if __name__ == "__main__":
    app()

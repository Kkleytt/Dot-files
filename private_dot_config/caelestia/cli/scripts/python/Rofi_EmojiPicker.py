#!/usr/bin/env python3

import httpx
import subprocess
from pathlib import Path
import zipfile
import io
import sys
from fontTools.ttLib import TTFont
import system_utils as utils

CACHE_FILE = Path.home() / ".cache/emoji_rofi.txt"
ICONS_CACHE = Path.home() / ".cache/icons_rofi.txt"
CLDR_URLS = {
    "ru": "https://raw.githubusercontent.com/unicode-org/cldr-json/main/cldr-json/cldr-annotations-full/annotations/ru/annotations.json",
    "en": "https://raw.githubusercontent.com/unicode-org/cldr-json/main/cldr-json/cldr-annotations-full/annotations/en/annotations.json",
}
NERD_URL = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"


def get_nerd_icons(url=NERD_URL):
    r = httpx.get(url, follow_redirects=True, timeout=30)
    r.raise_for_status()
    z = zipfile.ZipFile(io.BytesIO(r.content))

    # выбираем моно TTF (если есть), иначе первый .ttf
    ttf_files = [f for f in z.namelist() if f.endswith(".ttf")]
    if not ttf_files:
        raise RuntimeError("TTF не найден в архиве Nerd Fonts")
    with z.open(ttf_files[0]) as f:
        font = TTFont(f)

    cmap = font["cmap"].getBestCmap()  # type: ignore
    lines = []

    for codepoint, glyph_name in cmap.items():
        # оставляем только PUA (иконки Nerd Fonts)
        if not (0xE000 <= codepoint <= 0xF8FF or 0xF0000 <= codepoint <= 0xFFFFD):
            continue

        char = chr(codepoint)
        # видимое: символ + краткое имя
        visible = f"{char} {glyph_name}"
        # ключевые слова для поиска
        keywords = glyph_name.replace("_", " ").replace("-", " ")
        meta = f"meta\x1f{glyph_name} {keywords}"

        # байтовая строка с NUL и meta-парой
        line = visible.encode("utf-8") + b"\0" + meta.encode("utf-8")
        lines.append(line)

    return lines

def get_cldr_emoji():
    
    cldr_data = {}
    for lang, url in CLDR_URLS.items():
        r = httpx.get(url)
        r.raise_for_status()
        j = r.json()
        cldr_data[lang] = j["annotations"]["annotations"]

    lines = []
    
    for emoji, value in cldr_data["en"].items():
        if not emoji:
            continue
        # видимая часть: эмодзи + русское название
        # ru_label = (cldr_data["ru"].get(emoji, {}).get("tts") or ["Без названия"])[0]
        visible = f"{emoji} {value.get("tts")[0] or "Unknown"}"

        # meta: только английские ключи
        meta = f"meta\x1f{cldr_data["ru"].get(emoji, "").get("tts", "")[0]}"

        line = visible.encode("utf-8") + b"\0" + meta.encode("utf-8")
        lines.append(line)
    return lines
    
def update_data():
    system_lines = []
    emoji_lines = get_cldr_emoji()
    icon_lines = get_nerd_icons()
    system_lines.append("==Update set==".encode("utf-8"))
    all_lines = emoji_lines + icon_lines + system_lines
    CACHE_FILE.write_bytes(b"\n".join(all_lines))
    print(f"Create cache for {len(all_lines)} symbols")

def app():
    # гарантируем наличие кэша
    if not CACHE_FILE.exists():
        update_data()

    while True:
        choice, code = utils.run_rofi(
            payload=CACHE_FILE.read_bytes(), 
            theme="emoji"
        )
        
        match code:
            
            # Esc / Cancel
            case 1:
                sys.exit(0)
            
            # Enter
            case 0:
                picked = choice.split()[0]
                subprocess.run(["wl-copy"], input=picked.encode("utf-8"), check=True)  
                print(f"Copy - {picked}")
                sys.exit(0)  
            
            # Ctrl + U
            case 10:    
                banner = utils.show_update_banner(
                    text="Update emoji set. Please wait, this may take a monent"
                )
                try:
                    update_data()
                finally:
                    utils.close_banner(banner)
                continue
            
            # Error
            case _:
                sys.exit(0)
                

if __name__ == "__main__":
    app()

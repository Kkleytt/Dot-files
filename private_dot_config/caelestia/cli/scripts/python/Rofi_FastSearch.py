#!/usr/bin/env python3
import subprocess
import urllib.parse
import sys

import system_utils as utils

def app():
    query, code = utils.run_rofi(
        payload=[],
        theme="search"
    )
    if not query:
        return

    # кодируем запрос для URL
    encoded_query = urllib.parse.quote_plus(query)

    # формируем URL (Google по умолчанию)
    url = f"https://www.google.com/search?q={encoded_query}"

    # открываем в браузере
    try:
        subprocess.run(["xdg-open", url], check=True)
    finally:
        sys.exit(0)

if __name__ == "__main__":
    app()

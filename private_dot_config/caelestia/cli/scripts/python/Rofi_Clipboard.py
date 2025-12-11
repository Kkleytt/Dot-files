import re
import subprocess
import sys
import time

import system_utils as utils  # your helper module

# Preview settings
SHOW_NEWLINE = "↵"
SHOW_TAB = "⇥"

RE_FOUR_SPACES = re.compile(r"^(\d+)\s{4}(.*)$")
RE_TAB = re.compile(r"^(\d+)\t(.*)$")


def parse_cliphist_list() -> tuple[list[str], list[str], list[str]]:
    result = subprocess.run(["cliphist", "list"], stdout=subprocess.PIPE, check=True)
    ids: list[str] = []
    previews: list[str] = []
    original_lines: list[str] = []

    for raw_line in result.stdout.decode("utf-8", errors="replace").splitlines():
        if not raw_line.strip():
            continue

        m = RE_FOUR_SPACES.match(raw_line)
        if not m:
            m = RE_TAB.match(raw_line)

        if m:
            cid, content = m.group(1), m.group(2)
        else:
            cid, content = "", raw_line

        preview = content
        preview = re.sub(r"\s{2,}", " ", preview).strip()

        ids.append(cid)
        previews.append(preview)
        original_lines.append(raw_line)

    return ids, previews, original_lines


def decode_original_to_bytes(original_line: str) -> bytes:
    proc = subprocess.run(
        ["cliphist", "decode"],
        input=(original_line + "\n").encode("utf-8"),
        stdout=subprocess.PIPE,
        check=True,
    )
    return proc.stdout


def app():
    print("Хуй")
    while True:
        ids, previews, original_lines = parse_cliphist_list()
        if not previews:
            banner = utils.show_update_banner(
                text="Буфер обмена пуст. Сначала что-то скопируйте, чтобы начать пользоваться буфером.",
                width=50
            )
            try:
                time.sleep(3)
            finally:
                utils.close_banner(banner)
                sys.exit(0)
        
        selected_str, code = utils.run_rofi(
            payload=previews,
            theme="clipboard",
            bytes=False,
        )

        match code:
            case 1:  # Esc / Cancel
                sys.exit(0)

            case 0:  # Enter
                if "\t" in selected_str:
                    idx_str, _ = selected_str.split("\t", 1)
                    try:
                        idx = int(idx_str)
                    except ValueError:
                        idx = -1
                else:
                    try:
                        idx = previews.index(selected_str)
                    except ValueError:
                        idx = -1

                if idx < 0 or idx >= len(original_lines):
                    continue

                # Decode exact content and copy
                data = decode_original_to_bytes(original_lines[idx])
                subprocess.run(["wl-copy"], input=data, check=True)
                sys.exit(0)

            case 10:  # Ctrl+Delete / Ctrl+Backspace / Delete
                if "\t" in selected_str:
                    idx_str, _ = selected_str.split("\t", 1)
                    try:
                        idx = int(idx_str)
                    except ValueError:
                        idx = -1
                else:
                    try:
                        idx = previews.index(selected_str)
                    except ValueError:
                        idx = -1

                if 0 <= idx < len(original_lines):
                    subprocess.run(["cliphist", "delete"], input=(original_lines[idx] + "\n").encode("utf-8"), check=False)

            case 11:  # Ctrl+Alt+Delete
                subprocess.run(["cliphist", "wipe"], check=False)

            case _:  # Other codes
                sys.exit(0)


if __name__ == "__main__":
    app()
    

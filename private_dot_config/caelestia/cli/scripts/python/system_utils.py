import subprocess
import textwrap
from pathlib import Path

ROFI_THEMES_DIR = Path.home() / ".config" / "rofi" / "configs"
ROFI_MSG_THEME = ROFI_THEMES_DIR / "banner.rasi"

def show_update_banner(text: str, width: int = 50, min_lines: int = 5) -> subprocess.Popen:
    wrapped_lines = textwrap.wrap(text, width=width)

    while len(wrapped_lines) < min_lines:
        wrapped_lines.append("⠀")

    cmd = ["rofi", "-i", "-dmenu", "-config", str(ROFI_MSG_THEME)]
    proc = subprocess.Popen(
        cmd,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )

    if proc.stdin:
        payload = "\n".join(wrapped_lines)
        proc.stdin.write(payload.encode("utf-8"))
        proc.stdin.flush()

    return proc

def close_banner(proc: subprocess.Popen):
    try:
        proc.terminate()
    except Exception:
        pass


def run_rofi(payload, theme: str = "config", bytes: bool = True):
    
    final_payload = payload if bytes else "\n".join(payload).encode("utf-8")
    proc = subprocess.run(
        [
            "rofi", 
            "-i", 
            "-dmenu", 
            "-matching", 
            "normal",
            "-config", 
            ROFI_THEMES_DIR / f"{theme}.rasi", 
            "-click-to-exit"
        ],
        input=final_payload,
        stdout=subprocess.PIPE
    )
    return proc.stdout.decode("utf-8").strip(), proc.returncode
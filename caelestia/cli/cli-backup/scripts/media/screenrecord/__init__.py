#!/usr/bin/env python3
import subprocess
import typer
from shell_config import SCRIPTS_DIR

app = typer.Typer(help="Запись экрана")

# Путь к вашему bash-скрипту
SCRIPT_PATH = SCRIPTS_DIR / "media" / "screenrecord" / "script.sh"

def run_script(arguments: list[str] = []):    
    try:
        result = subprocess.run(
            [str(SCRIPT_PATH)] + arguments,
            capture_output=True,
            text=True,
            check=True
        )
        if result.stdout.strip():
            typer.echo(result.stdout.strip())
    except subprocess.CalledProcessError as e:
        typer.echo(f"Error running script: {e.stderr}", err=True)

    
@app.command()
def start(area: bool = False, sound: bool = False, pause: bool = False):
    """Запустить запись экрана caelestia"""
    run_script([
        "play", 
        "-r" if area else "", 
        "-s" if sound else "", 
        "-p" if pause else ""
    ])
    
if __name__ == "__main__":
    app()

#!/usr/bin/env python3
import subprocess
import typer
from typing import Literal
from shell_config import SCRIPTS_DIR

app = typer.Typer(help="Управление панелями оболочки Caelestia shell")

# Путь к вашему bash-скрипту
SCRIPT_PATH = SCRIPTS_DIR / "caelestia" / "rofi" / "script.sh"

app_list = "wallpapers", "emoji", "clipboard", "radio", "animation", "search", "keyhints"

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
def run(app_name: Literal[app_list], rofi_dir: str = str(SCRIPTS_DIR / "python")): # type: ignore
    """Запустить/Скрыть приложение Rofi"""
    run_script([app_name, rofi_dir])
    
if __name__ == "__main__":
    app()

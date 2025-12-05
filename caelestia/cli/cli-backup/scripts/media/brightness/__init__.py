#!/usr/bin/env python3
import subprocess
import typer
from shell_config import SCRIPTS_DIR

app = typer.Typer(help="Управление яркостью экрана")

# Путь к вашему bash-скрипту
SCRIPT_PATH = SCRIPTS_DIR / "media" / "brightness" / "script.sh"

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
def get():
    """Получить текущую яркость экрана в процентах (0-100)"""
    run_script(["get"])
    
@app.command()
def set(value: int, notify: bool = True):
    """Установить необходимую яркость экрана (0-100)"""
    run_script(["set", str(value), str(notify).lower()])
    
@app.command()
def up(step: int, notify: bool = True):
    """Поднять яркость экрана на n шагов"""
    run_script(["up", str(step), str(notify).lower()])
    
@app.command()
def down(step: int, notify: bool = True):
    """Понизить яркость экрана на n шагов"""
    run_script(["down", str(step), str(notify).lower()])
    
@app.command()
def cycle(count_step: int, notify: bool = True):
    """Переключить уровни яркости в n ступенях"""
    run_script(["cycle", str(count_step), str(notify).lower()])

if __name__ == "__main__":
    app()

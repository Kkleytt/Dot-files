#!/usr/bin/env python3
import subprocess
import typer
from shell_config import SCRIPTS_DIR

app = typer.Typer(help="Управление динамиками/наушниками")

# Путь к вашему bash-скрипту
SCRIPT_PATH = SCRIPTS_DIR / "media" / "speaker" / "script.sh"

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
    """Получить текущую громкость динамиков/наушников"""
    run_script(["get"])
    
@app.command()
def enable(notify: bool = True):
    """Включить динамики/наушники в состояние Unmuted"""
    run_script(["enable", str(notify).lower()])
    
@app.command()
def disable(notify: bool = True):
    """Выключить динамики/наушники в состояние Muted"""
    run_script(["disable", str(notify).lower()])
    
@app.command()
def toggle(notify: bool = True):
    """Переключить динамики/наушники в состояние Unmuted/Muted"""
    run_script(["toggle", str(notify).lower()])
    
@app.command()
def set(value: int, limit: int = 200, notify: bool = True):
    """Установить необходимую громкость динамиков/наушников"""
    run_script(["set", str(value), str(limit), str(notify).lower()])
    
@app.command()
def up(step: int, limit: int = 200, notify: bool = True):
    """Поднять громкость динамиков/наушников на n шагов"""
    run_script(["up", str(step), str(limit), str(notify).lower()])
    
@app.command()
def down(step: int, limit: int = 200, notify: bool = True):
    """Понизить громкость динамиков/наушников на n шагов"""
    run_script(["down", str(step), str(limit), str(notify).lower()])
    
if __name__ == "__main__":
    app()

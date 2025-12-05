#!/usr/bin/env python3
import subprocess
import typer
from shell_config import SCRIPTS_DIR

app = typer.Typer(help="Управление плеером")

# Путь к вашему bash-скрипту
SCRIPT_PATH = SCRIPTS_DIR / "media" / "player" / "script.sh"

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
def play(notify: bool = True):
    """Прододить воспроизведение"""
    run_script(["play", str(notify).lower()])
    
@app.command()
def pause(notify: bool = True):
    """Постаивть на паузу"""
    run_script(["pause", str(notify).lower()])
    
@app.command()
def toggle(notify: bool = True):
    """Play/Pause переключение"""
    run_script(["toggle", str(notify).lower()])
    
@app.command()
def stop(notify: bool = True):
    """Остановить воспроизведение"""
    run_script(["stop", str(notify).lower()])
    
@app.command()
def next(notify: bool = True):
    """Переключить трек вперед"""
    run_script(["next", str(notify).lower()])
    
@app.command()
def prev(notify: bool = True):
    """Переключить трек назад"""
    run_script(["prev", str(notify).lower()])
    
if __name__ == "__main__":
    app()

#!/usr/bin/env python3
import subprocess
import typer
from shell_config import SCRIPTS_DIR

app = typer.Typer(help="Управление клавиатурой")

# Путь к вашему bash-скрипту
SCRIPT_PATH = SCRIPTS_DIR / "peripherals" / "keyboard" / "script.sh"

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
def get(notify: bool = True):
    """Получить текущий статус клавиатуры"""
    run_script(["get", str(notify).lower()])
    
@app.command()
def enable(notify: bool = True):
    """Включить клавиатуру"""
    run_script(["enable", str(notify).lower()])
    
@app.command()
def disable(notify: bool = True):
    """Выключить клавиатуру"""
    run_script(["disable", str(notify).lower()])
    
@app.command()
def toggle(notify: bool = True):
    """Переключить клавиатуру в состояние Enable/Disable"""
    run_script(["toggle", str(notify).lower()])
    
@app.command()
def layout(method: str = "adaptive", layout: str = "", notify: bool = False):
    """Сменить раскладку клавиатуры"""
    run_script(["layout", method, layout, str(notify).lower()])
    
@app.command()
def backlight(direction: str = "up", notify: bool = True):
    """Переключить яркость клавиатуры"""
    run_script(["backlight", direction, str(notify).lower()])
    
if __name__ == "__main__":
    app()

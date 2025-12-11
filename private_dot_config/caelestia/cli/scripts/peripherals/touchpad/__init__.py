#!/usr/bin/env python3
import subprocess
import typer
from shell_config import SCRIPTS_DIR

app = typer.Typer(help="Управление тачпадом")

# Путь к вашему bash-скрипту
SCRIPT_PATH = SCRIPTS_DIR / "peripherals" / "touchpad" / "script.sh"

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
    """Получить текущий статус тачпада"""
    run_script(["get", str(notify).lower()])
    
@app.command()
def enable(notify: bool = True):
    """Включить тачпад"""
    run_script(["enable", str(notify).lower()])
    
@app.command()
def disable(notify: bool = True):
    """Выключить тачпад"""
    run_script(["disable", str(notify).lower()])
    
@app.command()
def toggle(notify: bool = True):
    """Переключить тачпад в состояние Enable/Disable"""
    run_script(["toggle", str(notify).lower()])

    
if __name__ == "__main__":
    app()

#!/usr/bin/env python3
import subprocess
import typer
from shell_config import SCRIPTS_DIR

app = typer.Typer(help="Управление оболочкой Caelestia shell")

# Путь к вашему bash-скрипту
SCRIPT_PATH = SCRIPTS_DIR / "caelestia" / "shell" / "script.sh"

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
def enable(notify: bool = True):
    """Включить оболочку Caelestia shell"""
    run_script(["enable", str(notify).lower()])
    
@app.command()
def disable(notify: bool = True):
    """Выключить оболочку Caelestia shell"""
    run_script(["disable", str(notify).lower()])
    
@app.command()
def toggle(notify: bool = True):
    """Переключить оболочку Caelestia shell"""
    run_script(["toggle", str(notify).lower()])
    
@app.command()
def restart(notify: bool = True):
    """Перезапустить оболочку Caelestia shell"""
    run_script(["restart", str(notify).lower()])
    
if __name__ == "__main__":
    app()

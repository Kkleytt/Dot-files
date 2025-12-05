#!/usr/bin/env python3
import subprocess
import typer
from shell_config import SCRIPTS_DIR

app = typer.Typer(help="Управление спящим режимом")

# Путь к вашему bash-скрипту
SCRIPT_PATH = SCRIPTS_DIR / "hyprland" / "idle" / "script.sh"

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
def sleep(notify: bool = True):
    """Перевести устройство в спящий режим"""
    run_script(["sleep", str(notify).lower()])
    
@app.command()
def lock(notify: bool = True):
    """Заблокировать устройство"""
    run_script(["lock", str(notify).lower()])
    
@app.command()
def display(status: str = "on", notify: bool = True):
    """Включить или Выключить экран"""
    run_script(["display", status, str(notify).lower()])
    
@app.command()
def notify(status: str = "on", notify: bool = True):
    """Отправить уведомление о статусе устройства"""
    run_script(["notify", status, str(notify).lower()])

    
if __name__ == "__main__":
    app()

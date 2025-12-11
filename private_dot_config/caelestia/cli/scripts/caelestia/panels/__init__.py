#!/usr/bin/env python3
import subprocess
import typer
from typing import Literal
from shell_config import SCRIPTS_DIR

app = typer.Typer(help="Управление панелями оболочки Caelestia shell")

# Путь к вашему bash-скрипту
SCRIPT_PATH = SCRIPTS_DIR / "caelestia" / "panels" / "script.sh"

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
def launcher(notify: bool = True):
    """Отобразить/Скрыть лаунчер приложений"""
    run_script(["launcher", str(notify).lower()])
    
@app.command()
def sidebar(notify: bool = True):
    """Отобразить/Скрыть панель уведомлений"""
    run_script(["sidebar", str(notify).lower()])

@app.command()
def dashboard(notify: bool = True):
    """Отобразить/Скрыть дашборд панель"""
    run_script(["dashboard", str(notify).lower()])
    
@app.command()
def session(notify: bool = True):
    """Отобразить/Скрыть панель управления питанием"""
    run_script(["session", str(notify).lower()])
    
@app.command()
def bar(method: Literal["hide", "show", "toggle_hide", "move", "unmove", "toggle_move"], notify: bool = True):
    """Управление настройками бара"""
    run_script(["bar", str(method), str(notify).lower()])
    
if __name__ == "__main__":
    app()

#!/usr/bin/env python3
import subprocess
import typer
from shell_config import SCRIPTS_DIR

app = typer.Typer(help="Управление внешним видом Hyprland")

# Путь к вашему bash-скрипту
SCRIPT_PATH = SCRIPTS_DIR / "hyprland" / "decorate" / "script.sh"

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
def opacity(notify: bool = True):
    """Изменить прозрачность окна"""
    run_script(["opacity", str(notify).lower()])
    
@app.command()
def blur(notify: bool = True):
    """Изменить размытие заднего фона"""
    run_script(["blur", str(notify).lower()])
    
@app.command()
def layout(notify: bool = True):
    """Переключить раскладку окон на рабочем столе"""
    run_script(["layout", str(notify).lower()])
    
@app.command()
def game_mode(notify: bool = True):
    """Перекдючить игровой режим (Вкл/Выкл)"""
    run_script(["game", str(notify).lower()])

    
if __name__ == "__main__":
    app()

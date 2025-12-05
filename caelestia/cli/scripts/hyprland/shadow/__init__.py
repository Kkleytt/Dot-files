#!/usr/bin/env python3
import subprocess
import typer
from shell_config import SCRIPTS_DIR

app = typer.Typer(help="Управление скрытным режимом")

# Путь к вашему bash-скрипту
SCRIPT_PATH = SCRIPTS_DIR / "hyprland" / "shadow" / "script.sh"

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
def toggle():
    """Переключить режим тени"""
    run_script(["toggle"])
    
@app.command(name="app")
def apps(app_name: str, notify: bool = True):
    """Открыть скрытное приложение"""
    run_script(["app", app_name, str(notify).lower()])
    
@app.command()
def space(number: int = 1, notify: bool = True):
    """Открыть/Закрыть рабочий стол под номером n"""
    run_script(["space", str(number), str(notify).lower()])

    
if __name__ == "__main__":
    app()

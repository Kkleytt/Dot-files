#!/usr/bin/env python3
import subprocess
import typer
from shell_config import SCRIPTS_DIR

app = typer.Typer(help="Запуск системных приложений")

# Путь к вашему bash-скрипту
SCRIPT_PATH = SCRIPTS_DIR / "hyprland" / "hyprapps" / "script.sh"

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
def picker():
    """Запуск пипетку для выбора цвета"""
    run_script(["picker"])
    
if __name__ == "__main__":
    app()

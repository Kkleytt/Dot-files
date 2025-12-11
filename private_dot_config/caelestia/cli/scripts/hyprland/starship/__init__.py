#!/usr/bin/env python3
import subprocess
import typer
from shell_config import SCRIPTS_DIR

app = typer.Typer(help="Управление оболочкой терминала")

# Путь к вашему bash-скрипту
SCRIPT_PATH = SCRIPTS_DIR / "hyprland" / "starship" / "script.sh"


def run_script(arguments: list[str] = []):
    try:
        result = subprocess.run([str(SCRIPT_PATH)] + arguments, capture_output=True, text=True, check=True)
        if result.stdout.strip():
            typer.echo(result.stdout.strip())
    except subprocess.CalledProcessError as e:
        typer.echo(f"Error running script: {e.stderr}", err=True)


@app.command()
def toggle(notify: bool = False):
    """Переключить компактный режим оболочки"""
    run_script(["toggle", str(notify).lower()])


if __name__ == "__main__":
    app()

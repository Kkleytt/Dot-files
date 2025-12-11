#!/usr/bin/env python3
import subprocess
import typer
from shell_config import SCRIPTS_DIR

app = typer.Typer(help="Управление всеми периферийными устройствами")

# Путь к вашему bash-скрипту
SCRIPT_PATH = SCRIPTS_DIR / "peripherals" / "clean" / "script.sh"

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
    """Получить текущий статус всех периферийных устройств"""
    run_script(["get", str(notify).lower()])
    
@app.command()
def enable(notify: bool = True):
    """Включить все периферийные устройства"""
    run_script(["enable", str(notify).lower()])
    
@app.command()
def timer(notify: bool = True):
    """Переключить периферийные устройства в режим очистки по времени"""
    run_script(["timer", str(notify).lower()])

    
if __name__ == "__main__":
    app()

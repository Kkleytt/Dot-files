#!/usr/bin/env python3
import subprocess
import typer
from shell_config import SCRIPTS_DIR

app = typer.Typer(help="Управление блокировкой оболочки Caelestia shell")

# Путь к вашему bash-скрипту
SCRIPT_PATH = SCRIPTS_DIR / "caelestia" / "lock" / "script.sh"

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
def lock(notify: bool = True):
    """Заблокировать система"""
    run_script(["lock", str(notify).lower()])
    
@app.command()
def unlock(notify: bool = True):
    """Разблокировать систему"""
    run_script(["unlock", str(notify).lower()])

@app.command()
def islocked(notify: bool = True):
    """Получить актуальный статус блокировки системы"""
    run_script(["islocked", str(notify).lower()])

    
if __name__ == "__main__":
    app()

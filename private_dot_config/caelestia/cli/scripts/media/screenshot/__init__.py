#!/usr/bin/env python3
import subprocess
import typer
from shell_config import SCRIPTS_DIR

app = typer.Typer(help="Создание и аннотация скриншотов")

# Путь к вашему bash-скрипту
SCRIPT_PATH = SCRIPTS_DIR / "media" / "screenshot" / "script.sh"

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
def screen(
    edited: bool = False,
    copied: bool = True,
    saved: bool = True,
    notify: bool = True,
    
    ):
    """Создать скринщот экрана"""
    run_script([
        "screen",
        "",
        str(edited).lower(),
        str(copied).lower(),
        str(saved).lower(),
        str(notify).lower()
    ])
    
@app.command()
def window(
    edited: bool = False,
    copied: bool = True,
    saved: bool = True,
    notify: bool = True,
    
    ):
    """Создать скриншот окна"""
    run_script([
        "window",
        "",
        str(edited).lower(),
        str(copied).lower(),
        str(saved).lower(),
        str(notify).lower()
    ])
    
@app.command()
def area(
    edited: bool = False,
    copied: bool = True,
    saved: bool = True,
    notify: bool = True,
    
    ):
    """Создать скриншот выделенной области"""
    run_script([
        "area",
        "",
        str(edited).lower(),
        str(copied).lower(),
        str(saved).lower(),
        str(notify).lower()
    ])
    
@app.command()
def fast(notify: bool = True):
    """Сделать быстрый скриншот"""
    run_script([
        "fast",
        "", "", "", "",
        str(notify).lower()
    ])
    
@app.command()
def freeze(notify: bool = True):
    """Сделать скриншот с блокировкой изменений на экране"""
    run_script([
        "frezze",
        "", "", "", "",
        str(notify).lower()
    ])

    
if __name__ == "__main__":
    app()

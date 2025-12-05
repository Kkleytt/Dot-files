import typer

from caelestia.lock import app as lock_app
from caelestia.panels import app as panels_app
from caelestia.rofi import app as rofi_app
from caelestia.shell import app as shell_app

app = typer.Typer(help="Управление медиа")

# Вкладываем подкоманды
app.add_typer(lock_app, name="lock", help="Управление блокировкой экрана")
app.add_typer(panels_app, name="panels", help="Управление панелями оболочки")
app.add_typer(rofi_app, name="rofi", help="Запуск мини программ Rofi")
app.add_typer(shell_app, name="shell", help="Работа с оболочкой")
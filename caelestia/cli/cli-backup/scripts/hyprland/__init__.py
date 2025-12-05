import typer

from hyprland.decorate import app as decorate_app
from hyprland.hyprapps import app as hyprapps_app
from hyprland.idle import app as idle_app
from hyprland.shadow import app as shadow_app
from hyprland.starship import app as starship_app

app = typer.Typer(help="Управление медиа")

# Вкладываем подкоманды
app.add_typer(decorate_app, name="decorate", help="Управление внешним виддом Hyprland")
app.add_typer(hyprapps_app, name="hyprapps", help="Запуск системных приложений")
app.add_typer(idle_app, name="idle", help="Управление спящим режимом, выключение экрана и блокировкой")
app.add_typer(shadow_app, name="shadow", help="Управление скрытным режимом")
app.add_typer(starship_app, name="starship", help="Управление оболочкой терминала")

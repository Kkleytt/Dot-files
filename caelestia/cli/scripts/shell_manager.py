import typer

from caelestia import app as caelestia_app
from hyprland import app as hyprland_app
from media import app as media_app
from peripherals import app as peripherals_app

app = typer.Typer(
    help="Универсальный системный контроллер для NixOS + Hyprland + Caelestia shell",
    add_completion=False,
    rich_markup_mode="rich"
)

app.add_typer(peripherals_app, name="peripherals", help="Управление периферией и беспроводными адаптерами")
app.add_typer(media_app, name="media", help="Управление медиаплеером и устройствами")
app.add_typer(hyprland_app, name="hypr", help="Управление окружением Hyprland")
app.add_typer(caelestia_app, name="caelestia", help="Управление оболочкой Caelestia shell")

if __name__ == "__main__":
    app()
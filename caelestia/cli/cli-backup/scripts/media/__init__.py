import typer

from media.brightness import app as brightness_app
from media.microphone import app as microphone_app
from media.speaker import app as speaker_app
from media.player import app as player_app
from media.airplane import app as airplane_app
from media.screenrecord import app as screenrecord_app
from media.screenshot import app as screenshot_app

app = typer.Typer(help="Управление медиа")

# Вкладываем подкоманды
app.add_typer(brightness_app, name="brightness", help="Управление яркостью экрана")
app.add_typer(microphone_app, name="microphone", help="Управление громкостью микрофона")
app.add_typer(speaker_app, name="speaker", help="Управление громкостью динамиков/наушников")
app.add_typer(player_app, name="player", help="Управление плеером")
app.add_typer(airplane_app, name="airplane", help="Управление режимом полета")
app.add_typer(screenrecord_app, name="screenrecord", help="Запись экрана")
app.add_typer(screenshot_app, name="screenshot", help="Создание скриншотов")

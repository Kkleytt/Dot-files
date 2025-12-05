import typer

from peripherals.bluetooth import app as bluetooth_app
from peripherals.wifi import app as wifi_app
from peripherals.keyboard import app as keyboard_app
from peripherals.touchpad import app as touchpad_app
from peripherals.mouse import app as mouse_app
from peripherals.touchscreen import app as touchscreen_app
from peripherals.clean import app as clean_app

app = typer.Typer(help="Управление периферией и адаптерами")

# Вкладываем подкоманды
app.add_typer(bluetooth_app, name="bluetooth", help="Управление адаптером Bluetooth")
app.add_typer(wifi_app, name="wifi", help="Управление адаптером Wi-Fi")
app.add_typer(keyboard_app, name="keyboard", help="Управление клавиатурой")
app.add_typer(touchpad_app, name="touchpad", help="Управление тачпадом")
app.add_typer(touchscreen_app, name="touchscreen", help="Управление сенсорным экраном")
app.add_typer(mouse_app, name="mouse", help="Управление мышью")
app.add_typer(clean_app, name="clean", help="Режим очистки")

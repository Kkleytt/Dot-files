import os
from pathlib import Path
from time import sleep

import config as cfg
from formatter import hyprland_parser, pallete_parser, wallpaper_parser
from watchdog.events import FileSystemEventHandler
from watchdog.observers import Observer

# --- список файлов, за которыми следим ---
WATCH_FILES = [
    cfg.HYPRLAND_VARIABLES_PATH,
    cfg.CAELESTIA_WALLPAPER_PATH,
]
if not os.path.exists(cfg.THEMES_PATH):
    os.makedirs(cfg.THEMES_PATH, exist_ok=True)

def watch_event(path):
    if path == cfg.HYPRLAND_VARIABLES_PATH:
        hyprland_parser()
    elif path == cfg.CAELESTIA_WALLPAPER_PATH:   
        pallete_parser()
        wallpaper_parser()
    else:
        print(f"Error path - {path}")

class ConfigWatcher(FileSystemEventHandler):
    def __init__(self, watch_files):
        super().__init__()
        # нормализуем пути в строковый вид
        self.watch_files = {str(p.resolve()) for p in watch_files}

    def on_modified(self, event):
        trigger_path = Path(str(event.src_path))
        
        if event.is_directory:
            return

        if str(trigger_path.resolve()) in self.watch_files:
            print(f"[ 💥 ] Triggered by file: {trigger_path}")
            sleep(2)
            watch_event(trigger_path)

def app():
    observer = Observer()

    # подписываемся на все уникальные директории
    watched_dirs = {str(p.parent.resolve()) for p in WATCH_FILES}
    for d in watched_dirs:
        observer.schedule(ConfigWatcher(WATCH_FILES), path=d, recursive=False)

    observer.start()

    print("[ 🚀 ] Watching files:")
    for i, f in enumerate(WATCH_FILES):
        print(f"  {i}) {f}")
    print()
    
    # Предстартовое обновление данных
    watch_event(cfg.HYPRLAND_VARIABLES_PATH)
    sleep(1)
    watch_event(cfg.CAELESTIA_WALLPAPER_PATH)

    try:
        while True:
            sleep(2)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
    

if __name__ == "__main__":
    app()

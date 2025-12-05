#!/usr/bin/env python3
import json
import os
import subprocess
import sys
from pathlib import Path

import system_utils as utils

# --- Конфигурация ---
mDIR = Path.home() / "Music"

# --- Онлайн-станции ---
online_music = {
    "󰋋 Lofi Girl": "https://play.streamafrica.net/lofiradio",
    "󰋋 Lofi": "https://radiorecord.hostingradio.ru/lofi96.aacp",
    "󰘉 Jazz FM": "http://nashe1.hostingradio.ru/jazz-128.mp3",
    "󱒕 Japan City Pop": "https://play.streamafrica.net/japancitypop",
    "󱝆 Summer Dance": "https://radiorecord.hostingradio.ru/summerparty96.aacp",
    " Ambient": "https://radiorecord.hostingradio.ru/ambient96.aacp",
    "󰐅 Christmas Chill": "https://radiorecord.hostingradio.ru/christmaschill96.aacp",
    "󰯐 Rap classic": "https://radiorecord.hostingradio.ru/rapclassics96.aacp",
    " Dream Pop": "https://radiorecord.hostingradio.ru/dreampop96.aacp",
    " Нафталин": "https://radiorecord.hostingradio.ru/naft96.aacp",
    "󰗕 Гастарбатер": "https://radiorecord.hostingradio.ru/gast96.aacp",
}

def send_notify(title: str = "Player", body: str = "", icon: str = "danger", sound: str = "error-2"):
    fifo_path = Path.home() / ".cache" / "caelestia" / "osd.fifo"

    payload = {
        "group": "player",
        "title": title,
        "body": body,
        "icon": icon,
        "timeout": 2500,
        "sound": sound,
        "urgency": "normal"
    }

    try:
        fd = os.open(fifo_path, os.O_WRONLY | os.O_NONBLOCK)
        with os.fdopen(fd, "w") as fifo:
            fifo.write(json.dumps(payload) + "\n")
    except BlockingIOError:
        print("Нет активного читателя FIFO — уведомление не отправлено.")
    except Exception as e:
        print(f"Ошибка отправки уведомления: {e}")
        
def stop_vlc(notify: bool = True):
    subprocess.run(["pkill", "-f", "Rofi-Radio"], stderr=subprocess.DEVNULL)
    subprocess.run(["pkill", "vlc"], stderr=subprocess.DEVNULL)
    send_notify("Музыка остановлена", "", "stop", "player") if notify else None
    
def get_tracks(dirpath: Path):
    exts = [".mp3", ".flac", ".wav", ".ogg", ".m4a", ".mp4", ".opus"]
    return sorted([p for p in dirpath.iterdir() if p.is_file() and p.suffix.lower() in exts])

def get_ordered_tracks(dirpath: Path, mode="sorted"):
    tracks = get_tracks(dirpath)
    return tracks

def play_local_music_vlc(current_dir: Path, mode="sorted"):
    while True:
        options = []
        tracks = []

        if current_dir != mDIR:
            options.append("󱞺 .. (Назад)")

        subdirs = sorted([p for p in current_dir.iterdir() if p.is_dir()])
        for sd in subdirs:
            options.append(f"󱍙 {sd.name}/")

        track_list = get_ordered_tracks(current_dir, mode)

        for t in track_list:
            tracks.append(t)
            options.append(f" {t.name}")

        if not options:
            send_notify("Ошибка", "Папка пуста", "folder", "warning")
            return

        choice, code = utils.run_rofi(
            payload=options,
            theme="radio",
            bytes=False
        )
        
        match code:
            # Esc / Cancel
            case 1:
                sys.exit(0)
            
            # Enter
            case 0:
                match choice:
                    case "󱞺 .. (Назад)":
                        play_local_music_vlc(current_dir.parent, mode)
                        return
                    case s if s.startswith("󱍙"):
                        sub_dir = choice[2:].strip().rstrip("/")
                        new_path = current_dir / sub_dir
                        play_local_music_vlc(new_path, "sorted")
                        return
                    case s if s.startswith(""):
                        selected_name = choice[2:].strip()
                        selected_track = next((t for t in tracks if t.name == selected_name), None)
                        if not selected_track:
                            continue
                        all_tracks = get_ordered_tracks(current_dir, mode)
                        idx = all_tracks.index(selected_track) if selected_track in all_tracks else 0
                        playlist = all_tracks[idx:] + all_tracks[:idx]
                        stop_vlc(False)
                        subprocess.Popen(["vlc", "--intf", "dummy", "--no-video", "--meta-title=Rofi-Music"] + [str(p) for p in playlist])
                        send_notify("Воспроизведение",f"Плейлиста из {len(playlist)} Треков", "play", "player")
                        return
                    
            # Error
            case _:
                sys.exit(0)

def play_online_music_vlc():
    choice, code = utils.run_rofi(payload=online_music.keys(), theme="radio", bytes=False)
    match code:
        # Enter
        case 0:
            link = online_music[choice]
            stop_vlc(False)
            subprocess.Popen([
                "vlc", "--intf", "dummy", "--no-video", "--play-and-exit",
                "--meta-title=Rofi-Radio", f"--meta-artist={choice}", link
            ])
            send_notify("Воспроизведение", f"Радио - {choice}", "radio", "player")
        
        # Esc / Cancel
        case 1:
            sys.exit(0)
        
        # Error
        case _:
            sys.exit(0)
    
def main_menu():
    choice, code = utils.run_rofi(
        payload=[" Online", " Local", " Stop "], 
        theme="radio-menu",
        bytes=False        
    )
    
    match code:
        # Enter
        case 0:
            match choice:
                case " Online": 
                    play_online_music_vlc()
                case " Local": 
                    play_local_music_vlc(mDIR)
                case " Stop": 
                    stop_vlc(True)
        
        # Esc / Cancel
        case 1:
            sys.exit(0)
        
        # Error
        case _:
            sys.exit(0)
        
def app():
  main_menu()

if __name__ == "__main__":
    app()

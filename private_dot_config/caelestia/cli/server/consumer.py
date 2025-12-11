#!/usr/bin/env python3
import asyncio
import subprocess as sp
import json as js
import os
import time as tm
import psutil
import argparse
import sys
from typing import Dict
from dbus_fast.aio import MessageBus
from dbus_fast import Variant

from logger import setup_logging

# Конфиг
FIFO_PATH = os.path.expanduser("~/.cache/caelestia/osd.fifo")           # Путь к FIFO
NOTIFY_DIR = os.path.expanduser("~/.config/caelestia/theme")            # Путь до директории иконок и звуков
critical_groups = [
    "critical", "emergency", "alert", 
    "warning", "error", "failure", 
    "fatal", "system", "exception"
]                                                                       # Группы критичных уведомлений (Будут воспроизводить звук и жить 8 секунд)
_sound_cooldown = 0.05                                                  # Время между воспроизведениями звуков (секунды)

logger = setup_logging(
    log_file=os.path.expanduser("~/.cache/caelestia/consumer_logs.log")
)

# Активные состояния
_active_timers: Dict[str, asyncio.Task] = {}        # Хранение активных таймеров жизни
_active_sounds: Dict[str, asyncio.Task] = {}        # Хранение активных таймеров звука
_active_notifs: Dict[str, Dict] = {}                # Хранение списка активных уведомлений
_dbus = None                                        # Интерфейс D-Bus
_last_sound_time = 0                                # Последнее время воспроизведения звука

async def connect_dbus():
    bus = await MessageBus().connect()
    
    introspection = await bus.introspect(
        "org.freedesktop.Notifications",
        "/org/freedesktop/Notifications"
    )
    
    obj = bus.get_proxy_object(
        "org.freedesktop.Notifications",
        "/org/freedesktop/Notifications",
        introspection
    )
    
    return obj.get_interface("org.freedesktop.Notifications")

def check_file_path(path) -> bool:
        if os.path.isfile(path):
            return True
        return False
    
class SmartNotification:
    def __init__(
        self,
        group: str,
        title: str,
        body: str,
        icon: str = "unknown",
        sound: str = "error-3",
        urgency: int = 1,
        timeout: int = 2500,
        clear_notify: bool = True,
        clear_all: bool = False,
        play_sound: bool = True
    ):
        global _dbus
        
        self.dbus = _dbus                       # Интерфейс D-Bus
        
        self.group = group                      # Класс уведомления
        self.title = title                      # Заголовок уведомления
        self.body = body                        # Сообщение уведомления
        self.urgency = urgency                  # Уровень важности (0, 1, 2)
        self.timeout = timeout                  # Время жизни уведомления (в мс)
        self.clear_notify = clear_notify        # Очистить уведомление после смерти
        self.play_sound = play_sound            # Воспроизвести звук при уведомлении
        self.fake_timeout = 40000               # Фейковое время жизни (для имитации OSD)
        
        dirt_icon = f"{NOTIFY_DIR}/icons/{icon}.png"
        self.icon = dirt_icon if check_file_path(dirt_icon) else "unknown"
        dirt_sound = f"{NOTIFY_DIR}/sounds/{sound}.ogg"
        self.sound = dirt_sound if check_file_path(dirt_sound) else "system"
        self.hints = {"transient": Variant("b", True)} if clear_notify else {}
        
        if group in critical_groups or urgency == 2:    # Если группа критичная или важность 2
            print("CRITICAL NOTIFY")
            self.icon = f"{NOTIFY_DIR}/icons/danger.png"
            self.sound = f"{NOTIFY_DIR}/sounds/error-3.ogg"
            self.urgency = 2
            self.timeout = 8000
            self.play_sound = True
            self.clear_notify = False

        if clear_all:
            sp.run(["caelestia", "shell", "notifs", "clear"], stdout=sp.DEVNULL, stderr=sp.DEVNULL)
    
    async def send(self) -> bool:  
        try:
            # Получение актуальных переменных
            now = tm.time()
            stored = _active_notifs.get(self.group, {})
            notify_id = stored.get("id")
            last_update = stored.get("last_update", 0)
            old_timeout = stored.get("timeout", 0)
            use_id = notify_id if notify_id and now < (last_update + old_timeout / 1000) else 0

            # Отправка уведомления
            new_id = await self.dbus.call_notify(       # type: ignore
                "Caelestia",                            # Имя приложения
                use_id,                                 # Старый ID (0 - новое уведомление)
                self.icon,                              # Полный путь до иконки
                self.title,                             # Заголовок уведомления
                self.body,                              # Текст уведомления
                [],                                     # Действия (кнопки)
                self.hints,                             # Дополнительные параметры
                self.fake_timeout                       # Время жизни уведомления (в мс)
            )
            
            # Запись в лог
            logger.info(f"[SENT] {new_id}, {use_id}, {self.group}, {self.title}, {self.body}, {self.timeout}")

            # Добавление в активные уведомления
            _active_notifs[self.group] = {
                "id": new_id,
                "last_update": now,
                "timeout": self.timeout,
            }
            
            # Запуск звукового сопровождения (если необходимо)
            if self.play_sound:
                self._schedule_sound()
            
            # Запуск таймера на закрытие уведомления
            self._schedule_close(now)
            
            return True
        except Exception as e:
            
            logger.error(f"Notification error: {e}")
            return False

    def _schedule_sound(self):
        def calculate_notify_volume(S: int) -> float:
            S_ref = 30
            if S <= 0:
                S = 1

            if S <= S_ref:
                V = (S_ref / S) ** 2.0
            elif S <= 100:
                V = (S_ref / S) ** 2.0
            elif S <= 140:
                V = (S_ref / S) ** 2.4
            elif S <= 160:
                V = (S_ref / S) ** 3.0
            else:
                V = (S_ref / S) ** 3.0

            print(f"Volume = {V}")
            return max(V, 0.01)
        
        def check_dnd() -> bool:
            result = sp.check_output(
                ["caelestia", "shell", "notifs", "isDndEnabled"],
                stderr=sp.DEVNULL, text=True
            )
            return result.strip() == "true"

        async def play():
            global _last_sound_time

            # DND проверка
            if check_dnd() and self.group not in critical_groups:
                return

            # Debounce: если недавно был звук, пропускаем
            now = tm.monotonic()
            if now - _last_sound_time < _sound_cooldown:
                return
            _last_sound_time = now
            
            system_volume = sp.check_output(
                ["pamixer", "--get-volume"],
                stderr=sp.DEVNULL, text=True
            )
            system_volume = int(system_volume.strip())

            try:
                cmd = ["pw-play", f"--volume={calculate_notify_volume(system_volume)}", self.sound]
                proc = await asyncio.create_subprocess_exec(
                    *cmd, stdout=asyncio.subprocess.DEVNULL, stderr=asyncio.subprocess.DEVNULL
                )
                # не ждём завершения, чтобы не блокировать
                asyncio.create_task(proc.wait())
            finally:
                _active_sounds.pop(self.group, None)

        # всегда создаём задачу, но с защитой от накладок
        _active_sounds[self.group] = asyncio.create_task(play())

    def _schedule_close(self, trigger_time: float):        
        async def closer():
            await asyncio.sleep(self.timeout / 1000)
            
            stored = _active_notifs.get(self.group)
            
            if not stored:
                return
            
            if stored["last_update"] == trigger_time:
                use_id = stored["id"]
                
                if self.clear_notify:
                    await self.dbus.call_close_notification(use_id) # type: ignore
                else:
                    await self.dbus.call_notify(                # type: ignore
                        "Caelestia",                            # app name
                        use_id,                                 # replaces_id (0 = новое)
                        self.icon,                              # icon path
                        self.title,                             # title
                        self.body,                              # message body
                        [],                                     # actions (buttons) 
                        self.hints,                             # hints
                        200                                     # timeout (мс)
                    )
                
                logger.info(f"[CLOSE] {use_id}, {self.group}, {self.title}, {self.body}, {self.timeout}")
                _active_notifs.pop(self.group, None)
                _active_sounds.pop(self.group, None)

        if self.group in _active_timers:
            _active_timers[self.group].cancel()
            
        _active_timers[self.group] = asyncio.create_task(closer())

async def fifo_consumer():
    # гарантируем наличие FIFO
    if not os.path.exists(FIFO_PATH):
        try:
            sp.run(["rm", "-f", FIFO_PATH])
            await asyncio.sleep(2)
            sp.run(["mkfifo", FIFO_PATH])
        except Exception as e:
            logger.error("Ошибка при создании FIFO: %s", e)
            return

    logger.info("Consumer started, waiting for messages...")

    def blocking_read():
        with open(FIFO_PATH, "r") as fifo:
            for line in fifo:
                yield line

    while True:
        try:
            # читаем блокирующе в отдельном потоке
            for line in await asyncio.to_thread(lambda: list(blocking_read())):
                try:
                    data = js.loads(line.strip())
                except js.JSONDecodeError:
                    logger.warning("Invalid JSON: %s", line.strip())
                    continue

                urgency_map = {"low": 0, "normal": 1, "critical": 2}
                urgency_int = urgency_map.get(data.get("urgency", "normal"), 1)
                group = data.get("group", "default")

                notif = SmartNotification(
                    group=group,
                    title=data.get("title", ""),
                    body=data.get("body", ""),
                    icon=data.get("icon", "unknown"),
                    sound=data.get("sound", "system"),
                    urgency=urgency_int,
                    timeout=data.get("timeout", 2000),
                    clear_notify=data.get("clearnotify", True),
                    clear_all=data.get("clearall", False),
                    play_sound=data.get("play_sound", True),
                )

                # устойчивый запуск отправки
                try:
                    await asyncio.create_task(notif.send())
                except Exception as e:
                    logger.error("Ошибка при отправке уведомления: %s", e)
                    # подождать и попробовать снова, если dbus ещё не готов
                    await asyncio.sleep(2)

        except Exception as e:
            logger.error("Ошибка в основном цикле consumer: %s", e)
            await asyncio.sleep(5)  # пауза перед повтором
            
async def async_start_server():
    global _dbus
    
    _dbus = await connect_dbus()
    
    logger.info(f"OSD server started at {FIFO_PATH}")
    await fifo_consumer()
        
def start_server():
    try:
        asyncio.run(async_start_server())
    except KeyboardInterrupt:
        print("Stop by user")
    except Exception as e:
        logger.exception(f"Fatal error: {e}")
    finally:
        exit(0)

def kill_existing_consumers():
    my_pid = os.getpid()
    my_name = os.path.basename(sys.executable if "python" in sys.argv[0].lower() else sys.argv[0])
    # Если запущен как python script.py — ищем по python, иначе по имени
    count = 0
    
    for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
        try:
            cmd = proc.cmdline()
            if not cmd:
                continue
                
            # Ищем точно по имени скрипта в cmdline
            if any(os.path.basename(arg) == "consumer" for arg in cmd) or proc.name() == "consumer":
                if proc.pid != my_pid and proc.is_running():
                    proc.kill()
                    count += 1
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            pass
    
    if count:
        print(f"Убил {count} старых consumer'ов")
    else:
        print("Нет других consumer'ов")
    exit(0)

def parse_args():
    parser = argparse.ArgumentParser(description="Caelestia OSD consumer")
    parser.add_argument("-b", "--background", action="store_true", help="Запуск в фоне")
    parser.add_argument("--kill", action="store_true", help="Убить все запущенные consumer'ы")
    return parser.parse_args()

def app():
    args = parse_args()

    if args.kill:
        kill_existing_consumers()

    if args.background:
        # Полностью отцепляемся от терминала
        if os.fork():
            os._exit(0)
        os.setsid()
        if os.fork():
            os._exit(0)

        # >>> ЭТО ГЛАВНОЕ — закрываем и перенаправляем всё в никуда <<<
        sys.stdout.flush()
        sys.stderr.flush()
        print(f"Consumer запущен в фоне (PID: {os.getpid()})", file=sys.stderr)  # это последнее сообщение увидишь только при запуске
        with open(os.devnull, 'r+b') as devnull:
            os.dup2(devnull.fileno(), sys.stdin.fileno())
            os.dup2(devnull.fileno(), sys.stdout.fileno())
            os.dup2(devnull.fileno(), sys.stderr.fileno())

        # Можно ещё PID записать, если хочешь
    else:
        if not args.kill:
            print("Consumer запущен в терминале (Ctrl+C для остановки)")

    try:
        asyncio.run(async_start_server())
    except KeyboardInterrupt:
        print("Остановлено пользователем")
    except Exception as e:
        logger.exception(f"Фатальная ошибка: {e}")

if __name__ == "__main__":
    app()

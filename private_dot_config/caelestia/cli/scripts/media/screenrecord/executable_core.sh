RecordDir="$HOME/Videos/Recordings"
PidFile="$HOME/.cache/gpu-screen-recorder.pid"
mkdir -p "$RecordDir"

send_notify() {
  local body="$1"
  local icon="$2"
  local sound="$3"

  # Формируем JSON одной строкой
  local json
  json=$(printf '{"group":"screenrecorder","title":"ScreenRecord","body":"%s","icon":"%s","timeout":2500,"sound":"%s","urgency":"normal"}\n' \
        "$body" "$icon" "$sound")

  # Записываем в FIFO
  printf '%s' "$json" > "$HOME/.cache/caelestia/osd.fifo"
}

is_running() {
  local pid
  [[ -f "$PidFile" ]] || return 1
  pid=$(<"$PidFile")
  [[ -n "$pid" ]] || return 1
  kill -0 "$pid" 2>/dev/null
}

start_recording() {
    local sound="$1"
    local save="$2"
    local notify="$3"
        
    # Проверка на существующую запись
    if is_running; then
        [[ "$notify" == "true" ]] && send_notify "Уже идёт запись (PID $(<"$PidFile"))" "screenrecord" "pop"
        return 1
    fi
    
    # Генерация имени файла
    local ts outfile
    ts=$(date +"%Y-%m-%d_%H-%M-%S")
    outfile="$RecordDir/${ts}.mp4"
        
    # Разбор аргументов
    local args=()
    args+=("-w" "portal")
    [[ "$sound" == "true" ]] && args+=("-a" "default-output")
    [[ "$save" == "true" ]] && args+=("-o" "$outfile")

    # Запуск с portal — откроется диалог выбора экрана/окна/области
    gpu-screen-recorder "${args[@]}" >/dev/null 2>&1 &
    local pid=$!
    sleep 0.2

    if kill -0 "$pid" 2>/dev/null; then
        printf '%s' "$pid" > "$PidFile"
        disown "$pid" 2>/dev/null || true
        [[ "$notify" == "true" ]] && send_notify "Запись начата (PID $pid)" "screenrecord" "pop"
        return 0
    else
        [[ "$notify" == "true" ]] && send_notify "Не удалось начать запись" "danger" "error-2"
        return 1
    fi
}

toggle_pause() {
    local notify="$1"
    
    if ! is_running; then
        [[ "$notify" == "true" ]] && send_notify "Запись не запущена" "warning" "pop"
        printf 'Запись не запущена\n'
        return 1
    fi

    local pid cur_state
    pid=$(<"$PidFile")
    if [[ -r "/proc/$pid/status" ]]; then
        cur_state=$(awk '/^State:/ {print $2}' "/proc/$pid/status" 2>/dev/null || true)
    else
        cur_state=""
    fi

    if [[ "$cur_state" == "T" ]]; then
        kill -CONT "$pid" 2>/dev/null 
        [[ "$notify" == "true" ]] && send_notify "Возобновлена (PID $pid)" "play" "pop"
    else
        kill -STOP "$pid" 2>/dev/null
        [[ "$notify" == "true" ]] && send_notify "Пауза (PID $pid)" "pause" "pop"
    fi
}

stop_recording() {
    local notify="$1"
    
  if ! is_running; then
    [[ "$notify" == "true" ]] && send_notify "Запись не запущена" "warning" "pop"
    return 1
  fi

  local pid
  pid=$(<"$PidFile")

  # сначала корректно посылаем SIGINT чтобы приложение завершило запись и закрыл файл
  kill -INT "$pid" 2>/dev/null
  # ждём до 5 секунд
  for i in {1..10}; do
    sleep 0.5
    if ! kill -0 "$pid" 2>/dev/null; then
      break
    fi
  done

  # если всё ещё жив — SIGTERM, затем SIGKILL
  if kill -0 "$pid" 2>/dev/null; then
    kill -TERM "$pid" 2>/dev/null
    sleep 0.5
  fi
  if kill -0 "$pid" 2>/dev/null; then
    kill -KILL "$pid" 2>/dev/null
    sleep 0.2
  fi

  if kill -0 "$pid" 2>/dev/null; then
    send_notify "Не удалось остановить процесс $pid" "danger" "error-2"
    return 1
  else
    rm -f "$PidFile"
    send_notify "Запись остановлена" "screenrecord-off" "pop"
    copy_last_to_clipboard "$notify"
  fi
}

status_text() {
    local notify="$1"
    
    if is_running; then
        local pid state
        pid=$(<"$PidFile")
        if [[ -r "/proc/$pid/status" ]]; then
            state=$(awk '/^State:/ {print $2}' "/proc/$pid/status" 2>/dev/null || true)
        else
            state="?"
        fi
        printf 'Запись запущена (PID %s), состояние: %s\n' "$pid" "$state"
        [[ "$notify" == "true" ]] && send_notify "Запись запущена $pid" "screenrecord" "pop"
    else
        printf 'Запись не запущена\n'
        [[ "$notify" == "true" ]] && send_notify "Запись не запущена" "screenrecord-off" "pop"
    fi
}

copy_last_to_clipboard() {
    local notify="$1"
    
    local last
    last=$(ls -1t "$RecordDir"/* 2>/dev/null | head -n1 || true)
    
    if [[ -z "$last" ]]; then
        [[ "$notify" == "true" ]] && send_notify "Файл не найден для копирования" "warning" "pop"
        return 1
    fi
    
    wl-copy --type video/mp4 < "$last" 
    [[ "$notify" == "true" ]] && send_notify "Скопировано в буфер" "clipboard" "pop"
}


# Examples
method="${1:-start}"            # {start|stop|toggle|status} - Выбор режима
sound="false"                   # {true|false} - Записать звук устройства
save="true"                     # {true|false} - Записать видео в файл
notify="true"                   # {true|false} - Отправлять уведомления, обязательный параметр (Становится на место screen когда выбран режим stop|play|pause|toggle)

# Выявление флагов (Булевых значений)
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sound|--d)        sound="true"; shift        ;;
    --save|--s)         save="true"; shift         ;;
    --notify|--n)       notify="true"; shift       ;;
    *)                  POSITIONAL+=("$1"); shift  ;;
  esac
done
set -- "${POSITIONAL[@]}"


case "$method" in
    start)  start_recording "$sound" "$save" "$notify" ;;
    stop)   stop_recording "$notify" ;;
    toggle) toggle_pause "$notify" ;;
    status) status_text "$notify" ;;
    *)      echo "Error Args" ;;
esac
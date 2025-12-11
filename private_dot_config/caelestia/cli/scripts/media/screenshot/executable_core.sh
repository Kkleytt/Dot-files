#!/usr/bin/env bash
# /scripts/media/screenshot/script.sh

send_notify() {
  local body="$1"
  local icon="$2"
  local sound="${3:-"system"}"

  local FIFO="$HOME/.cache/caelestia/osd.fifo"

  # Формируем JSON одной строкой
  local json
  json=$(printf '{"group":"screenshot","title":"Screenshot","body":"%s","icon":"%s","timeout":2500,"sound":"%s","urgency":"normal"}\n' \
        "$body" "$icon" "$sound")

  # Записываем в FIFO
  printf '%s' "$json" > "$FIFO"
}

genarate_name() {
    local method="$1"
    local dir="$2"
    
    case "$method" in
        number)
            local number last_num
        
            # Найдём максимальный номер среди файлов *.png
            last_num=$(find "$dir" -maxdepth 1 -type f -name '[0-9][0-9][0-9][0-9][0-9][0-9].png' \
            | sed -E 's#.*/([0-9]{6})\.png#\1#' \
            | sort -n \
            | tail -n1)
        
            if [[ -z "$last_num" ]]; then
                number=0
            else
                number=$((10#$last_num + 1))
            fi
            echo "$(printf '%06d' "$number").png"
            ;;
        date) 
            echo "$(date +%Y-%m-%d_%H%M%S).png"
            ;;
        *)
            echo "$(date +%Y-%m-%d_%H%M%S).png"
            ;;
    esac
}

wait_for_file_stable() {
    local file="$1"
    local timeout="${2:-3000}"   # ms, общий таймаут (по умолчанию 3000 ms)
    local interval=50            # начальный интервал ms
    local elapsed=0
    local prev_size=-1
    local stable_count=0
    local need_stable=3

    while :; do
        if [[ -f "$file" ]]; then
            local size
            # stat -c%s работает в GNU; fallback на wc -c если нужно
            if size=$(stat -c%s -- "$file" 2>/dev/null); then
                :
            else
                size=$(wc -c < "$file" 2>/dev/null || echo 0)
            fi
        
            if [[ "$size" -eq "$prev_size" ]]; then
                stable_count=$((stable_count+1))
            else
                stable_count=0
            fi
        
            prev_size=$size
        
            # если размер не менялся N раз подряд — считаем готовым
            if [[ $stable_count -ge $need_stable && $size -gt 0 ]]; then
                return 0
            fi
        fi

        # таймаут
        if (( elapsed >= timeout )); then
            return 1
        fi
    
        # sleep for interval ms
        sleep_time=$(awk "BEGIN {printf \"%.3f\", $interval/1000}")
        sleep "$sleep_time"
    
        elapsed=$((elapsed + interval))
    done
}

# Пути
default_path="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
state_dir="${XDG_CACHE_HOME:-$HOME/.cache}/screenshot"
tmpfile=".tmp.$(date +%s%N).png"
mkdir -p "$state_dir" "$default_path"

# Аргументы
method="${1:-screen}"                   # screen|window|region
annotate="${2:-none}"                   # satty|gradia|none
clipboard="${3:-true}"                  # true|false
save="${4:-true}"                       # true|false
notify="${5:-true}"                     # true|false
freeze="${6:-false}"                    # true|false
dir="${7:-$default_path}"
name="${8:-"$(genarate_name number $dir)"}"

# Создание команды для hyprshot
args=(-o $dir -f $tmpfile -s)
[[ "$freeze" == "true" ]] && args+=(-z)

# Создание скриншота
case "$method" in
    screen) hyprshot -m output "${args[@]}" ;;
    region) hyprshot -m region "${args[@]}" ;;
    window) hyprshot -m window "${args[@]}" ;;
    active) hyprshot -m active "${args[@]}" ;;
esac

# Ожидание конца записи файла
if ! wait_for_file_stable "$dir/$tmpfile" 5000; then exit 1; fi

# Аннотация
case "$annotate" in
    satty)  satty -f "$dir/$tmpfile" -o "$dir/$tmpfile" ;;
    gradia) gradia "$dir/$tmpfile" && exit 0 ;;  # Так как Gradia GTK приложение - она сама все сделает
    *) ;;
esac

# Буфер обмена
[[ "$clipboard" == "true" ]] || [[ "$save" == "false" ]] && wl-copy < "$dir/$tmpfile"

# Сохранение файла
if [[ "$save" == "true" ]]; then    
    [[ "$notify" == "true" ]] && send_notify "Name is $name" "screenshot-$method" "drop"
    mv "$dir/$tmpfile" "$dir/$name"
fi

# Запоминание последних действий
cat > "$state_dir/last.json" <<EOF
{"method":"$method","annotate":"$annotate","clipboard":$clipboard,"save":$save,"notify":$notify,"freeze":$freeze,"dir":$dir,"name":$name}
EOF

#!/usr/bin/env bash
# simple-rofi-screenshot.sh

Core="/home/kkleytt/.config/caelestia/cli/scripts/media/screenrecord/core.sh"
Rofi="rofi -i -dmenu -matching normal -config /home/kkleytt/.config/rofi/configs/screenshot.rasi -click-to-exit"

rofi_select() {
  local items=("$@")
  local out
  # запускаем rofi, сохраняем вывод и код возврата
  out=$(printf '%s\n' "${items[@]}" | eval "$Rofi " 2>/dev/null)
  local rc=$?
  out="${out%%$'\n'*}"
  if [[ -n "$out" ]]; then printf '%s' "$out"; fi
  return $rc
}

check_keybinds() {
    local status_code="$1"
    
    echo "Status code: " "$status_code"
    
    case "$status_code" in
        0) : ;;
        1) exit 0 ;;
        
        # Alt + {}
        # Быстрые скрины ( -Notify | -Annotate | -Save | -Freeze )
        10) "$Core" "screen" "none" "true" "true" "false" "false"; exit 0 ;;
        11) "$Core" "window" "none" "true" "true" "false" "false"; exit 0 ;;
        12) "$Core" "region" "none" "true" "true" "false" "false"; exit 0 ;;
        
        # Обычные скрины ( -Annotate | -Freeze )
        13) "$Core" "screen" "none" "true" "false" "talse" "false"; exit 0 ;;
        14) "$Core" "window" "none" "true" "false" "talse" "false"; exit 0 ;;
        15) "$Core" "region" "none" "true" "false" "talse" "false"; exit 0 ;;
        
        # Быстрые замороженные ( -Notify | -Annotate )
        16) "$Core" "screen" "none" "true" "true" "false" "talse"; exit 0 ;;
        17) "$Core" "window" "none" "true" "true" "false" "talse"; exit 0 ;;
        18) "$Core" "region" "none" "true" "true" "false" "talse"; exit 0 ;;
        
        # Ctrl + {}
        # С Satty ( -Notify | -Freeze )
        19) "$Core" "screen" "satty" "true" "true" "false" "false"; exit 0 ;;
        20) "$Core" "window" "satty" "true" "true" "false" "false"; exit 0 ;;
        21) "$Core" "region" "satty" "true" "true" "false" "false"; exit 0 ;;
        
        # С Gradia ( -Notify | -Freeze )
        22) "$Core" "screen" "gradia" "true" "true" "false" "false"; exit 0 ;;
        23) "$Core" "window" "gradia" "true" "true" "false" "false"; exit 0 ;;
        24) "$Core" "region" "gradia" "true" "true" "false" "false"; exit 0 ;;
        
        # С Satty freeze ( -Notify )
        25) "$Core" "screen" "satty" "true" "true" "false" "talse"; exit 0 ;;
        26) "$Core" "window" "satty" "true" "true" "false" "talse"; exit 0 ;;
        27) "$Core" "region" "satty" "true" "true" "false" "talse"; exit 0 ;;
        
        *) exit 0 ;;
    esac
}

# вызывает HOT_SCRIPT в фоне
take_screenrecord() {
    local method="${1:-start}"
    local save="${2:-true}"
    local sound="${3:-false}"
    
    local args=()
    [[ "$save" == "true" ]] && args+=("--save")
    [[ "$sound" == "true" ]] && args+=("--sound")

    # запускаем в фоне, чтобы rofi вернул управление
    "$Core" "$method" "${args[@]}" --notify
}

main() {
    local opt method sound save clipboard
    
    # Выбор метода
    opt=$(rofi_select "Record" "Stop" "Play/Pause" "Status")
    rc=$?
    if [[ "$opt" == "Record" ]]; then method=start; elif [[ "$opt" == "Stop" ]]; then method=stop; elif [[ "$opt" == "Play/Pause" ]]; then method=toggle; else method=status; fi
    check_keybinds "$rc"
    [[ "$method" == "stop" ]] && take_screenrecord "stop"
    [[ "$method" == "toggle" ]] && take_screenrecord "toggle"
    [[ "$method" == "status" ]] && take_screenrecord "status"
    
    
    # Выбор записи звука
    opt=$(rofi_select "Sound" "OFF")
    rc=$?
    if [[ "$opt" == "Sound" ]]; then sound=true; else sound=false; fi
    check_keybinds "$rc"

    # Выбор сохранения
    opt=$(rofi_select "Save" "OFF")
    rc=$?
    if [[ "$opt" == "Save" ]]; then save=true; else save=false; fi
    check_keybinds "$rc"

    # Запуск команды
    take_screenrecord "$method" "$sound" "$save"
}

# Аргументы
method="$1"

case "$method" in
    ui)     main ;;
    *)      take_screenrecord "$@" ;;
esac
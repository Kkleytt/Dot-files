#!/usr/bin/env bash

# --- CONFIG ---
CACHE_FILE="$HOME/.config/hypr/scheme/variables-new.json"
mkdir -p "$(dirname "$CACHE_FILE")"
touch "$CACHE_FILE"

# --- LOGGING ---
_hv_err() { echo "hypr-vars: $*" >&2; }
_hv_dbg() { [ -n "$HV_DEBUG" ] && echo "[DEBUG] $*"; }

# --- HELPERS: типы и нормализация ---
_hv_is_int() { [[ "$1" =~ ^-?[0-9]+$ ]]; }
_hv_is_bool_word() { [[ "$1" == "true" || "$1" == "false" ]]; }
_hv_is_bool_num() { [[ "$1" == "1" || "$1" == "0" ]]; }
_hv_to_bool() {
    local v="$1"
    if _hv_is_bool_word "$v"; then echo "$v"; return 0; fi
    if _hv_is_bool_num "$v"; then [ "$v" == "1" ] && echo "true" || echo "false"; return 0; fi
    return 1
}

# Раскрытие переменных окружения ($HOME, $EDITOR и т.п.)
_hv_expand_env() {
    # envsubst безопасно заменяет $VAR в строке
    envsubst <<< "$1"
}

# --- JSON I/O ---
# Получить тип значения ключа в JSON: string/number/boolean/null/object/array
_hv_json_type() {
    local key="$1"
    jq -r --arg k "$key" 'if has($k) then .[$k] | type else "null" end' "$CACHE_FILE"
}

# Получить значение ключа без кавычек (строки: как есть, числа/булевы: как литералы)
get_variable() {
    local var_name="$1"
    [ -z "$var_name" ] && { _hv_err "Usage: get_variable <name>"; return 1; }
    [ ! -f "$CACHE_FILE" ] && { _hv_err "Cache not found: $CACHE_FILE"; return 1; }

    local t val
    t=$(_hv_json_type "$var_name")

    case "$t" in
        null)
            _hv_err "Variable '$var_name' not found"
            return 1
            ;;
        string)
            val=$(jq -r --arg k "$var_name" '.[$k]' "$CACHE_FILE")
            printf '%s\n' "$val"
            ;;
        number|boolean|object|array)
            val=$(jq --arg k "$var_name" '.[$k]' "$CACHE_FILE")
            printf '%s\n' "$val"
            ;;
        *)
            _hv_err "Unknown JSON type '$t' for '$var_name'"
            return 1
            ;;
    esac
}

# Записать значение по ключу с корректным типом
# set_variable <name> <value> [type=string|integer|boolean|toggle]
set_variable() {
    local var_name="$1"
    local new_value="$2"
    local var_type="$3"

    [ -z "$var_name" ] && { _hv_err "Usage: set_variable <name> <value> [type]"; return 1; }
    [ ! -f "$CACHE_FILE" ] && { _hv_err "Cache not found: $CACHE_FILE"; return 1; }

    # Раскрываем переменные окружения ($HOME и др.)
    new_value=$(_hv_expand_env "$new_value")
    _hv_dbg "Expanded value: $new_value"

    # Обработка типа/переключателя
    case "${var_type:-string}" in
        integer)
            if ! _hv_is_int "$new_value"; then
                _hv_err "Value is not integer: $new_value"
                return 1
            fi
            ;;
        boolean)
            if ! _hv_is_bool_word "$new_value" && ! _hv_is_bool_num "$new_value"; then
                _hv_err "Boolean must be true/false/1/0"
                return 1
            fi
            new_value=$(_hv_to_bool "$new_value") || { _hv_err "Invalid boolean: $new_value"; return 1; }
            ;;
        toggle)
            # Тогглируем существующий булев ключ
            local current t
            t=$(_hv_json_type "$var_name")
            if [[ "$t" != "boolean" ]]; then
                _hv_err "Cannot toggle non-boolean variable '$var_name' (type: $t)"
                return 1
            fi
            current=$(get_variable "$var_name") || return 1
            if [[ "$current" == "true" ]]; then new_value="false"; else new_value="true"; fi
            var_type="boolean"
            ;;
        string|"")
            # Строка — всегда допустима
            ;;
        *)
            _hv_err "Unknown type: $var_type (use: string, integer, boolean, toggle)"
            return 1
            ;;
    esac

    _hv_dbg "Writing '$var_name' as type '${var_type:-string}' with value '$new_value'"

    # Обновляем JSON строго по типу
    local ok=0
    case "${var_type:-string}" in
        integer)
            jq --arg k "$var_name" --argjson v "$new_value" '.[$k] = $v' "$CACHE_FILE" > "$CACHE_FILE.tmp" && ok=1
            ;;
        boolean)
            # new_value уже 'true' или 'false'
            jq --arg k "$var_name" --argjson v "$new_value" '.[$k] = $v' "$CACHE_FILE" > "$CACHE_FILE.tmp" && ok=1
            ;;
        string)
            jq --arg k "$var_name" --arg v "$new_value" '.[$k] = $v' "$CACHE_FILE" > "$CACHE_FILE.tmp" && ok=1
            ;;
    esac
    if [[ "$ok" -eq 1 ]]; then
        mv "$CACHE_FILE.tmp" "$CACHE_FILE"
    else
        rm -f "$CACHE_FILE.tmp"
        _hv_err "Failed to write JSON"
        return 1
    fi

    # Обновление Hyprland: значение — без кавычек
    # Пример: hyprctl keyword $keyboard_layout us
    hyprctl keyword "\$$var_name" "$new_value" -r >/dev/null 2>&1 || _hv_err "hyprctl keyword failed for '$var_name'"

    # Выводим «сырое» значение (без кавычек) — как ты просил
    printf '%s\n' "$new_value"
}

# --- CLI ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        get)  shift; get_variable "$1" ;;
        set)  shift; set_variable "$1" "$2" "$3" ;;
        *)
            echo "Usage:"
            echo "  $0 get <name>"
            echo "  $0 set <name> <value> [type=string|integer|boolean|toggle]"
            ;;
    esac
fi
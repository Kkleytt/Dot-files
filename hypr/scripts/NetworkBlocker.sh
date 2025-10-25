#!/usr/bin/env bash

set -euo pipefail

show_help() {
    cat <<EOF

Управление беспроводными интерфейсами через rfkill

Использование:
    $0 <block|unblock> <wifi|bluetooth|all>

Команды:
    block                               - отключить устройство
    unblock                            - включить устройство

Устройства:
    wifi                                - Wi-Fi
    bluetooth                           - Bluetooth
    all                                 - Все беспроводные интерфейсы

Примеры:
    $0 block wifi
    $0 unblock bluetooth
    $0 block all

Примечание:
  Для проводного LAN используйте \`ip\` или NetworkManager — rfkill его не поддерживает.

EOF
}

log() {
    local level="$1"; shift
    case "$level" in
        ok)    echo -e "${OK_ICON} ${GREEN}$*${RESET}" ;;
        err)   echo -e "${ERR_ICON} ${RED}$*${RESET}" >&2 ;;
        info)  echo -e "${HELP_ICON} ${BLUE}$*${RESET}" ;;
        warn)  echo -e "${ERR_ICON} ${YELLOW}$*${RESET}" >&2 ;;
    esac
}

normalize_device() {
    case "$1" in
        wifi) echo "wifi" ;;
        bluetooth|bt) echo "bluetooth" ;;
        all) echo "all" ;;
        *) echo "invalid" ;;
    esac
}

main() {
    if [ "$#" -eq 0 ] || [ "$1" = "help" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        show_help
        exit 0
    fi

    if [ "$#" -ne 2 ]; then
        log err "Неверное количество аргументов."
        log info "Используйте: $0 --help"
        exit 1
    fi

    local method="$1"
    local device_raw="$2"
    local device
    device="$(normalize_device "$device_raw")"

    if [ "$device" = "invalid" ]; then
        log err "Неизвестное устройство: '$device_raw'"
        log info "Допустимые: wifi, bluetooth, bt, all"
        exit 1
    fi

    if ! command -v rfkill >/dev/null 2>&1; then
        log err "Команда 'rfkill' не найдена. Установите пакет 'rfkill' или 'linux-firmware'."
        exit 1
    fi

    case "$method" in
        block)
            log info "Отключаю ${device}..."
            case "$device" in
                wifi)       rfkill block wifi ;;
                bluetooth)  rfkill block bluetooth ;;
                all)        rfkill block all ;;
            esac
            log ok "${device^} успешно отключён."
            ;;
        unblock)
            log info "Включаю ${device}..."
            case "$device" in
                wifi)       rfkill unblock wifi ;;
                bluetooth)  rfkill unblock bluetooth ;;
                all)        rfkill unblock all ;;
            esac
            log ok "${device^} успешно включён."
            ;;
        *)
            log err "Неизвестный метод: '$method'"
            log info "Используйте: block, unblock"
            exit 1
            ;;
    esac
}

main "$@"
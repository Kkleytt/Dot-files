# !/bin/bash
# ./hotkey.sh

ProjectDir="$HOME/.config/caelestia/cli/scripts"
MediaDir="$ProjectDir/media"
PeripheralsDir="$ProjectDir/peripherals"
CaelestiaDir="$ProjectDir/caelestia"
HyprDir="$ProjectDir/hyprland"

case "$1" in
  speaker|microphone|airplane|brightness|player|screenshot|screenrecord)
    exec "$MediaDir/$1/script.sh" "${@:2}" ;;
  mouse|touchpad|keyboard|touchscreen|wifi|bluetooth|clean)
    exec "$PeripheralsDir/$1/script.sh" "${@:2}" ;;
  panels|lock|shell|theme|services|watcher|rofi|init|dnd)
    exec "$CaelestiaDir/$1/script.sh" "${@:2}" ;;
  decorate|shadow|hyprapps|kill|idle|starship|window|codesnap|power|keyhint)
    exec "$HyprDir/$1/script.sh" "${@:2}" ;;
  *)
    echo "Error args" ;;
esac

#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##

# For Hyprlock
#pidof hyprlock || hyprlock -q 


case "$1" in
    "hyprlock")
        loginctl lock-session
        ;;
    "caelestia")
        hyprctl dispatch global "caelestia:lock"
        ;;
    "--dec")
        change_brightness "down" "$step"
        ;;
    "--cycle")
        cycle_brightness
        ;;
    *)
        get_brightness
        ;;
esac



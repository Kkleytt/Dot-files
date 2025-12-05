start_consumer() {
    cd "$HOME/.config/cealestia/cli/server"
    sleep 0.1
    source .venv/bin/activate
    sleep 0.5
    exec consumer
}

start_watcher() {
    cd "$HOME/.config/caelestia/cli/scripts"
    sleep 0.1
    exec ./hotkey.sh watcher
}

start_caelestia() {
    cd "$HOME/.config/caelestia/cli/scripts"
    sleep 0.1
    exec ./hotkey.sh shell enable
}

start_hypridle() {
    exec hypridle
}

start_hyprpaper() {
    exec hyprpaper
}

start_syncthing() {
    exec syncthing
}

sleep 10
start_caelestia &
sleep 1
start_watcher &
sleep 1
start_hyprpaper &
sleep 1
start_hypridle &
sleep 4
start_consumer &
sleep 1
start_syncthing &
sleep 1

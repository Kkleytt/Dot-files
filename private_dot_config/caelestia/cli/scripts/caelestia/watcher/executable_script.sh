scriptDir="$HOME/.config/caelestia/cli/scripts/caelestia/watcher/"

start_watcher() {
  cd $scriptDir 
  source .venv/bin/activate 
  python Watcher.py
}

start_watcher
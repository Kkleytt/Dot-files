#!/usr/bin/env bash
# notify-wrap: единая обёртка для уведомлений и "сворачивания" центра уведомлений.
# Поддерживает dunst и mako, мягко игнорирует их отсутствие.

cmd_exists() { command -v "$1" >/dev/null 2>&1; }

collapse_notifications() {
  if cmd_exists dunstctl; then dunstctl close-all || true; fi
  if cmd_exists makoctl; then makoctl dismiss -a || true; fi
}

notify() {
  # usage: notify "Title" "Body" [timeout_ms]
  local title="$1"; shift
  local body="${1:-}"; shift || true
  local timeout="${1:-3000}"
  notify-send -t "$timeout" "$title" "$body" || true
}

clipboard_copy_uri() {
  # usage: clipboard_copy_uri /absolute/path
  local path="$1"
  local uri="file://$path"
  if cmd_exists wl-copy; then
    printf '%s\n' "$uri" | wl-copy --type text/uri-list
  fi
}

clipboard_copy_filebytes() {
  # usage: clipboard_copy_filebytes /path mime
  local path="$1" mime="${2:-application/octet-stream}"
  if cmd_exists wl-copy; then
    wl-copy --type "$mime" < "$path"
  fi
}

"$@"

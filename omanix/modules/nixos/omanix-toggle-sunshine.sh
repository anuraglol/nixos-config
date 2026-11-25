sunshine_on() {
  systemctl --user start sunshine.service
  notify-send "Sunshine" "Streaming server started"
}

sunshine_off() {
  systemctl --user stop sunshine.service
  notify-send "Sunshine" "Streaming server stopped"
}

show_status() {
  if systemctl --user is-active sunshine.service >/dev/null 2>&1; then
    echo "on"
    exit 0
  else
    echo "off"
    exit 1
  fi
}

case "${1:-}" in
  --status) show_status ;;
  --on)     sunshine_on ;;
  --off)    sunshine_off ;;
  *)
    if systemctl --user is-active sunshine.service >/dev/null 2>&1; then
      sunshine_off
    else
      sunshine_on
    fi
    ;;
esac

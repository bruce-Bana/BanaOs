# Start the graphical desktop automatically on the local first virtual terminal.
# Keep SSH and alternate consoles in text mode for recovery.
if [ -z "${DISPLAY:-}" ] && [ -z "${SSH_CONNECTION:-}" ]; then
  current_tty="$(tty 2>/dev/null || true)"
  if [ "$current_tty" = "/dev/tty1" ]; then
    exec startx
  fi
fi

# Start X only on physical TTY1 login
if [[ -z $DISPLAY && $XDG_VTNR -eq 1 ]]; then
  startx
fi

#!/bin/bash
stty -echo 2>/dev/null || true
#wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.0
brightnessctl -q -e4 -n2 set 100%  
exec /opt/VeterDM/bin/crt-greeter.py
#aplay -q /var/lib/crt-greeter/mehanicheskaia-knopka-tv.wav

# После завершения скрипта – войти в обычную оболочку (опционально)
# exec $SHELL

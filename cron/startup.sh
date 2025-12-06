#!/bin/bash

id=1000 #$(id -u)
DISPLAY=':0.0'
# XDG_RUNTIME_DIR=/run/user/$id # Must be passed before command
DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$id/bus

/usr/bin/notify-send \
  --expire-time 4000 \
  --urgency normal \
  "STARTUP COMPLETE" \
  "I am $HOME/bin/cron/startup and I have been executed thanks to crontab @reboot $HOME/bin/startup.sh"

sleep 0.1
tput bel
sleep 0.5
tput bel
sleep 0.5
tput bel

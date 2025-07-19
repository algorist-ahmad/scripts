#!/bin/bash

id=1000 #$(id -u)
DISPLAY=':0.0'
# XDG_RUNTIME_DIR=/run/user/$id # Must be passed before command
DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$id/bus

/usr/bin/notify-send \
  --expire-time 3000 \
  --urgency critical "STARTUP COMPLETE" \
  "I am $HOME/bin/startup and I have been executed thanks to crontab @reboot $HOME/bin/startup.sh"

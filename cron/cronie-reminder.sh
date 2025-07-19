#!/bin/bash

id=$(id -u)
DISPLAY=':0.0'
DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$id/bus

/usr/bin/notify-send \
  --expire-time 2000 \
  "Cronie is running"

sleep 0.5
tput bel

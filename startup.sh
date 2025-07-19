#!/bin/bash

/usr/bin/notify-send --urgency critical "STARTUP COMPLETE" "I am $HOME/bin/startup and I have been executed thanks to crontab @reboot $HOME/bin/startup.sh"

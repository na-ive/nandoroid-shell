#!/usr/bin/fish

killall  qs quickshell

dbus-send --type=signal / org.freedesktop.DBus.NameOwnerChanged \
    string:"org.kde.StatusNotifierWatcher" string:"" string:""

sleep 2

nohup qs -c nandoroid > /dev/null 2>&1 &
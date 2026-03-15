#!/usr/bin/bash

# Kill existing quickshell instances
killall qs quickshell 2>/dev/null

# Clean up D-Bus name for System Tray
# Often kded6 or other services hold this name but don't provide the service, 
# preventing Quickshell from becoming the Tray Watcher.
WATCHER_PID=$(dbus-send --session --dest=org.freedesktop.DBus --type=method_call --print-reply /org/freedesktop/DBus org.freedesktop.DBus.GetConnectionUnixProcessID string:"org.kde.StatusNotifierWatcher" 2>/dev/null | grep uint32 | awk '{print $2}')

if [ ! -z "$WATCHER_PID" ]; then
    echo "Cleaning up zombie tray watcher (PID: $WATCHER_PID)..."
    kill -9 $WATCHER_PID 2>/dev/null
    sleep 0.5
fi

# Wait for old shell to truly die
sleep 1

# Start Quickshell in the background
nohup qs -c nandoroid > /dev/null 2>&1 &

# Small delay to let the shell initialize
sleep 2

# Force re-registration signal
dbus-send --type=signal / org.freedesktop.DBus.NameOwnerChanged \
    string:"org.kde.StatusNotifierWatcher" string:":1.dummy" string:":1.dummy2"

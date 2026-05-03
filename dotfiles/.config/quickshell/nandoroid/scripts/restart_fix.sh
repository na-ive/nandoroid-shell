#!/bin/bash

# Nandoroid Restart Fix Script
# Aggressively cleans up processes and re-registers the D-Bus Tray Watcher
# Used when notifications or the system tray disappear

# 1. Kill existing quickshell instances
killall qs quickshell 2>/dev/null
pkill -9 cava 2>/dev/null

# 2. Clean up D-Bus name for System Tray
# Often kded6 or other services hold this name but don't provide the service, 
# preventing Quickshell from becoming the Tray Watcher.
WATCHER_PID=$(dbus-send --session --dest=org.freedesktop.DBus --type=method_call --print-reply /org/freedesktop/DBus org.freedesktop.DBus.GetConnectionUnixProcessID string:"org.kde.StatusNotifierWatcher" 2>/dev/null | grep uint32 | awk '{print $2}')

if [ ! -z "$WATCHER_PID" ]; then
    echo "Cleaning up zombie tray watcher (PID: $WATCHER_PID)..."
    kill -9 $WATCHER_PID 2>/dev/null
    sleep 0.5
fi

# 3. Wait for old shell to truly die
sleep 1

# 4. Start Quickshell in the background
nohup quickshell -c nandoroid > /dev/null 2>&1 &

# 5. Small delay to let the shell initialize
sleep 2

# 6. Force re-registration signal
dbus-send --type=signal / org.freedesktop.DBus.NameOwnerChanged \
    string:"org.kde.StatusNotifierWatcher" string:":1.dummy" string:":1.dummy2"

exit 0

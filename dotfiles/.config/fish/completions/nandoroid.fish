# Fish completions for Nandoroid Shell IPC
# Auto-loaded by fish from ~/.config/fish/completions/

# Helper: check if we're completing after 'qs -c nandoroid ipc call'
function __nandoroid_ipc_needs_target
    set -l tokens (commandline -opc)
    # Match: qs -c nandoroid ipc call (no target yet)
    if test (count $tokens) -ge 5
        and test "$tokens[2]" = "-c"
        and test "$tokens[3]" = "nandoroid"
        and test "$tokens[4]" = "ipc"
        and test "$tokens[5]" = "call"
        and test (count $tokens) -eq 5
        return 0
    end
    return 1
end

function __nandoroid_ipc_needs_method
    set -l tokens (commandline -opc)
    # Match: qs -c nandoroid ipc call <target> (no method yet)
    if test (count $tokens) -ge 6
        and test "$tokens[2]" = "-c"
        and test "$tokens[3]" = "nandoroid"
        and test "$tokens[4]" = "ipc"
        and test "$tokens[5]" = "call"
        and test (count $tokens) -eq 6
        return 0
    end
    return 1
end

function __nandoroid_ipc_get_target
    set -l tokens (commandline -opc)
    if test (count $tokens) -ge 6
        echo $tokens[6]
    end
end

# Disable file completions for qs after ipc call
complete -c qs -n '__nandoroid_ipc_needs_target' -f

# IPC targets
complete -c qs -n '__nandoroid_ipc_needs_target' -a 'launcher' -d 'App Launcher'
complete -c qs -n '__nandoroid_ipc_needs_target' -a 'spotlight' -d 'Spotlight Search'
complete -c qs -n '__nandoroid_ipc_needs_target' -a 'notifications' -d 'Notification Center'
complete -c qs -n '__nandoroid_ipc_needs_target' -a 'quicksettings' -d 'Quick Settings'
complete -c qs -n '__nandoroid_ipc_needs_target' -a 'systemmonitor' -d 'System Monitor'
complete -c qs -n '__nandoroid_ipc_needs_target' -a 'overview' -d 'Overview Panel'
complete -c qs -n '__nandoroid_ipc_needs_target' -a 'session' -d 'Session (Power)'
complete -c qs -n '__nandoroid_ipc_needs_target' -a 'dashboard' -d 'Dashboard'
complete -c qs -n '__nandoroid_ipc_needs_target' -a 'settings' -d 'Nandoroid Settings'
complete -c qs -n '__nandoroid_ipc_needs_target' -a 'region' -d 'Region Tools (Screenshot/Record)'
complete -c qs -n '__nandoroid_ipc_needs_target' -a 'brightness' -d 'Brightness Control'
complete -c qs -n '__nandoroid_ipc_needs_target' -a 'pomodoro' -d 'Pomodoro Timer'
complete -c qs -n '__nandoroid_ipc_needs_target' -a 'wallpaper' -d 'Wallpaper Selector'
complete -c qs -n '__nandoroid_ipc_needs_target' -a 'osd' -d 'OSD Controls'

# Disable file completions for methods
complete -c qs -n '__nandoroid_ipc_needs_method' -f

# Methods per target
# Most panels: toggle
complete -c qs -n '__nandoroid_ipc_needs_method; and test (__nandoroid_ipc_get_target) = launcher' -a 'toggle' -d 'Toggle launcher'
complete -c qs -n '__nandoroid_ipc_needs_method; and test (__nandoroid_ipc_get_target) = spotlight' -a 'toggle' -d 'Toggle spotlight'
complete -c qs -n '__nandoroid_ipc_needs_method; and test (__nandoroid_ipc_get_target) = notifications' -a 'toggle' -d 'Toggle notification center'
complete -c qs -n '__nandoroid_ipc_needs_method; and test (__nandoroid_ipc_get_target) = quicksettings' -a 'toggle' -d 'Toggle quick settings'
complete -c qs -n '__nandoroid_ipc_needs_method; and test (__nandoroid_ipc_get_target) = systemmonitor' -a 'toggle' -d 'Toggle system monitor'
complete -c qs -n '__nandoroid_ipc_needs_method; and test (__nandoroid_ipc_get_target) = overview' -a 'toggle' -d 'Toggle overview'
complete -c qs -n '__nandoroid_ipc_needs_method; and test (__nandoroid_ipc_get_target) = session' -a 'toggle' -d 'Toggle session menu'
complete -c qs -n '__nandoroid_ipc_needs_method; and test (__nandoroid_ipc_get_target) = dashboard' -a 'toggle' -d 'Toggle dashboard'
complete -c qs -n '__nandoroid_ipc_needs_method; and test (__nandoroid_ipc_get_target) = settings' -a 'toggle' -d 'Toggle settings'

# Region: multiple methods
complete -c qs -n '__nandoroid_ipc_needs_method; and test (__nandoroid_ipc_get_target) = region' -a 'screenshot' -d 'Region screenshot'
complete -c qs -n '__nandoroid_ipc_needs_method; and test (__nandoroid_ipc_get_target) = region' -a 'search' -d 'Visual search'
complete -c qs -n '__nandoroid_ipc_needs_method; and test (__nandoroid_ipc_get_target) = region' -a 'ocr' -d 'Text OCR'
complete -c qs -n '__nandoroid_ipc_needs_method; and test (__nandoroid_ipc_get_target) = region' -a 'record' -d 'Record region'
complete -c qs -n '__nandoroid_ipc_needs_method; and test (__nandoroid_ipc_get_target) = region' -a 'recordWithSound' -d 'Record region with audio'

# Brightness
complete -c qs -n '__nandoroid_ipc_needs_method; and test (__nandoroid_ipc_get_target) = brightness' -a 'increment' -d 'Increase brightness'
complete -c qs -n '__nandoroid_ipc_needs_method; and test (__nandoroid_ipc_get_target) = brightness' -a 'decrement' -d 'Decrease brightness'

# Pomodoro
complete -c qs -n '__nandoroid_ipc_needs_method; and test (__nandoroid_ipc_get_target) = pomodoro' -a 'start' -d 'Start pomodoro'

# Wallpaper
complete -c qs -n '__nandoroid_ipc_needs_method; and test (__nandoroid_ipc_get_target) = wallpaper' -a 'openDesktop' -d 'Open desktop wallpaper picker'
complete -c qs -n '__nandoroid_ipc_needs_method; and test (__nandoroid_ipc_get_target) = wallpaper' -a 'openLock' -d 'Open lock wallpaper picker'

# OSD
complete -c qs -n '__nandoroid_ipc_needs_method; and test (__nandoroid_ipc_get_target) = osd' -a 'showBrightness' -d 'Show brightness OSD'

# Also complete the 'quickshell' command with same completions
complete -c quickshell -n '__nandoroid_ipc_needs_target' -f
complete -c quickshell -n '__nandoroid_ipc_needs_target' -a 'launcher spotlight notifications quicksettings systemmonitor overview session dashboard settings region brightness pomodoro wallpaper osd'
complete -c quickshell -n '__nandoroid_ipc_needs_method' -f

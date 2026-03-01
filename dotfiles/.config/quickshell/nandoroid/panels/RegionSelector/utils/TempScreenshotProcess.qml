import QtQuick
import Quickshell
import Quickshell.Io
import "../../../core"
import "../../../core/functions" as Functions

Process {
    id: screenshotProc
    running: true
    property string screenshotDir: Directories.screenshotTemp
    required property ShellScreen screen
    property string screenshotPath: `${screenshotDir}/image-${screen.name}`
    command: ["bash", "-c", `mkdir -p '${Functions.StringUtils.shellSingleQuoteEscape(screenshotDir)}' && grim -o '${Functions.StringUtils.shellSingleQuoteEscape(screen.name)}' '${Functions.StringUtils.shellSingleQuoteEscape(screenshotPath)}'`]
}

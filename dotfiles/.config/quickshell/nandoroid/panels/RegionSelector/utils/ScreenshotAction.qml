pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import QtQuick.Controls
import Quickshell
import "../../../core"
import "../../../core/functions" as Functions
import "../../../services"

Singleton {
    id: root

    enum Action {
        Copy,
        Edit,
        Search,
        CharRecognition,
        Record,
        RecordWithSound,
        RecordFullscreenWithSound
    }

    property string imageSearchEngineBaseUrl: Config.ready ? Config.options.search.imageSearch.imageSearchEngineBaseUrl : "https://lens.google.com/uploadbyurl?url="
    property string fileUploadApiEndpoint: "https://uguu.se/upload"

    function getCommand(x, y, width, height, screenshotPath, action, saveDir = "") {
        // Set command for action
        const rx = Math.round(x);
        const ry = Math.round(y);
        const rw = Math.round(width);
        const rh = Math.round(height);
        
        const shellEscape = Functions.StringUtils.shellSingleQuoteEscape;
        
        const cropBase = `magick ${shellEscape(screenshotPath)} `
            + `-crop ${rw}x${rh}+${rx}+${ry}`
        const cropToStdout = `${cropBase} -`
        const cropInPlace = `${cropBase} '${shellEscape(screenshotPath)}'`
        const cleanup = `rm '${shellEscape(screenshotPath)}'`
        const slurpRegion = `${rx},${ry} ${rw}x${rh}`
        
        const uploadAndGetUrl = (filePath) => {
            return `curl -sF files[]=@'${shellEscape(filePath)}' ${root.fileUploadApiEndpoint} | jq -r '.files[0].url'`
        }
        
        const useSatty = (Config.ready && Config.options.regionSelector && Config.options.regionSelector.annotation) 
            ? Config.options.regionSelector.annotation.useSatty 
            : false;
        const annotationCommand = `${useSatty ? "satty" : "swappy"} -f -`;
        const recordScript = Quickshell.shellPath("scripts/videos/record.sh");
        


        switch (action) {
            case ScreenshotAction.Action.Copy:
                if (saveDir === "") {
                    // not saving the screenshot, just copy to clipboard
                    return ["bash", "-c", `${cropToStdout} | wl-copy && ${cleanup}`]
                }
                return [
                    "bash", "-c",
                    `mkdir -p '${shellEscape(saveDir)}' && \
                    saveFileName="screenshot-$(date '+%Y-%m-%d_%H.%M.%S').png" && \
                    savePath="${saveDir}/$saveFileName" && \
                    ${cropToStdout} | tee >(wl-copy) > "$savePath" && \
                    ${cleanup}`
                ]

            case ScreenshotAction.Action.Edit:
                return ["bash", "-c", `${cropToStdout} | ${annotationCommand} && ${cleanup}`]
                
            case ScreenshotAction.Action.Search:
                const lensUrl = "https://lens.google.com/uploadbyurl?url=";
                const uploadCmd = `curl -sF "files[]=@${screenshotPath}" https://uguu.se/upload | jq -r '.files[0].url'`;
                return ["bash", "-c", `${cropInPlace} && IMG_LINK=$(${uploadCmd}) && [ -n "$IMG_LINK" ] && xdg-open "${lensUrl}$IMG_LINK" && ${cleanup}`]
                
            case ScreenshotAction.Action.CharRecognition:
                return ["bash", "-c", `${cropInPlace} && tesseract '${shellEscape(screenshotPath)}' stdout -l $(tesseract --list-langs | awk 'NR>1{print $1}' | tr '\\n' '+' | sed 's/\\+$/\\n/') | wl-copy && ${cleanup}`]
                
            case ScreenshotAction.Action.Record:
                return ["bash", "-c", `'${recordScript}' --region '${slurpRegion}'`]
                
            case ScreenshotAction.Action.RecordWithSound:
                return ["bash", "-c", `'${recordScript}' --region '${slurpRegion}' --sound`]
            
            case ScreenshotAction.Action.RecordFullscreenWithSound:
                return ["bash", "-c", `'${recordScript}' --fullscreen --sound`]
                
            default:

                return [];
        }
    }
}

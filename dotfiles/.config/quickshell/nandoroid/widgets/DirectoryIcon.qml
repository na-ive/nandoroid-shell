import QtQuick
import Quickshell
import Quickshell.Io
import "../core"
import "../core/functions"

/**
 * Directory and File icon component.
 * Resolves appropriate icons for folders and file types.
 */
Image {
    id: root
    required property var fileModelData
    asynchronous: true
    fillMode: Image.PreserveAspectFit

    source: {
        if (!fileModelData) return "";
        if (!fileModelData.fileIsDir)
            return Quickshell.iconPath("application-x-zerosize");

        const pictures = FileUtils.trimFileProtocol(Directories.pictures);
        const home = FileUtils.trimFileProtocol(Directories.home);
        
        if (fileModelData.filePath === pictures) return Quickshell.iconPath("folder-pictures");
        if (fileModelData.filePath === home) return Quickshell.iconPath("user-home");

        return Quickshell.iconPath("inode-directory");
    }

    onStatusChanged: {
        if (status === Image.Error)
            source = Quickshell.iconPath("error");
    }

    Process {
        running: fileModelData && !fileModelData.fileIsDir
        command: ["file", "--mime", "-b", fileModelData.filePath || ""]
        stdout: StdioCollector {
            onStreamFinished: {
                const mime = text.split(";")[0].replace("/", "-");
                const path = "file://" + root.fileModelData.filePath;
                root.source = (Images.validImageTypes.some(t => mime === `image-${t}`)) ? path : Quickshell.iconPath(mime, "image-missing");
            }
        }
    }
}

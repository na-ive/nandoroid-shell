import "../core"
import "../core/functions" as Functions
import "../services"
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

/**
 * Universal User Profile widget for sidebars.
 * Shows Avatar, Hostname, and Distribution info.
 */
Rectangle {
    id: root
    implicitWidth: parent.width
    implicitHeight: 72
    color: "transparent"
    
    property bool compact: false

    RowLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 14
        
        // Circular Avatar
        Item {
            id: avatarContainer
            width: 44; height: 44
            
            Image {
                id: avatarImage
                anchors.fill: parent
                source: {
                    const cfgPath = Config.options.bar?.avatar_path;
                    if (cfgPath && cfgPath !== "") return `file://${cfgPath}`;
                    const sysPath = SystemInfo.userAvatarPath;
                    if (!sysPath || sysPath.includes("/var/lib/AccountsService/icons/")) return "";
                    return `file://${sysPath}`;
                }
                fillMode: Image.PreserveAspectCrop
                visible: false // Hidden, shown via MultiEffect/OpacityMask
            }

            Rectangle {
                id: maskRect
                anchors.fill: parent
                radius: 22
                visible: false
            }

            OpacityMask {
                anchors.fill: parent
                source: avatarImage
                maskSource: maskRect
                visible: avatarImage.status === Image.Ready
            }
            
            MaterialSymbol {
                anchors.centerIn: parent
                visible: avatarImage.status !== Image.Ready
                text: "person"
                iconSize: 22
                color: Appearance.m3colors.m3onPrimaryContainer
            }
        }
        
        ColumnLayout {
            visible: !root.compact
            spacing: -2
            Layout.fillWidth: true

            StyledText {
                text: SystemInfo.hostname
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
                color: Appearance.m3colors.m3onSurface
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            StyledText {
                text: SystemInfo.distroName || "Linux System"
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }
}

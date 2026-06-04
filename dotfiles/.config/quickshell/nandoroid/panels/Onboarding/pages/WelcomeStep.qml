import "../../../core"
import "../../../widgets"
import "../../Settings/pages/WallpaperStyle"
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 24 * Appearance.effectiveScale

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8 * Appearance.effectiveScale

        StyledText {
            text: "Step 1: Wallpaper & Style"
            font.pixelSize: Appearance.font.pixelSize.larger
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer1
        }
        
        StyledText {
            text: "Let's start by personalizing your workspace. Choose a wallpaper and pick your favorite theme colors."
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colSubtext
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }

    // Embed the Wallpaper & Style Settings component
    // With isOnboarding = true, it hides unnecessary sections
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: "transparent"
        clip: true

        WallpaperStyleSettings {
            id: wsSettings
            anchors.fill: parent
            isOnboarding: true
        }

        // Scroll Hint
        RowLayout {
            id: scrollHint
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8 * Appearance.effectiveScale
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8 * Appearance.effectiveScale
            
            opacity: wsSettings.contentY < 20 ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
            
            SequentialAnimation on anchors.bottomMargin {
                loops: Animation.Infinite
                running: scrollHint.visible
                NumberAnimation { to: 16 * Appearance.effectiveScale; duration: 600; easing.type: Easing.OutSine }
                NumberAnimation { to: 8 * Appearance.effectiveScale; duration: 600; easing.type: Easing.InSine }
            }

            StyledText {
                text: "Scroll for more options"
                font.pixelSize: 14 * Appearance.effectiveScale
                color: Appearance.colors.colSubtext
            }
            MaterialSymbol {
                text: "arrow_downward"
                iconSize: 18 * Appearance.effectiveScale
                color: Appearance.colors.colSubtext
            }
        }
    }
}

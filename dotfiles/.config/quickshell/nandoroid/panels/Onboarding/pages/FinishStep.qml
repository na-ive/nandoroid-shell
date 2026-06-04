import "../../../core"
import "../../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 32 * Appearance.effectiveScale

        MaterialSymbol {
            Layout.alignment: Qt.AlignHCenter
            text: "task_alt" // A nice big checkmark
            iconSize: 120 * Appearance.effectiveScale
            color: Appearance.colors.colPrimary
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12 * Appearance.effectiveScale

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: "You're All Set!"
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.Bold
                color: Appearance.colors.colOnLayer1
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 640 * Appearance.effectiveScale
                text: "NAnDoroid is now fully configured and ready to use. Remember, you can always revisit this onboarding later from the Settings panel > About. Enjoy your new workspace!"
                font.pixelSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colSubtext
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.6
            }
        }
    }
}

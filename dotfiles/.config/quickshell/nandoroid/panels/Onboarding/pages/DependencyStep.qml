import "../../../core"
import "../../../widgets"
import "../../../services"
import "../../Settings/pages/About"
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 14 * Appearance.effectiveScale

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4 * Appearance.effectiveScale

        StyledText {
            text: I18nService.tr("Pre-requisite: Dependency Check")
            font.pixelSize: Appearance.font.pixelSize.larger
            font.family: Appearance.font.family.title
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer1
        }

        StyledText {
            text: I18nService.tr("Before we begin, let's make sure you have all necessary components installed. Same scanner as in Settings. Scan and install what is missing.")
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }

    StyledFlickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: contentCol.height + 16 * Appearance.effectiveScale
        clip: true

        ColumnLayout {
            id: contentCol
            width: parent.width

            AboutDependency {
                Layout.fillWidth: true
            }
        }
    }
}

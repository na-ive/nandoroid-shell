import "../../../core"
import "../../../widgets"
import "../../Settings/pages/About"
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
            text: "Pre-requisite: Dependency Check"
            font.pixelSize: Appearance.font.pixelSize.larger
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer1
        }
        
        StyledText {
            text: "Before we begin, let's make sure you have all the necessary components installed for NAnDoroid to function properly. You can scan and install missing dependencies here."
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colSubtext
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }

    StyledFlickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: contentCol.height + 24 * Appearance.effectiveScale
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

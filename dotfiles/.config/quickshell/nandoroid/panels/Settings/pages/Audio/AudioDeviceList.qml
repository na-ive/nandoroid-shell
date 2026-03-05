import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    property var model
    property bool isSink: true
    signal selected(var node)
    
    Layout.fillWidth: true
    implicitHeight: 300
    radius: 16
    color: Appearance.colors.colLayer1
    clip: true

    ListView {
        id: audioList
        anchors.fill: parent
        anchors.margins: 8
        model: parent.model
        spacing: 4
        clip: true

        delegate: RippleButton {
            id: audioItem
            width: audioList.width
            implicitHeight: 56
            buttonRadius: 12

            readonly property bool isActive: parent.parent.parent.isSink 
                ? (Audio.sink === modelData)
                : (Audio.source === modelData)

            colBackground: audioItem.isActive 
                ? Functions.ColorUtils.transparentize(Appearance.colors.colPrimary, 0.85) 
                : "transparent"
            
            onClicked: parent.parent.parent.parent.selected(modelData)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                MaterialSymbol {
                    text: {
                        if (!parent.parent.parent.parent.parent.isSink) return "mic"
                        const desc = modelData.description.toLowerCase()
                        if (desc.includes("headset") || desc.includes("headphone")) return "headphones"
                        if (desc.includes("hdmi") || desc.includes("tv")) return "tv"
                        return "speaker"
                    }
                    iconSize: 20
                    color: audioItem.isActive ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                }

                StyledText {
                    text: Audio.friendlyDeviceName(modelData)
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: audioItem.isActive ? Font.Bold : Font.Normal
                    color: Appearance.colors.colOnLayer1
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                MaterialSymbol {
                    visible: audioItem.isActive
                    text: "check"
                    iconSize: 20
                    color: Appearance.colors.colPrimary
                }
            }
        }
    }
}

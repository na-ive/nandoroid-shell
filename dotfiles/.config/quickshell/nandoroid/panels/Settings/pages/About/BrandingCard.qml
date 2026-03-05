import "../../../../core"
import "../../../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets

Rectangle {
    id: cardRoot
    property string title
    property string name
    property string subText
    property color accentColor
    property string icon
    property string logoSource: ""
    property bool isSystemIcon: false

    implicitHeight: 180
    radius: 24
    color: Appearance.m3colors.m3surfaceContainerHigh
    
    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: cardRoot.width
            height: cardRoot.height
            radius: cardRoot.radius
        }
    }

    // Decorative background (Android style)
    Rectangle {
        width: parent.width * 0.8
        height: width
        radius: width / 2
        color: accentColor
        opacity: 0.1
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: -parent.width * 0.2
        anchors.topMargin: -parent.width * 0.2
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 4

        StyledText {
            text: title
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
            font.weight: Font.Medium
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                StyledText {
                    text: name
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer1
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: 6
                    MaterialSymbol {
                        text: icon
                        iconSize: 16
                        color: accentColor
                    }
                    StyledText {
                        text: subText
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            // Distribution / Shell Logo
            Loader {
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64
                active: logoSource !== ""
                sourceComponent: isSystemIcon ? sysIconComp : localIconComp
                
                Component {
                    id: sysIconComp
                    IconImage {
                        source: Quickshell.iconPath(logoSource)
                        width: 64; height: 64
                    }
                }
                
                Component {
                    id: localIconComp
                    Image {
                        source: logoSource
                        width: 64; height: 64
                        sourceSize: Qt.size(128, 128) // Higher res for scaling
                        fillMode: Image.PreserveAspectFit
                        opacity: 0.8
                    }
                }
            }
        }
    }
}

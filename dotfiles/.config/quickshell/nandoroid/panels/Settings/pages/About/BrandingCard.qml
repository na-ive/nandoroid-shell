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

    implicitHeight: 180 * Appearance.effectiveScale
    radius: 24 * Appearance.effectiveScale
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
        anchors.margins: 20 * Appearance.effectiveScale
        spacing: 4 * Appearance.effectiveScale

        StyledText {
            text: title
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
            font.weight: Font.Medium
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12 * Appearance.effectiveScale

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4 * Appearance.effectiveScale

                StyledText {
                    text: name
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer1
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: 6 * Appearance.effectiveScale
                    MaterialSymbol {
                        text: icon
                        iconSize: 16 * Appearance.effectiveScale
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
                Layout.preferredWidth: 64 * Appearance.effectiveScale
                Layout.preferredHeight: 64 * Appearance.effectiveScale
                active: logoSource !== ""
                sourceComponent: isSystemIcon ? sysIconComp : localIconComp
                
                Component {
                    id: sysIconComp
                    IconImage {
                        source: Quickshell.iconPath(logoSource)
                        width: 64 * Appearance.effectiveScale; height: 64 * Appearance.effectiveScale
                    }
                }
                
                Component {
                    id: localIconComp
                    Image {
                        source: logoSource
                        width: 64 * Appearance.effectiveScale; height: 64 * Appearance.effectiveScale
                        sourceSize: Qt.size(128 * Appearance.effectiveScale, 128 * Appearance.effectiveScale) // Higher res for scaling
                        fillMode: Image.PreserveAspectFit
                        opacity: 0.8
                    }
                }
            }
        }
    }
}

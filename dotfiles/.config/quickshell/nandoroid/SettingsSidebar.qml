import "core"
import "core/functions" as Functions
import "widgets"
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

/**
 * Navigation sidebar for the Settings panel.
 * Uses a NavigationRail style common in modern Android apps.
 */
Rectangle {
    id: root
    implicitWidth: expanded ? 220 : 72
    color: Appearance.colors.colLayer0
    
    property bool expanded: true
    property int currentIndex: 0
    signal pageSelected(int index)

    Behavior on implicitWidth {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 16

        RippleButton {
            Layout.fillWidth: true
            implicitHeight: 48
            buttonRadius: 16
            colBackground: Appearance.colors.colPrimary
            colBackgroundHover: Appearance.colors.colPrimaryHover
            colRipple: Functions.ColorUtils.transparentize(Appearance.colors.colOnPrimary, 0.88)
            visible: root.expanded
            
            onClicked: {
                let path = Directories.shellConfigPath;
                if (!Qt.openUrlExternally("file://" + path)) {
                    Quickshell.execDetached(["xdg-open", path]);
                }
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 8
                MaterialSymbol {
                    text: "edit"
                    iconSize: 20
                    color: Appearance.colors.colOnPrimary
                }
                StyledText {
                    text: "Config file"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnPrimary
                }
            }
        }
        
        // Gap below config button
        Item { Layout.preferredHeight: 12 }
        
        // Icon for collapsed state
        MaterialSymbol {
            Layout.alignment: Qt.AlignHCenter
            text: "settings"
            iconSize: 24
            color: Appearance.colors.colPrimary
            visible: !root.expanded
        }

        // Navigation Items
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: [
                    { name: "Network", icon: "wifi" },
                    { name: "Bluetooth", icon: "bluetooth" },
                    { name: "Audio", icon: "volume_up" },
                    { name: "Display", icon: "monitor" },
                    { name: "Wallpaper & Style", icon: "palette" },
                    { name: "Services", icon: "cloud" },
                    { name: "About", icon: "info" }
                ]

                delegate: RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 48
                    buttonRadius: 16
                    colBackground: root.currentIndex === index 
                        ? Functions.ColorUtils.transparentize(Appearance.colors.colPrimary, 0.88)
                        : "transparent"
                    colBackgroundHover: root.currentIndex === index
                        ? colBackground
                        : Appearance.colors.colLayer0Hover
                    
                    onClicked: {
                        root.pageSelected(index)
                    }


                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: root.expanded ? 16 : 0
                        spacing: 16

                        MaterialSymbol {
                            Layout.alignment: Qt.AlignCenter
                            text: modelData.icon
                            iconSize: 24
                            color: root.currentIndex === index 
                                ? Appearance.colors.colPrimary 
                                : Appearance.colors.colSubtext
                        }

                        StyledText {
                            visible: root.expanded
                            Layout.fillWidth: true
                            text: modelData.name
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: root.currentIndex === index ? Font.Medium : Font.Normal
                            color: root.currentIndex === index 
                                ? Appearance.colors.colPrimary 
                                : Appearance.colors.colOnLayer0
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}

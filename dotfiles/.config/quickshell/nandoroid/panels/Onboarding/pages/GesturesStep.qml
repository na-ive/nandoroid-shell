import "../../../core"
import "../../../widgets"
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
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
            text: "Step 3: Desktop & Dock Gestures"
            font.pixelSize: Appearance.font.pixelSize.larger
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer1
        }
        
        StyledText {
            text: "NAnDoroid comes with powerful mouse and swipe gestures built-in. Let's learn how to navigate your desktop like a pro!"
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colSubtext
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }

    // ── Desktop Mockup ──
    Rectangle {
        id: mockupContainer
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Appearance.colors.colLayer0
        radius: 16 * Appearance.effectiveScale
        border.width: Math.max(1, 1 * Appearance.effectiveScale)
        border.color: Appearance.colors.colOutlineVariant
        
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: mockupContainer.width
                height: mockupContainer.height
                radius: 16 * Appearance.effectiveScale
            }
        }

        Image {
            anchors.fill: parent
            source: "file://" + Quickshell.env("HOME") + "/.local/src/nandoroid/dotfiles/.config/quickshell/nandoroid/assets/wallpapers/default_wallpaper.png"
            fillMode: Image.PreserveAspectCrop
            opacity: 0.3
        }

        // Gesture overlays
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24 * Appearance.effectiveScale
            spacing: 16 * Appearance.effectiveScale

            // Desktop Right Click
            RowLayout {
                spacing: 16 * Appearance.effectiveScale
                Rectangle {
                    width: 48 * Appearance.effectiveScale
                    height: 48 * Appearance.effectiveScale
                    radius: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "ads_click"
                        iconSize: 24 * Appearance.effectiveScale
                        color: Appearance.colors.colOnPrimary
                    }
                }
                ColumnLayout {
                    spacing: 4 * Appearance.effectiveScale
                    StyledText {
                        text: "Right Click Desktop"
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "Opens the Desktop Context Menu to quickly access Spotlight, Terminal, System Monitor, or change Wallpaper & Styles."
                        font.pixelSize: 12 * Appearance.effectiveScale
                        color: Appearance.colors.colSubtext
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // Desktop Swipe Up
            RowLayout {
                spacing: 16 * Appearance.effectiveScale
                Rectangle {
                    width: 48 * Appearance.effectiveScale
                    height: 48 * Appearance.effectiveScale
                    radius: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "swipe_up"
                        iconSize: 24 * Appearance.effectiveScale
                        color: Appearance.colors.colOnPrimary
                    }
                }
                ColumnLayout {
                    spacing: 4 * Appearance.effectiveScale
                    StyledText {
                        text: "Swipe Up on Desktop"
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "Opens the Launcher (App Drawer)."
                        font.pixelSize: 12 * Appearance.effectiveScale
                        color: Appearance.colors.colSubtext
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Item { Layout.fillHeight: true } // Spacer
            
            // Dock Right Click
            RowLayout {
                spacing: 16 * Appearance.effectiveScale
                Rectangle {
                    width: 48 * Appearance.effectiveScale
                    height: 48 * Appearance.effectiveScale
                    radius: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "ads_click"
                        iconSize: 24 * Appearance.effectiveScale
                        color: Appearance.colors.colOnPrimary
                    }
                }
                ColumnLayout {
                    spacing: 4 * Appearance.effectiveScale
                    StyledText {
                        text: "Right Click on the Dock"
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "Opens the Dock Context Menu to manage apps (Pin, Close, New Window) and perform system power actions."
                        font.pixelSize: 12 * Appearance.effectiveScale
                        color: Appearance.colors.colSubtext
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // Mock Dock at the bottom
            Rectangle {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                width: 200 * Appearance.effectiveScale
                height: 50 * Appearance.effectiveScale
                radius: 25 * Appearance.effectiveScale
                color: Appearance.colors.colLayer2
                opacity: 0.9
                
                Row {
                    anchors.centerIn: parent
                    spacing: 12 * Appearance.effectiveScale
                    Repeater {
                        model: 4
                        Rectangle {
                            width: 32 * Appearance.effectiveScale
                            height: 32 * Appearance.effectiveScale
                            radius: 16 * Appearance.effectiveScale
                            color: Appearance.colors.colPrimary
                            opacity: 0.8
                        }
                    }
                }
            }
        }
    }
}

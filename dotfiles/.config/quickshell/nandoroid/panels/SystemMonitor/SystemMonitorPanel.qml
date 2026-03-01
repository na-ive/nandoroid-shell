import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"

import "pages"

/**
 * High-fidelity System Monitor Panel for NAnDoroid.
 * Features:
 * - Real-time performance graphs (CPU, RAM, Network, Disk)
 * - Process management with right-click menu
 * - GPU statistics
 * - Navigation sidebar
 */
Scope {
    id: rootScope

    FloatingWindow {
        id: panelWindow
        
        visible: GlobalStates.systemMonitorOpen
        color: "transparent"

        title: "System Monitor"

        // Default native window size
        width: Math.min(1100, Appearance.sizes.screen.width * 0.75)
        height: Math.min(820, Appearance.sizes.screen.height * 0.85)

        // Main Panel Background
        Rectangle {
            id: root
            anchors.fill: parent
            color: Appearance.colors.colLayer0
            border.color: Appearance.colors.colLayer1
            border.width: 1
            clip: true

            focus: visible
            Keys.onEscapePressed: GlobalStates.systemMonitorOpen = false

            // Stop click propagation to backdrop
            MouseArea {
                anchors.fill: parent
                onClicked: (mouse) => mouse.accepted = true
            }


            // Reset tab to Performance (0) when closed
            Connections {
                target: GlobalStates
                function onSystemMonitorOpenChanged() {
                    if (!GlobalStates.systemMonitorOpen) {
                        root.currentIndex = 0;
                        GlobalStates.systemMonitorIndex = 0;
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                // ── Global Header ──
                Item {
                    id: headerWrapper
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52 // Reduced from 64

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 12
                        spacing: 20

                        StyledText {
                            text: "System Monitor"
                            font.pixelSize: Appearance.font.pixelSize.huge
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnLayer0
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Item { Layout.fillWidth: true } // Spacer

                        RippleButton {
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: 36
                            implicitHeight: 36
                            buttonRadius: 18
                            colBackground: "transparent"
                            onClicked: GlobalStates.systemMonitorOpen = false
                            
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "close"
                                iconSize: 22
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }
                }

                // ── Main Content Area (Sidebar + Pages) ──
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12
                    
                    // Side Navigation (Rounded card inside)
                    Rectangle {
                        id: sidebar
                        Layout.fillHeight: true
                        width: 240
                        color: Appearance.colors.colLayer1
                        radius: 20
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 8
                            
                            Repeater {
                                model: [
                                { name: "Performance", icon: "monitoring" },
                                { name: "Processes", icon: "list" }
                            ]
                            
                            delegate: RippleButton {
                                Layout.fillWidth: true
                                implicitHeight: 52
                                buttonRadius: 16
                                colBackground: GlobalStates.systemMonitorIndex === index 
                                    ? Functions.ColorUtils.transparentize(Appearance.colors.colPrimary, 0.85) 
                                    : "transparent"
                                colBackgroundHover: GlobalStates.systemMonitorIndex === index 
                                    ? colBackground 
                                    : Appearance.colors.colLayer2
                                
                                onClicked: GlobalStates.systemMonitorIndex = index
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    spacing: 16
                                    
                                    MaterialSymbol {
                                        text: modelData.icon
                                        iconSize: 24
                                        color: GlobalStates.systemMonitorIndex === index 
                                            ? Appearance.colors.colPrimary 
                                            : Appearance.colors.colSubtext
                                    }
                                    
                                    StyledText {
                                        text: modelData.name
                                        font.pixelSize: 15
                                        font.weight: GlobalStates.systemMonitorIndex === index ? Font.Bold : Font.Medium
                                        color: GlobalStates.systemMonitorIndex === index 
                                            ? Appearance.colors.colPrimary 
                                            : Appearance.colors.colOnLayer0
                                    }
                                }
                            }
                        }
                        
                        Item { Layout.fillHeight: true }
                        
                        // Bottom Profile info
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 72
                            radius: 20
                            color: "transparent"
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 4
                                spacing: 14
                                
                                // Circular Avatar
                                Rectangle {
                                    id: avatarContainer
                                    width: 48; height: 48; radius: 24
                                    color: Appearance.colors.colLayer2
                                    
                                    Image {
                                        id: avatarImage
                                        anchors.fill: parent
                                        source: "file://" + SystemInfo.userAvatarPath
                                        fillMode: Image.PreserveAspectCrop
                                        visible: status === Image.Ready
                                        
                                        layer.enabled: true
                                        layer.effect: OpacityMask {
                                            maskSource: Rectangle {
                                                width: avatarContainer.width
                                                height: avatarContainer.height
                                                radius: avatarContainer.radius
                                            }
                                        }
                                    }
                                    
                                    // Fallback
                                    StyledText {
                                        anchors.centerIn: parent
                                        visible: avatarImage.status !== Image.Ready
                                        text: SystemInfo.username.charAt(0).toUpperCase()
                                        color: Appearance.m3colors.m3onPrimaryContainer
                                        font.pixelSize: 18
                                        font.weight: Font.Black
                                    }
                                }
                                
                                ColumnLayout {
                                    spacing: 0
                                    StyledText {
                                        text: SystemInfo.hostname
                                        font.pixelSize: 15
                                        font.weight: Font.Bold
                                        color: Appearance.m3colors.m3onSurface
                                    }
                                    StyledText {
                                        text: "Up: " + SystemData.uptime
                                        font.pixelSize: 11
                                        color: Appearance.colors.colSubtext
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Main Content Area
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Appearance.colors.colLayer1
                    radius: 20
                    clip: true
                    
                    StackLayout {
                        anchors.fill: parent
                        currentIndex: GlobalStates.systemMonitorIndex
                        
                        PerformancePage {}
                        ProcessesPage {}
                    } // End contentContainer Loader
                } // End Main Content RowLayout
            } // End Global ColumnLayout
        } // End Main Panel Background Rectangle
    } // End FloatingWindow
} // End Scope
}

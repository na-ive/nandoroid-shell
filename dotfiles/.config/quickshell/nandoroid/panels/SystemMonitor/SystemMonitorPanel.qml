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
        implicitWidth: Math.min(1100 * Appearance.effectiveScale, Appearance.sizes.screen.width * 0.75)
        implicitHeight: Math.min(820 * Appearance.effectiveScale, Appearance.sizes.screen.height * 0.85)

        width: implicitWidth
        height: implicitHeight

        // Main Panel Background
        Rectangle {
            id: root
            property int currentIndex: 0
            anchors.fill: parent
            color: Appearance.colors.colLayer0
            border.color: Appearance.colors.colLayer1
            border.width: Math.max(1, 1 * Appearance.effectiveScale)
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

            // Auto-fallback if battery is removed/unavailable
            Connections {
                target: Battery
                function onAvailableChanged() {
                    if (!Battery.available && GlobalStates.systemMonitorIndex === 1) {
                        GlobalStates.systemMonitorIndex = 0;
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12 * Appearance.effectiveScale
                spacing: 12 * Appearance.effectiveScale

                // ── Global Header ──
                Item {
                    id: headerWrapper
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52 * Appearance.effectiveScale // Reduced from 64

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20 * Appearance.effectiveScale
                        anchors.rightMargin: 12 * Appearance.effectiveScale
                        spacing: 20 * Appearance.effectiveScale

                        StyledText {
                            text: "System Monitor"
                            font.pixelSize: 24 * Appearance.effectiveScale
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnLayer0
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Item { Layout.fillWidth: true } // Spacer

                        RippleButton {
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: 36 * Appearance.effectiveScale
                            implicitHeight: 36 * Appearance.effectiveScale
                            buttonRadius: 18 * Appearance.effectiveScale
                            colBackground: "transparent"
                            onClicked: GlobalStates.systemMonitorOpen = false
                            
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "close"
                                iconSize: 22 * Appearance.effectiveScale
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }
                }

                // ── Main Content Area (Sidebar + Pages) ──
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12 * Appearance.effectiveScale
                    
                    // Side Navigation (Matching SettingsSidebar style)
                    Rectangle {
                        id: sidebar
                        Layout.fillHeight: true
                        Layout.preferredWidth: 220 * Appearance.effectiveScale
                        Layout.fillWidth: false
                        color: Appearance.colors.colLayer0
                        radius: 20 * Appearance.effectiveScale
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            
                            // Navigation Items
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8 * Appearance.effectiveScale
                                
                                Repeater {
                                    model: [
                                        { name: "Performance", icon: "monitoring", stackIndex: 0 },
                                        { name: "Battery", icon: "battery_charging_full", stackIndex: 1, visible: Battery.available },
                                        { name: "Processes", icon: "list", stackIndex: 2 }
                                    ]
                                    
                                    delegate: RippleButton {
                                        visible: modelData.visible !== false
                                        Layout.fillWidth: true
                                        implicitHeight: visible ? 48 * Appearance.effectiveScale : 0
                                        buttonRadius: 16 * Appearance.effectiveScale
                                        colBackground: GlobalStates.systemMonitorIndex === modelData.stackIndex 
                                            ? Functions.ColorUtils.transparentize(Appearance.colors.colPrimary, 0.88) 
                                            : "transparent"
                                        colBackgroundHover: GlobalStates.systemMonitorIndex === modelData.stackIndex 
                                            ? colBackground 
                                            : Appearance.colors.colLayer0Hover
                                        
                                        onClicked: GlobalStates.systemMonitorIndex = modelData.stackIndex
                                        
                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16 * Appearance.effectiveScale
                                            spacing: 16 * Appearance.effectiveScale
                                            Layout.alignment: Qt.AlignLeft
                                            
                                            MaterialSymbol {
                                                text: modelData.icon
                                                iconSize: 24 * Appearance.effectiveScale
                                                color: GlobalStates.systemMonitorIndex === modelData.stackIndex 
                                                    ? Appearance.colors.colPrimary 
                                                    : Appearance.colors.colSubtext
                                            }
                                            
                                            StyledText {
                                                text: modelData.name
                                                font.pixelSize: 14 * Appearance.effectiveScale
                                                font.weight: GlobalStates.systemMonitorIndex === modelData.stackIndex ? Font.Medium : Font.Normal
                                                color: GlobalStates.systemMonitorIndex === modelData.stackIndex 
                                                    ? Appearance.colors.colPrimary 
                                                    : Appearance.colors.colOnLayer0
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignLeft
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Item { Layout.fillHeight: true }
                            
                            // Bottom Profile info (Using universal widget)
                            UserProfile {
                                compact: false
                                Layout.fillWidth: true
                            }
                        }
                    }
                
                // Main Content Area
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Appearance.colors.colLayer1
                    radius: 20 * Appearance.effectiveScale
                    clip: true
                    
                    StackLayout {
                        anchors.fill: parent
                        currentIndex: GlobalStates.systemMonitorIndex
                        
                        PerformancePage {}
                        BatteryPage { visible: Battery.available }
                        ProcessesPage {}
                    } // End contentContainer Loader
                } // End Main Content RowLayout
            } // End Global ColumnLayout
        } // End Main Panel Background Rectangle
    } // End FloatingWindow
} // End Scope
}

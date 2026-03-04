import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import "."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

/**
 * Functional Network Settings page.
 * Provides WiFi scanning, listing, and connection management.
 */
Item {
    id: root

    property string currentView: "main" // "main", "saved", or "wired"

    onVisibleChanged: {
        if (visible) Network.update()
        else root.currentView = "main"
    }
    
    // Reset scroll when changing views
    onCurrentViewChanged: {
        mainFlicking.contentY = 0
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 24

        // ── Header ──
        ColumnLayout {
            spacing: 4
            Layout.fillWidth: true
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Back Button (only in sub-pages)
                RippleButton {
                    visible: root.currentView !== "main"
                    implicitWidth: 40
                    implicitHeight: 40
                    buttonRadius: 20
                    colBackground: Appearance.colors.colLayer1
                    onClicked: root.currentView = "main"
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "arrow_back"
                        iconSize: 24
                        color: Appearance.colors.colOnLayer1
                    }
                }

                StyledText {
                    text: {
                        if (root.currentView === "main") return "Network & Internet"
                        if (root.currentView === "saved") return "Saved Networks"
                        if (root.currentView === "wired") return "Wired Network"
                        return "Network"
                    }
                    font.pixelSize: Appearance.font.pixelSize.huge
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }
                
                RowLayout {
                    visible: root.currentView === "main"
                    spacing: 12
                    
                    // Refresh Button
                    RippleButton {
                        implicitWidth: 40
                        implicitHeight: 40
                        buttonRadius: 20
                        colBackground: Appearance.colors.colLayer1
                        onClicked: Network.rescanWifi()
                        
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "refresh"
                            iconSize: 20
                            color: Appearance.colors.colOnLayer1
                            
                            RotationAnimation on rotation {
                                id: refreshAnim
                                from: 0
                                to: 360
                                duration: 1000
                                loops: Animation.Infinite
                                running: Network.wifiScanning
                            }
                        }
                    }

                    // Add Network Button
                    RippleButton {
                        implicitWidth: 40
                        implicitHeight: 40
                        buttonRadius: 20
                        colBackground: Appearance.colors.colLayer1
                        onClicked: addNetworkDialog.open()
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "add"
                            iconSize: 20
                            color: Appearance.colors.colOnLayer1
                        }
                    }

                    // Global WiFi Toggle
                    Rectangle {
                        implicitWidth: 52
                        implicitHeight: 28
                        radius: 14
                        color: Network.wifiEnabled
                            ? Appearance.colors.colPrimary
                            : Appearance.colors.colLayer2

                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            x: Network.wifiEnabled ? parent.width - width - 4 : 4
                            color: Network.wifiEnabled
                                ? Appearance.colors.colOnPrimary
                                : Appearance.colors.colSubtext
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Network.toggleWifi()
                        }
                    }
                }
            }
            StyledText {
                text: {
                    if (root.currentView === "main") return "Manage your WiFi networks, Ethernet, and connectivity."
                    if (root.currentView === "saved") return "Manage and forget your saved WiFi networks."
                    if (root.currentView === "wired") return "Manage your wired ethernet connections."
                    return ""
                }
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
            }
        }

        // ── Scrollable Content Area ──
        Flickable {
            id: mainFlicking
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentCol.implicitHeight
            clip: true
            interactive: true

            ScrollBar.vertical: ScrollBar {}

            ColumnLayout {
                id: contentCol
                width: parent.width
                spacing: 24

                NetworkMainView {
                    id: mainViewCol
                    Layout.fillWidth: true
                    visible: root.currentView === "main"
                }
                NetworkSavedView {
                    id: savedViewCol
                    Layout.fillWidth: true
                    visible: root.currentView === "saved"
                }
                NetworkWiredView {
                    id: wiredViewCol
                    Layout.fillWidth: true
                    visible: root.currentView === "wired"
                }
            }
        } // End Flickable

        // ── Bottom Management Buttons (Main View) ──
        RowLayout {
            id: bottomManagementRow
            Layout.fillWidth: true
            Layout.margins: 16
            Layout.topMargin: 0
            spacing: 12
            visible: root.currentView === "main"

            RippleButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                buttonRadius: 16
                colBackground: Appearance.colors.colLayer1
                onClicked: root.currentView = "wired"
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    MaterialSymbol {
                        text: "lan"
                        iconSize: 20
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "Wired Network"
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }
            }

            RippleButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                buttonRadius: 16
                colBackground: Appearance.colors.colLayer1
                onClicked: root.currentView = "saved"
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    MaterialSymbol {
                        text: "history"
                        iconSize: 20
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "Saved Networks"
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }
            }
        }
    } // End root ColumnLayout

    NetworkAddDialog {
        id: addNetworkDialog
    }
}

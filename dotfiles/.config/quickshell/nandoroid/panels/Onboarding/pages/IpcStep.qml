import "../../../core"
import "../../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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
            text: "Step 4: Command Line & IPC Integration"
            font.pixelSize: Appearance.font.pixelSize.larger
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer1
        }

        StyledText {
            text: "NAnDoroid is highly scriptable. Here is the full list of IPC Commands available to bind in your Window Manager. Try running them directly below!"
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colSubtext
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }

    // Tutorial Block
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: tutorialLayout.implicitHeight + 32 * Appearance.effectiveScale
        color: Appearance.colors.colLayer0
        radius: 12 * Appearance.effectiveScale
        border.width: Math.max(1, 1 * Appearance.effectiveScale)
        border.color: Appearance.colors.colOutlineVariant
        
        ColumnLayout {
            id: tutorialLayout
            anchors.fill: parent
            anchors.margins: 16 * Appearance.effectiveScale
            spacing: 8 * Appearance.effectiveScale
            
            StyledText {
                text: "How to bind in Window Managers (Example: Hyprland Lua)"
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer0
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 40 * Appearance.effectiveScale
                color: Appearance.colors.colLayer2
                radius: 8 * Appearance.effectiveScale
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12 * Appearance.effectiveScale
                    
                    StyledText {
                        Layout.fillWidth: true
                        text: 'hl.bind("SUPER + I", hl.dsp.exec_cmd("quickshell -c nandoroid ipc call settings toggle"))'
                        font.family: "monospace"
                        font.pixelSize: 12 * Appearance.effectiveScale
                        color: Appearance.colors.colPrimary
                    }
                }
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        StyledFlickable {
            id: ipcFlickable
            anchors.fill: parent
            contentHeight: contentLayout.height
            clip: true

            ColumnLayout {
                id: contentLayout
                width: parent.width
                spacing: 24 * Appearance.effectiveScale

                Repeater {
                    model: [
                        {
                            category: "Sidebar & Panels",
                            items: [
                                { name: "App Launcher", cmd: "quickshell -c nandoroid ipc call launcher toggle", target: "launcher", method: "toggle" },
                                { name: "Spotlight Search", cmd: "quickshell -c nandoroid ipc call spotlight toggle", target: "spotlight", method: "toggle" },
                                { name: "Notification Center", cmd: "quickshell -c nandoroid ipc call notifications toggle", target: "notifications", method: "toggle" },
                                { name: "Quick Settings", cmd: "quickshell -c nandoroid ipc call quicksettings toggle", target: "quicksettings", method: "toggle" },
                                { name: "System Monitor", cmd: "quickshell -c nandoroid ipc call systemmonitor toggle", target: "systemmonitor", method: "toggle" },
                                { name: "Overview Panel", cmd: "quickshell -c nandoroid ipc call overview toggle", target: "overview", method: "toggle" },
                                { name: "Session (Power)", cmd: "quickshell -c nandoroid ipc call session toggle", target: "session", method: "toggle" },
                                { name: "Dashboard", cmd: "quickshell -c nandoroid ipc call dashboard toggle", target: "dashboard", method: "toggle" },
                                { name: "Quick Actions", cmd: "quickshell -c nandoroid ipc call quickactions toggle", target: "quickactions", method: "toggle" },
                                { name: "Nandoroid Settings", cmd: "quickshell -c nandoroid ipc call settings toggle", target: "settings", method: "toggle" }
                            ]
                        },
                        {
                            category: "Region Tools",
                            items: [
                                { name: "Region Screenshot", cmd: "quickshell -c nandoroid ipc call region screenshot", target: "region", method: "screenshot" },
                                { name: "Visual Search", cmd: "quickshell -c nandoroid ipc call region search", target: "region", method: "search" },
                                { name: "Text OCR", cmd: "quickshell -c nandoroid ipc call region ocr", target: "region", method: "ocr" },
                                { name: "QR Code Scan", cmd: "quickshell -c nandoroid ipc call region qrcode", target: "region", method: "qrcode" },
                                { name: "Record Region", cmd: "quickshell -c nandoroid ipc call region record", target: "region", method: "record" },
                                { name: "Record w/ Audio", cmd: "quickshell -c nandoroid ipc call region recordWithSound", target: "region", method: "recordWithSound" }
                            ]
                        },
                        {
                            category: "Media, System & Others",
                            items: [
                                { name: "Brightness +", cmd: "quickshell -c nandoroid ipc call brightness increment", target: "brightness", method: "increment" },
                                { name: "Brightness -", cmd: "quickshell -c nandoroid ipc call brightness decrement", target: "brightness", method: "decrement" },
                                { name: "Start Pomodoro", cmd: "quickshell -c nandoroid ipc call pomodoro start", target: "pomodoro", method: "start" },
                                { name: "Pause Pomodoro", cmd: "quickshell -c nandoroid ipc call pomodoro pause", target: "pomodoro", method: "pause" },
                                { name: "Stop Pomodoro", cmd: "quickshell -c nandoroid ipc call pomodoro stop", target: "pomodoro", method: "stop" },
                                { name: "Reset Pomodoro", cmd: "quickshell -c nandoroid ipc call pomodoro reset", target: "pomodoro", method: "reset" },
                                { name: "Open Desktop Wallpaper", cmd: "quickshell -c nandoroid ipc call wallpaper openDesktop", target: "wallpaper", method: "openDesktop" },
                                { name: "Open Lock Wallpaper", cmd: "quickshell -c nandoroid ipc call wallpaper openLock", target: "wallpaper", method: "openLock" }
                            ]
                        }
                    ]

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12 * Appearance.effectiveScale

                        StyledText {
                            text: modelData.category
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer1
                            font.pixelSize: 14 * Appearance.effectiveScale
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: 16 * Appearance.effectiveScale
                            rowSpacing: 16 * Appearance.effectiveScale

                            Repeater {
                                model: modelData.items

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 72 * Appearance.effectiveScale
                                    color: Appearance.colors.colLayer0
                                    radius: 12 * Appearance.effectiveScale
                                    border.width: Math.max(1, 1 * Appearance.effectiveScale)
                                    border.color: Appearance.colors.colOutlineVariant

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12 * Appearance.effectiveScale
                                        spacing: 12 * Appearance.effectiveScale

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 4 * Appearance.effectiveScale

                                            StyledText {
                                                text: modelData.name
                                                font.weight: Font.DemiBold
                                                color: Appearance.colors.colOnLayer0
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                            StyledText {
                                                text: modelData.cmd
                                                font.pixelSize: 11 * Appearance.effectiveScale
                                                font.family: "monospace"
                                                color: Appearance.colors.colSubtext
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                        }

                                        // Copy Button
                                        Rectangle {
                                            width: 32 * Appearance.effectiveScale
                                            height: 32 * Appearance.effectiveScale
                                            radius: 16 * Appearance.effectiveScale
                                            color: "transparent"
                                            border.width: 1 * Appearance.effectiveScale
                                            border.color: copyMouse.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                                            
                                            MaterialSymbol {
                                                anchors.centerIn: parent
                                                text: "content_copy"
                                                iconSize: 16 * Appearance.effectiveScale
                                                color: copyMouse.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                                            }
                                            MouseArea {
                                                id: copyMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    Quickshell.execDetached(["wl-copy", modelData.cmd])
                                                    Quickshell.execDetached(["notify-send", "-a", "NAnDoroid", "-i", "edit-copy", "Copied", "IPC Command copied to clipboard!"])
                                                }
                                            }
                                        }

                                        // Run Button
                                        RippleButton {
                                            implicitWidth: 64 * Appearance.effectiveScale
                                            implicitHeight: 32 * Appearance.effectiveScale
                                            buttonRadius: 16 * Appearance.effectiveScale
                                            colBackground: Appearance.colors.colPrimary
                                            onClicked: {
                                                Quickshell.execDetached(["quickshell", "-c", "nandoroid", "ipc", "call", modelData.target, modelData.method])
                                            }
                                            StyledText {
                                                anchors.centerIn: parent
                                                text: "Run"
                                                font.weight: Font.DemiBold
                                                color: Appearance.colors.colOnPrimary
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } 
        

    }
}

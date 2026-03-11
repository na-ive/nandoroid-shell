import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../.."
import "../../../core"
import "../../../core/functions" as Functions
import "../../../services"
import "../../../widgets"
import ".."
import Quickshell
import Quickshell.Io

/**
 * Processes page for the System Monitor.
 * Displays a list of running processes with the ability to kill them.
 */
Item {
    id: root

    property string sortField: "cpu"
    property bool sortAscending: false


    readonly property var sortedProcesses: {
        let procs = SystemData.allProcesses.slice();
        procs.sort((a, b) => {
            let valA = a[sortField];
            let valB = b[sortField];
            if (typeof valA === "string") {
                valA = valA.toLowerCase();
                valB = valB.toLowerCase();
            }
            if (valA < valB) return sortAscending ? -1 : 1;
            if (valA > valB) return sortAscending ? 1 : -1;
            return 0;
        });
        return procs;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: "Processes"
                font.pixelSize: 24
                font.weight: Font.Bold
                color: Appearance.m3colors.m3onSurface
            }
            Item { Layout.fillWidth: true }
            StyledText {
                text: SystemData.processCount + " total processes"
                font.pixelSize: 12
                color: Appearance.colors.colSubtext
            }
        }

        // Header
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 40
            color: Appearance.colors.colLayer1
            radius: 8
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12
                
                HeaderItem { text: "PID"; field: "pid"; Layout.preferredWidth: 60 }
                HeaderItem { text: "Name"; field: "command"; Layout.fillWidth: true }
                HeaderItem { text: "CPU %"; field: "cpu"; Layout.preferredWidth: 80; alignment: Text.AlignRight }
                HeaderItem { text: "Memory"; field: "memoryKB"; Layout.preferredWidth: 100; alignment: Text.AlignRight }
                HeaderItem { text: "User"; field: "username"; Layout.preferredWidth: 100; alignment: Text.AlignRight }
            }
        }

        // Process List
        ListView {
            id: processList
            Layout.fillWidth: true
            Layout.fillHeight: true
            // ScriptModel diffs by pid — only adds/removes changed rows,
            // so the ListView never resets contentY on data refresh.
            model: ScriptModel {
                values: root.sortedProcesses
                objectProp: "pid"
            }
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: 0
            spacing: 6
            
            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width
                implicitHeight: 44
                radius: 12
                color: mouseArea.containsMouse ? Appearance.colors.colLayer2 : Appearance.colors.colLayer1
                border.color: mouseArea.containsMouse ? Appearance.m3colors.m3primary : Functions.ColorUtils.transparentize(Appearance.m3colors.m3primary, 0.85)
                border.width: 1
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12
                    
                    StyledText { text: modelData.pid; Layout.preferredWidth: 60; color: Appearance.colors.colSubtext }
                    StyledText { text: modelData.command; Layout.fillWidth: true; elide: Text.ElideRight; font.weight: Font.Medium }
                    StyledText { text: modelData.cpu.toFixed(1) + "%"; Layout.preferredWidth: 80; horizontalAlignment: Text.AlignRight }
                    StyledText { text: (modelData.memoryKB / 1024).toFixed(1) + " MB"; Layout.preferredWidth: 100; horizontalAlignment: Text.AlignRight }
                    StyledText { text: modelData.username; Layout.preferredWidth: 100; elide: Text.ElideRight; horizontalAlignment: Text.AlignRight }
                }
                
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            processMenu.targetPid = modelData.pid;
                            processMenu.targetName = modelData.command;
                            processMenu.popup();
                        }
                    }
                }
            }
        }
    }

    // Context Menu
    Menu {
        id: processMenu
        property int targetPid: 0
        property string targetName: ""
        
        Process {
            id: actionProc
        }

        background: Rectangle {
            implicitWidth: Appearance.sizes.contextMenuWidth
            color: Appearance.colors.colLayer0
            opacity: 0.98
            radius: Appearance.rounding.normal
            border.color: Appearance.colors.colOutlineVariant
            border.width: 1
        }

        component StyledMenuItem: MenuItem {
            id: menuItem
            
            implicitHeight: Appearance.sizes.contextMenuItemHeight
            
            contentItem: RowLayout {
                spacing: 12
                MaterialSymbol {
                    text: {
                        if (menuItem.text.includes("Kill")) return "delete_forever";
                        if (menuItem.text.includes("Stop")) return "pause";
                        if (menuItem.text.includes("Continue")) return "play_arrow";
                        if (menuItem.text.includes("Close")) return "close";
                        if (menuItem.text.includes("Copy")) return "content_copy";
                        return "info";
                    }
                    iconSize: Appearance.sizes.iconSize * 0.9
                    color: menuItem.highlighted ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer0
                }
                StyledText {
                    text: menuItem.text
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: menuItem.highlighted ? Font.Medium : Font.Normal
                    color: menuItem.highlighted ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer0
                    Layout.fillWidth: true
                }
            }
            
            background: Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                color: menuItem.highlighted ? Functions.ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.12) : "transparent"
                radius: Appearance.rounding.small
            }
        }
        
        padding: 6

        StyledMenuItem {
            text: "Stop (Pause)"
            onTriggered: { actionProc.command = ["kill", "-STOP", processMenu.targetPid.toString()]; actionProc.running = true; }
        }
        StyledMenuItem {
            text: "Continue"
            onTriggered: { actionProc.command = ["kill", "-CONT", processMenu.targetPid.toString()]; actionProc.running = true; }
        }
        
        MenuSeparator {
            contentItem: Rectangle { 
                implicitHeight: 1 
                color: Appearance.colors.colOutlineVariant 
                opacity: 0.3
                Layout.leftMargin: 12 
                Layout.rightMargin: 12 
            }
        }

        StyledMenuItem {
            text: "Kill (Force)"
            onTriggered: { actionProc.command = ["kill", "-9", processMenu.targetPid.toString()]; actionProc.running = true; }
        }
        
        StyledMenuItem {
            text: "Close (Graceful)"
            onTriggered: { actionProc.command = ["kill", processMenu.targetPid.toString()]; actionProc.running = true; }
        }

        MenuSeparator {
            contentItem: Rectangle { 
                implicitHeight: 1 
                color: Appearance.colors.colOutlineVariant 
                opacity: 0.3
                Layout.leftMargin: 12 
                Layout.rightMargin: 12 
            }
        }

        StyledMenuItem {
            text: "Copy PID"
            onTriggered: Quickshell.clipboardText = processMenu.targetPid.toString()
        }
    }

    // Helper for Header Items
    component HeaderItem: MouseArea {
        property string text
        property string field
        property int alignment: Text.AlignLeft
        
        Layout.fillHeight: true
        hoverEnabled: true
        
        onClicked: {
            if (root.sortField === field) {
                root.sortAscending = !root.sortAscending;
            } else {
                root.sortField = field;
                root.sortAscending = false;
            }
        }
        
        RowLayout {
            anchors.fill: parent
            spacing: 4
            layoutDirection: alignment === Text.AlignRight ? Qt.RightToLeft : Qt.LeftToRight
            
            StyledText {
                text: parent.parent.text
                font.pixelSize: 12
                font.weight: Font.Bold
                color: root.sortField === parent.parent.field ? Appearance.m3colors.m3primary : Appearance.colors.colSubtext
                Layout.fillWidth: true
                horizontalAlignment: parent.parent.alignment
            }
            MaterialSymbol {
                visible: root.sortField === parent.parent.field
                text: root.sortAscending ? "arrow_upward" : "arrow_downward"
                iconSize: 12
                color: Appearance.m3colors.m3primary
            }
        }
    }
}

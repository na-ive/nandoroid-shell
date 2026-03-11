import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Io

ColumnLayout {
    id: updateRoot
    spacing: 24

    FileView {
        id: installStateView
        path: Directories.home.replace("file://", "") + "/.config/nandoroid/install_state.json"
        watchChanges: true
        JsonAdapter {
            id: installState
            property bool inject: false
            property string install_dir: ""
            property string channel: "stable"
        }
    }

    // --- 1. Channel Selector ---
    SegmentedWrapper {
        Layout.fillWidth: true
        implicitHeight: channelRow.implicitHeight + 40
        orientation: Qt.Vertical
        maxRadius: 20
        color: Appearance.m3colors.m3surfaceContainerHigh
        
        RowLayout {
            id: channelRow
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            ColumnLayout {
                spacing: 2
                StyledText {
                    text: "Update Channel"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    text: "Choose between Stable (Tags) and Canary (Commits)."
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
            }
            
            Item { Layout.fillWidth: true }
            
            RowLayout {
                spacing: 4
                Layout.preferredHeight: 52
                Layout.alignment: Qt.AlignRight
                
                Repeater {
                    model: [
                        { label: "Stable", value: "stable" },
                        { label: "Canary", value: "canary" }
                    ]
                    delegate: SegmentedButton {
                        isHighlighted: installState.channel === modelData.value
                        Layout.fillHeight: true
                        
                        buttonText: modelData.label
                        leftPadding: 32
                        rightPadding: 32
                        
                        colActive: Appearance.m3colors.m3primary
                        colActiveText: Appearance.m3colors.m3onPrimary
                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                        
                        onClicked: {
                            installState.channel = modelData.value;
                            installStateView.writeAdapter();
                            checkUpdateCollector.clear()
                            gitLogProc.running = false
                            gitTagProc.running = false
                            gitLogProc.running = true
                            gitTagProc.running = true
                        }
                    }
                }
            }
        }
    }

    // --- 2. Check for Updates Status Row ---
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 80
        radius: 20
        color: Appearance.m3colors.m3surfaceContainerHigh
        visible: installState.install_dir !== ""
        
        Process {
            id: checkUpdateProc
            command: ["bash", "-c", `
                cd '${installState.install_dir}' || exit
                if [ '${installState.channel}' = 'stable' ]; then
                    git fetch --tags >/dev/null 2>&1
                    LATEST=$(git describe --tags $(git rev-list --tags --max-count=1 2>/dev/null) 2>/dev/null)
                    if [ -z "$LATEST" ]; then echo "Up to date"; exit 0; fi
                    
                    LOCAL_COMMIT=$(git rev-parse HEAD 2>/dev/null)
                    TAG_COMMIT=$(git rev-list -n 1 "$LATEST" 2>/dev/null)
                    
                    if [ "$LOCAL_COMMIT" != "$TAG_COMMIT" ]; then 
                        echo "Switch Available: $LATEST"
                    else 
                        echo "Up to date"
                    fi
                else
                    git fetch origin main >/dev/null 2>&1
                    LOCAL=$(git rev-parse HEAD)
                    REMOTE=$(git rev-parse origin/main)
                    if [ "$LOCAL" != "$REMOTE" ]; then echo "Update Available (New Commits)"; else echo "Up to date"; fi
                fi
            `]
            stdout: StdioCollector { id: checkUpdateCollector }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 16
            spacing: 16
            
            MaterialSymbol {
                text: (checkUpdateCollector.text && checkUpdateCollector.text.includes("Available")) ? "update" : "published_with_changes"
                iconSize: 24
                color: (checkUpdateCollector.text && checkUpdateCollector.text.includes("Available")) ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                StyledText {
                    text: "Update Status"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    text: checkUpdateProc.running ? "Checking..." : (checkUpdateCollector.text ? checkUpdateCollector.text.trim() : "Fetch the latest changes from the repository.")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: (checkUpdateCollector.text && checkUpdateCollector.text.includes("Available")) ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                }
            }

            Item { Layout.fillWidth: true }

            RippleButton {
                implicitWidth: 140
                implicitHeight: 40
                buttonRadius: 20
                colBackground: Appearance.colors.colPrimary
                onClicked: {
                    checkUpdateProc.running = false
                    checkUpdateProc.running = true
                    gitLogProc.running = false
                    gitTagProc.running = false
                    gitLogProc.running = true
                    gitTagProc.running = true
                }
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    MaterialSymbol {
                        text: "sync"
                        iconSize: 18
                        color: Appearance.colors.colOnPrimary
                    }
                    StyledText {
                        text: "Check Now"
                        color: Appearance.colors.colOnPrimary
                        font.weight: Font.Medium
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                }
            }
        }
    }

    property string updateType: "" // "shell" or "all"

    /**
     * BACKGROUND UPDATE PROCESS
     */
    Process {
        id: runUpdateProc
        command: ["bash", "-c", `${installState.install_dir}/update.sh ${updateType} ${installState.channel}`]
        onExited: {
            Quickshell.reload();
        }
    }

    // --- 3. Update Buttons (50:50) ---
    RowLayout {
        Layout.fillWidth: true
        spacing: 20
        visible: installState.install_dir !== ""

        RippleButton {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.preferredHeight: 64
            buttonRadius: 20
            colBackground: Appearance.m3colors.m3surfaceContainerHigh
            onClicked: {
                updateRoot.updateType = "shell";
                runUpdateProc.running = true;
            }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 16
                MaterialSymbol {
                    text: "system_update_alt"
                    iconSize: 24
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    Layout.fillWidth: true
                    text: "Update Shell Only"
                    font.weight: Font.Medium
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                }
                MaterialSymbol {
                    text: "download"
                    iconSize: 20
                    color: Appearance.colors.colPrimary
                }
            }
        }

        RippleButton {
            visible: installState.inject
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.preferredHeight: 64
            buttonRadius: 20
            colBackground: Appearance.m3colors.m3surfaceContainerHigh
            onClicked: {
                updateRoot.updateType = "all";
                runUpdateProc.running = true;
            }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 16
                MaterialSymbol {
                    text: "downloading"
                    iconSize: 24
                    color: Appearance.colors.colError
                }
                StyledText {
                    Layout.fillWidth: true
                    text: "Update All Files"
                    font.weight: Font.Medium
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colError
                }
                MaterialSymbol {
                    text: "download"
                    iconSize: 20
                    color: Appearance.colors.colError
                }
            }
        }
    }

    // --- Logs & Tags 50:50 Section ---
    RowLayout {
        Layout.fillWidth: true
        spacing: 20
        visible: installState.install_dir !== ""

        // Commit Log (Canary)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.preferredHeight: 250
            radius: 24
            color: Appearance.m3colors.m3surfaceContainerHigh

            Process {
                id: gitLogProc
                command: ["bash", "-c", `cd '${installState.install_dir}' && git fetch origin && git log --oneline -n 10 origin/main`]
                stdout: StdioCollector { id: gitLogCollector }
                running: updateRoot.visible && installState.install_dir !== ""
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                RowLayout {
                    spacing: 12
                    MaterialSymbol {
                        text: "commit"
                        iconSize: 24
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: "Recent Commits"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: logText.implicitHeight
                    clip: true
                    
                    StyledText {
                        id: logText
                        text: gitLogCollector.text || "Fetching recent commits..."
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                        wrapMode: Text.WrapAnywhere
                        font.family: Appearance.font.family.monospace
                        lineHeight: 1.2
                    }
                }
            }
        }

        // Tags Log (Stable)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.preferredHeight: 250
            radius: 24
            color: Appearance.m3colors.m3surfaceContainerHigh

            Process {
                id: gitTagProc
                command: ["bash", "-c", `cd '${installState.install_dir}' && git fetch --tags && git tag --sort=-creatordate | head -n 10`]
                stdout: StdioCollector { id: gitTagCollector }
                running: updateRoot.visible && installState.install_dir !== ""
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                RowLayout {
                    spacing: 12
                    MaterialSymbol {
                        text: "local_offer"
                        iconSize: 24
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: "Recent Tags"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: tagText.implicitHeight
                    clip: true
                    
                    StyledText {
                        id: tagText
                        text: gitTagCollector.text || "Fetching stable releases..."
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                        wrapMode: Text.WrapAnywhere
                        font.family: Appearance.font.family.monospace
                        lineHeight: 1.2
                    }
                }
            }
        }
    }
    
    StyledText {
        visible: installState.install_dir === ""
        text: "Update system unavailable. Installation state missing."
        color: Appearance.colors.colError
        Layout.alignment: Qt.AlignHCenter
    }
}

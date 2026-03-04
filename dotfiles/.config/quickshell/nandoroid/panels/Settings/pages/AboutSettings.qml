import "../../../core"
import "../../../services"
import "../../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Io

Flickable {
    id: root
    width: parent ? parent.width : 0
    height: parent ? parent.height : 0
    contentHeight: mainCol.implicitHeight + 48
    clip: true
    
    ScrollBar.vertical: StyledScrollBar {}

    property string currentView: "main" // "main", "update", "dependency", or "credits"

    onVisibleChanged: {
        if (!visible) root.currentView = "main"
        if (visible && root.currentView === "main" && !pacmanCheckProc.running) {
             pacmanCheckProc.running = true;
        }
    }

    Component.onCompleted: {
        pacmanCheckProc.running = true;
    }

    FileView {
        id: versionView
        path: Directories.home.replace("file://", "") + "/.config/quickshell/nandoroid/version.json"
        watchChanges: true
        JsonAdapter {
            id: versionData
            property string version: "0.95-alpha"
        }
    }

    ColumnLayout {
        id: mainCol
        width: parent.width
        spacing: 32

        // ── Header ──
        ColumnLayout {
            spacing: 4
            Layout.fillWidth: true
            
            RowLayout {
                spacing: 12
                Layout.fillWidth: true

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
                        if (root.currentView === "update") return "Shell Update"
                        if (root.currentView === "dependency") return "Dependency Check"
                        if (root.currentView === "credits") return "Special Thanks"
                        return "About"
                    }
                    font.pixelSize: Appearance.font.pixelSize.huge
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer1
                }
            }

            StyledText {
                visible: root.currentView === "main"
                text: "System information and project branding."
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
            }
        }

        // ── Main View ──
        ColumnLayout {
            visible: root.currentView === "main"
            Layout.fillWidth: true
            spacing: 32

            // ── Top Branding & Distro Cards (50:50) ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 20

                BrandingCard {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    title: "Shell"
                    name: "NAnDoroid"
                    subText: "Version " + versionData.version
                    accentColor: Appearance.colors.colPrimary
                    icon: "verified_user"
                    // Use local SVG but with better scaling
                    logoSource: "../../../assets/icons/NAnDoroid.svg"
                }

                BrandingCard {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    title: "Distro"
                    name: SystemInfo.distroName
                    subText: "Kernel " + SystemInfo.kernel
                    accentColor: Appearance.m3colors.m3tertiary
                    icon: "terminal"
                    // Use system logo name from os-release
                    logoSource: SystemInfo.logo
                    isSystemIcon: true
                }
            }

            // ── Update & Dependencies ──
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                RippleButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    buttonRadius: 16
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    onClicked: root.currentView = "update"
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 16
                        spacing: 16
                        MaterialSymbol {
                            text: "system_update"
                            iconSize: 22
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: "Shell Update"
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        MaterialSymbol {
                            text: "chevron_right"
                            iconSize: 20
                            color: Appearance.colors.colSubtext
                        }
                    }
                }

                RippleButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    buttonRadius: 16
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    onClicked: root.currentView = "dependency"
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 16
                        spacing: 16
                        MaterialSymbol {
                            text: "verified"
                            iconSize: 22
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: "Dependency Check"
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        MaterialSymbol {
                            text: "chevron_right"
                            iconSize: 20
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }

            // ── System Information ──
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    spacing: 12
                    Layout.bottomMargin: 8
                    MaterialSymbol {
                        text: "info"
                        iconSize: 24
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: "System Information"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    InfoRow { label: "Distro"; value: SystemInfo.distroName }
                    InfoRow { label: "Username"; value: SystemInfo.username }
                    InfoRow { label: "Host"; value: SystemInfo.hostname }
                    InfoRow { label: "Kernel"; value: SystemInfo.kernel }
                    InfoRow { label: "Shell"; value: "nandoroid-shell" }
                }
            }

            // ── Hardware Information ──
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    spacing: 12
                    Layout.bottomMargin: 8
                    MaterialSymbol {
                        text: "memory"
                        iconSize: 24
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: "Hardware"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    InfoRow { label: "Processor"; value: SystemInfo.cpu }
                    InfoRow { label: "GPU"; value: SystemInfo.gpu }
                    InfoRow { label: "Memory"; value: SystemInfo.memory }
                    InfoRow { label: "Storage"; value: SystemInfo.storage }
                    InfoRow { label: "Displays"; value: HyprlandData.monitors.length + " connected" }
                }
            }

            // ── Links ──
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    spacing: 12
                    Layout.bottomMargin: 8
                    MaterialSymbol {
                        text: "link"
                        iconSize: 24
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: "Links"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: 52
                        orientation: Qt.Vertical
                        maxRadius: 20
                        color: Appearance.m3colors.m3surfaceContainerHigh

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 20
                            anchors.rightMargin: 20
                            spacing: 12
                            
                            MaterialSymbol {
                                text: "code"
                                iconSize: 20
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: "Source Code"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer0
                            }
                            StyledText {
                                text: "GitHub Repository"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colPrimary
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Qt.openUrlExternally("https://github.com/na-ive/nandoroid-shell")
                                }
                            }
                        }
                    }

                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: 52
                        orientation: Qt.Vertical
                        maxRadius: 20
                        color: Appearance.m3colors.m3surfaceContainerHigh

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 20
                            anchors.rightMargin: 12
                            spacing: 12
                            
                            MaterialSymbol {
                                text: "favorite"
                                iconSize: 20
                                color: "#ff4081"
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: "Special Thanks"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer0
                            }
                            MaterialSymbol {
                                text: "chevron_right"
                                iconSize: 20
                                color: Appearance.colors.colSubtext
                            }
                        }

                        RippleButton {
                            anchors.fill: parent
                            colBackground: "transparent"
                            onClicked: root.currentView = "credits"
                            
                            topLeftRadius: parent.rTopLeft
                            topRightRadius: parent.rTopRight
                            bottomLeftRadius: parent.rBottomLeft
                            bottomRightRadius: parent.rBottomRight
                        }
                    }
                }
            }
        }

        // ── Update Sub-page ──
        ColumnLayout {
            visible: root.currentView === "update"
            Layout.fillWidth: true
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

            // --- 2. Check for Updates Hero Card ---
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 250
                radius: 28
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

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 16
                    
                    MaterialSymbol {
                        text: "published_with_changes"
                        iconSize: 64
                        color: Appearance.colors.colPrimary
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    StyledText {
                        text: "Update Status"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnLayer1
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    StyledText {
                        text: checkUpdateProc.running ? "Checking..." : (checkUpdateCollector.text ? checkUpdateCollector.text.trim() : "Fetch the latest changes from the repository.")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: (checkUpdateCollector.text && checkUpdateCollector.text.includes("Available")) ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                        Layout.alignment: Qt.AlignHCenter
                    }

                    RippleButton {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: checkBtnContent.implicitWidth + 48
                        implicitHeight: 48
                        buttonRadius: 24
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
                            id: checkBtnContent
                            anchors.centerIn: parent
                            spacing: 8
                            MaterialSymbol {
                                text: "sync"
                                iconSize: 20
                                color: Appearance.colors.colOnPrimary
                            }
                            StyledText {
                                text: "Check for Updates"
                                color: Appearance.colors.colOnPrimary
                                font.weight: Font.Medium
                            }
                        }
                    }
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
                        Quickshell.execDetached(["kitty", "--hold", "-e", "bash", "-c", `${installState.install_dir}/update.sh shell ${installState.channel}`])
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
                        Quickshell.execDetached(["kitty", "--hold", "-e", "bash", "-c", `${installState.install_dir}/update.sh all ${installState.channel}`])
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
                        running: root.currentView === "update" && installState.install_dir !== ""
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
                                font.family: Appearance.font.monospace
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
                        running: root.currentView === "update" && installState.install_dir !== ""
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
                                font.family: Appearance.font.monospace
                                lineHeight: 1.2
                            }
                        }
                    }
                }
            }
            
            // Fallback warning if install dir missing
            StyledText {
                visible: installState.install_dir === ""
                text: "Update system unavailable. Installation state missing."
                color: Appearance.colors.colError
                Layout.alignment: Qt.AlignHCenter
            }
        }

        // ── Dependency Sub-page ──
        ColumnLayout {
            visible: root.currentView === "dependency"
            Layout.fillWidth: true
            spacing: 24

            Process {
                id: pacmanCheckProc
                command: ["bash", "-c", "pacman -Qq"]
                running: false
                stdout: StdioCollector {
                    id: pacmanCollector
                    onTextChanged: {
                        if (!text) return;
                        let pkgs = text.split('\n');
                        let pkgSet = new Set(pkgs);
                        for (let i = 0; i < depModel.count; i++) {
                            let p = depModel.get(i).packageName;
                            let isInst = pkgSet.has(p) || pkgSet.has(p + "-git") || pkgSet.has(p + "-bin");
                            
                            // Specific Overrides for AUR/Alternate names
                            if (p === "matugen") isInst = pkgSet.has("matugen") || pkgSet.has("matugen-bin");
                            if (p === "bluez-utils") isInst = pkgSet.has("bluez-utils") || pkgSet.has("bluez-utils-git");
                            if (p === "quickshell") isInst = pkgSet.has("quickshell") || pkgSet.has("quickshell-git");
                            if (p === "dgop") isInst = pkgSet.has("dgop") || pkgSet.has("dgop-bin") || pkgSet.has("dgop-git");

                            depModel.setProperty(i, "installed", isInst);
                        }
                    }
                }
            }

            ListModel {
                id: depModel
                ListElement { displayName: "Hyprland"; packageName: "hyprland"; installed: false; desc: "Wayland compositor" }
                ListElement { displayName: "Quickshell"; packageName: "quickshell"; installed: false; desc: "Desktop shell framework" }
                ListElement { displayName: "Pipewire"; packageName: "pipewire"; installed: false; desc: "Audio server" }
                ListElement { displayName: "NetworkManager"; packageName: "networkmanager"; installed: false; desc: "Network connection manager" }
                ListElement { displayName: "BlueZ Utils"; packageName: "bluez-utils"; installed: false; desc: "Bluetooth utilities" }
                ListElement { displayName: "Libnotify"; packageName: "libnotify"; installed: false; desc: "Desktop notifications" }
                ListElement { displayName: "Polkit"; packageName: "polkit"; installed: false; desc: "Policy toolkit" }
                ListElement { displayName: "XDG Portal Hyprland"; packageName: "xdg-desktop-portal-hyprland"; installed: false; desc: "Screen sharing portal" }
                ListElement { displayName: "XDG Portal GTK"; packageName: "xdg-desktop-portal-gtk"; installed: false; desc: "File picker portal" }
                ListElement { displayName: "dgop"; packageName: "dgop"; installed: false; desc: "System monitor daemon" }
                ListElement { displayName: "Brightnessctl"; packageName: "brightnessctl"; installed: false; desc: "Screen brightness control" }
                ListElement { displayName: "ddcutil"; packageName: "ddcutil"; installed: false; desc: "External monitor brightness" }
                ListElement { displayName: "Playerctl"; packageName: "playerctl"; installed: false; desc: "Media player controller" }
                ListElement { displayName: "Matugen"; packageName: "matugen"; installed: false; desc: "Material theme generator" }
                ListElement { displayName: "Grim"; packageName: "grim"; installed: false; desc: "Screenshot utility" }
                ListElement { displayName: "Slurp"; packageName: "slurp"; installed: false; desc: "Region selector" }
                ListElement { displayName: "Wf-Recorder"; packageName: "wf-recorder"; installed: false; desc: "Screen recorder" }
                ListElement { displayName: "ImageMagick"; packageName: "imagemagick"; installed: false; desc: "Image processing" }
                ListElement { displayName: "Ffmpeg"; packageName: "ffmpeg"; installed: false; desc: "Multimedia framework" }
                ListElement { displayName: "Songrec"; packageName: "songrec"; installed: false; desc: "Music recognition" }
                ListElement { displayName: "Cava"; packageName: "cava"; installed: false; desc: "Audio visualizer" }
                ListElement { displayName: "Easyeffects"; packageName: "easyeffects"; installed: false; desc: "Audio effects" }
                ListElement { displayName: "Hyprpicker"; packageName: "hyprpicker"; installed: false; desc: "Color picker" }
                ListElement { displayName: "Hyprlock"; packageName: "hyprlock"; installed: false; desc: "Screen locker" }
                ListElement { displayName: "Hyprsunset"; packageName: "hyprsunset"; installed: false; desc: "Blue light filter" }
                ListElement { displayName: "jq"; packageName: "jq"; installed: false; desc: "Command-line JSON processor" }
                ListElement { displayName: "XDG Utils"; packageName: "xdg-utils"; installed: false; desc: "Desktop integration utilities" }
                ListElement { displayName: "Wl-Clipboard"; packageName: "wl-clipboard"; installed: false; desc: "Wayland clipboard" }
                ListElement { displayName: "Kitty"; packageName: "kitty"; installed: false; desc: "Terminal emulator" }
                ListElement { displayName: "Fish"; packageName: "fish"; installed: false; desc: "Interactive shell" }
                ListElement { displayName: "Starship"; packageName: "starship"; installed: false; desc: "Cross-shell prompt" }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                radius: 28
                color: Appearance.m3colors.m3surfaceContainerHigh
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20
                    
                    MaterialSymbol {
                        text: "account_tree"
                        iconSize: 48
                        color: Appearance.colors.colPrimary
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        StyledText {
                            text: "System Dependencies"
                            font.pixelSize: Appearance.font.pixelSize.large
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: "Ensure all required packages are installed."
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colSubtext
                        }
                    }

                    RippleButton {
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        implicitWidth: 160
                        implicitHeight: 48
                        buttonRadius: 24
                        colBackground: Appearance.colors.colPrimary
                        onClicked: {
                            pacmanCheckProc.running = false
                            pacmanCheckProc.running = true
                        }
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            MaterialSymbol {
                                text: "sync"
                                iconSize: 20
                                color: Appearance.colors.colOnPrimary
                            }
                            StyledText {
                                text: "Scan Now"
                                color: Appearance.colors.colOnPrimary
                                font.weight: Font.Medium
                            }
                        }
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 12
                columnSpacing: 12

                Repeater {
                    model: depModel
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 72
                        radius: 20
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        border.width: 1
                        border.color: model.installed ? "#81C995" : Appearance.colors.colError // #81C995 is a material green suitable for both dark and light

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: {
                                if (!model.installed) {
                                    let pkg = model.packageName;
                                    if (pkg === "quickshell") pkg = "quickshell-git";
                                    if (pkg === "matugen") pkg = "matugen-bin";
                                    Quickshell.execDetached(["kitty", "--hold", "-e", "paru", "-S", "--needed", pkg]);
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 20
                                anchors.rightMargin: 20
                                spacing: 16

                                MaterialSymbol {
                                    text: model.installed ? "check_circle" : "cancel"
                                    iconSize: 28
                                    color: model.installed ? "#81C995" : Appearance.colors.colError
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: model.displayName
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                        font.weight: Font.Bold
                                        color: Appearance.colors.colOnLayer1
                                        elide: Text.ElideRight
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: model.desc
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colSubtext
                                        elide: Text.ElideRight
                                    }
                                }

                                ColumnLayout {
                                    visible: !model.installed
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                    spacing: 2
                                    StyledText {
                                        text: "Not Installed"
                                        color: Appearance.colors.colError
                                        font.weight: Font.Bold
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        Layout.alignment: Qt.AlignRight
                                    }
                                    StyledText {
                                        text: "Click to install"
                                        color: Appearance.colors.colError
                                        opacity: 0.8
                                        font.pixelSize: 10
                                        Layout.alignment: Qt.AlignRight
                                    }
                                }
                                
                                StyledText {
                                    visible: model.installed
                                    text: "Installed"
                                    color: "#81C995"
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                    font.weight: Font.Bold
                                    font.pixelSize: Appearance.font.pixelSize.small
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Credits Sub-page ──
        ColumnLayout {
            visible: root.currentView === "credits"
            Layout.fillWidth: true
            spacing: 24

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                
                StyledText {
                    Layout.fillWidth: true
                    text: "This project is a port and personal creation, built with love and inspired by these amazing developers and projects."
                    wrapMode: Text.WordWrap
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
                }
            }

            // --- Inspiration Cards ---
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                ProjectCard {
                    title: "illogical-impulse"
                    description: "End-4's Hyprland dotfiles. A lot of the architecture and shell logic here traces back to this."
                    iconSource: "../../../assets/icons/illogical-impulse.svg"
                    url: "https://github.com/end-4/dots-hyprland"
                    accentColor: "#89b4fa"
                }

                ProjectCard {
                    title: "ii-vynx"
                    description: "Vynx's fork of illogical-impulse. Helped a lot with the Quickshell port and various other bits throughout the config."
                    iconSource: "../../../assets/icons/illogical-impulse.svg"
                    url: "https://github.com/vaguesyntax/ii-vynx"
                    accentColor: "#cba6f7"
                }

                ProjectCard {
                    title: "Dank Material Shell"
                    description: "AvengeMedia's DMS. Helped a ton with a lot of the harder parts of the config, and dgop was super useful for system monitoring stuff."
                    iconSource: "../../../assets/icons/danklogo.svg"
                    url: "https://github.com/AvengeMedia/DankMaterialShell"
                    accentColor: "#f38ba8"
                }

                ProjectCard {
                    title: "Ambxst"
                    description: "Axenide's Ambxst. Where the notch idea came from, and probably a few other things down the line."
                    iconSource: "../../../assets/icons/ambxst-logo-color.svg"
                    url: "https://github.com/Axenide/Ambxst"
                    accentColor: "#89dceb"
                }
            }
            

        }

        Item { Layout.fillHeight: true }
    }

    // ── Internal Components ──

    component BrandingCard: Rectangle {
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

    component InfoRow: SegmentedWrapper {
        property string label
        property string value
        Layout.fillWidth: true
        Layout.preferredHeight: 52
        orientation: Qt.Vertical
        maxRadius: 20
        color: Appearance.m3colors.m3surfaceContainerHigh
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 20

            StyledText {
                text: label
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer0
                Layout.fillWidth: true
            }
            StyledText {
                text: value
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
                Layout.alignment: Qt.AlignRight
                elide: Text.ElideRight
            }
        }
    }

    component ProjectCard: Rectangle {
        id: projRoot
        property string title
        property string description
        property string iconSource
        property string url
        property color accentColor

        Layout.fillWidth: true
        Layout.preferredHeight: layoutCol.implicitHeight + 40
        radius: 28
        color: Appearance.m3colors.m3surfaceContainerHigh
        
        RippleButton {
            anchors.fill: parent
            buttonRadius: parent.radius
            colBackground: "transparent"
            onClicked: Qt.openUrlExternally(projRoot.url)
        }

        ColumnLayout {
            id: layoutCol
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            RowLayout {
                spacing: 16
                Image {
                    source: projRoot.iconSource
                    sourceSize: Qt.size(64, 64)
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64
                    fillMode: Image.PreserveAspectFit
                }
                
                ColumnLayout {
                    spacing: 2
                    StyledText {
                        text: projRoot.title
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: projRoot.url
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: projRoot.accentColor
                        opacity: 0.8
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: projRoot.description
                wrapMode: Text.WordWrap
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
                lineHeight: 1.2
            }
        }
    }
}

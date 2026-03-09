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
    id: dependencyRoot
    spacing: 24

    property alias isScanning: pacmanCheckProc.running

    function scanDependencies() {
        pacmanCheckProc.running = false
        pacmanCheckProc.running = true
    }

    Process {
        id: pacmanCheckProc
        command: ["bash", "-c", "pacman -Qq; echo '---FONTCHECK---'; fc-list : family"]
        running: false
        stdout: StdioCollector {
            id: pacmanCollector
            onTextChanged: {
                if (!text) return;
                let sections = text.split('---FONTCHECK---');
                let pkgs = (sections[0] || '').split('\n');
                let pkgSet = new Set(pkgs);
                let fonts = (sections[1] || '').toLowerCase();
                for (let i = 0; i < depModel.count; i++) {
                    let p = depModel.get(i).packageName;
                    let isInst = false;

                    // Font-based checks (installed via git clone, not pacman)
                    if (p === "__font_google_sans") {
                        isInst = fonts.indexOf("google sans flex") >= 0;
                    } else {
                        isInst = pkgSet.has(p) || pkgSet.has(p + "-git") || pkgSet.has(p + "-bin");
                    }
                    
                    // Specific Overrides for AUR/Alternate names
                    if (p === "matugen") isInst = pkgSet.has("matugen") || pkgSet.has("matugen-bin");
                    if (p === "bluez-utils") isInst = pkgSet.has("bluez-utils") || pkgSet.has("bluez-utils-git");
                    if (p === "quickshell") isInst = pkgSet.has("quickshell") || pkgSet.has("quickshell-git");
                    if (p === "dgop") isInst = pkgSet.has("dgop") || pkgSet.has("dgop-bin") || pkgSet.has("dgop-git");
                    if (p === "ttf-material-symbols-variable-git") isInst = pkgSet.has("ttf-material-symbols-variable-git") || pkgSet.has("ttf-material-symbols-variable") || pkgSet.has("material-symbols-git");

                    depModel.setProperty(i, "installed", isInst);
                }
            }
        }
    }

    ListModel {
        id: depModel
        ListElement { displayName: "Hyprland"; packageName: "hyprland"; installed: false; desc: "Wayland compositor" }
        ListElement { displayName: "Quickshell"; packageName: "quickshell"; installed: false; desc: "Desktop shell framework" }
        ListElement { displayName: "Python 3"; packageName: "python"; installed: false; desc: "Terminal color application" }
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
        ListElement { displayName: "Cliphist"; packageName: "cliphist"; installed: false; desc: "Clipboard history manager" }
        ListElement { displayName: "Zenity"; packageName: "zenity"; installed: false; desc: "System dialogs for file/folder selection" }
        ListElement { displayName: "fd"; packageName: "fd"; installed: false; desc: "Fast file search utility" }
        ListElement { displayName: "Libqalculate"; packageName: "libqalculate"; installed: false; desc: "Advanced math calculator (qalc)" }
        ListElement { displayName: "Google Sans Flex"; packageName: "__font_google_sans"; installed: false; desc: "UI font (from GitHub)" }
        ListElement { displayName: "Material Symbols"; packageName: "ttf-material-symbols-variable-git"; installed: false; desc: "Icon font" }
        ListElement { displayName: "JetBrains Mono NF"; packageName: "ttf-jetbrains-mono-nerd"; installed: false; desc: "Monospace font" }
        ListElement { displayName: "Kitty"; packageName: "kitty"; installed: false; desc: "Terminal emulator (optional)" }
        ListElement { displayName: "Fish"; packageName: "fish"; installed: false; desc: "Interactive shell (optional)" }
        ListElement { displayName: "Starship"; packageName: "starship"; installed: false; desc: "Cross-shell prompt (optional)" }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 80
        radius: 20
        color: Appearance.m3colors.m3surfaceContainerHigh
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 16
            spacing: 16
            
            MaterialSymbol {
                text: "account_tree"
                iconSize: 24
                color: Appearance.colors.colPrimary
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                StyledText {
                    text: "Dependency Scanner"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    text: "Identify and install missing system components."
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
            }

            Item { Layout.fillWidth: true }

            RippleButton {
                implicitWidth: 140
                implicitHeight: 40
                buttonRadius: 20
                colBackground: Appearance.colors.colPrimary
                onClicked: {
                    dependencyRoot.scanDependencies();
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
                        text: "Scan Now"
                        color: Appearance.colors.colOnPrimary
                        font.weight: Font.Medium
                        font.pixelSize: Appearance.font.pixelSize.small
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
                border.color: model.installed ? "#81C995" : Appearance.colors.colError 

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

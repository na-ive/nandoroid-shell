import "../../../core"
import "../../../services"
import "../../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets

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
                    subText: "Version 0.9-alpha"
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

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 200
                radius: 28
                color: Appearance.m3colors.m3surfaceContainerHigh
                
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
                        text: "Your system is up to date"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnLayer1
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    StyledText {
                        text: "Version: 0.9-alpha (stable)"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colSubtext
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
            
            Button {
                flat: true
                Layout.alignment: Qt.AlignHCenter
                contentItem: StyledText {
                    text: "Check for updates"
                    color: Appearance.colors.colPrimary
                    font.weight: Font.Bold
                }
                onClicked: {
                    // This would normally trigger a repo check
                }
            }
        }

        // ── Dependency Sub-page ──
        ColumnLayout {
            visible: root.currentView === "dependency"
            Layout.fillWidth: true
            spacing: 24

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 300
                radius: 28
                color: Appearance.m3colors.m3surfaceContainerHigh
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 16
                    
                    StyledText {
                        text: "Dependency Status"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnLayer1
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        
                        InfoRow { label: "Quickshell"; value: "Installed (v0.1.0+)" }
                        InfoRow { label: "Hyprland"; value: "Running" }
                        InfoRow { label: "dgop"; value: "Installed" }
                        InfoRow { label: "Material Symbols"; value: "Loaded" }
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

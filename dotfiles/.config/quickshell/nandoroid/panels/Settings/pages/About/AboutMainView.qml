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
    property string version: ""
    signal pushView(string viewName)

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
                    subText: "Version " + version
                    accentColor: Appearance.colors.colPrimary
                    icon: "verified_user"
                    // Use local SVG but with better scaling
                    logoSource: "../../../../assets/icons/NAnDoroid.svg"
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
                    onClicked: pushView( "update")
                    
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
                    onClicked: pushView( "dependency")
                    
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
                
                SearchHandler { 
                    searchString: "System Information"
                    aliases: ["OS", "Distro", "Kernel", "Hostname"]
                }

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
                
                SearchHandler { 
                    searchString: "Hardware"
                    aliases: ["CPU", "GPU", "Memory", "RAM", "Specs"]
                }

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
                            onClicked: pushView( "credits")
                            
                            buttonRadius: Appearance.rounding.button
                        }
                    }
                }
            }


        // ── Update Sub-page ──

    }

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

            spacing: 32 * Appearance.effectiveScale

            // ── Top Branding & Distro Cards (50:50) ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 20 * Appearance.effectiveScale

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
                spacing: 12 * Appearance.effectiveScale

                RippleButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52 * Appearance.effectiveScale
                    buttonRadius: 16 * Appearance.effectiveScale
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    onClicked: pushView( "update")
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20 * Appearance.effectiveScale
                        anchors.rightMargin: 16 * Appearance.effectiveScale
                        spacing: 16 * Appearance.effectiveScale
                        MaterialSymbol {
                            text: "system_update"
                            iconSize: 22 * Appearance.effectiveScale
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
                            iconSize: 20 * Appearance.effectiveScale
                            color: Appearance.colors.colSubtext
                        }
                    }
                }

                RippleButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52 * Appearance.effectiveScale
                    buttonRadius: 16 * Appearance.effectiveScale
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    onClicked: pushView( "dependency")
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20 * Appearance.effectiveScale
                        anchors.rightMargin: 16 * Appearance.effectiveScale
                        spacing: 16 * Appearance.effectiveScale
                        MaterialSymbol {
                            text: "verified"
                            iconSize: 22 * Appearance.effectiveScale
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: "Dependency Check"
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }

                        // Notification Badge
                        Rectangle {
                            visible: SysCheckService.missingCount > 0
                            width: 8 * Appearance.effectiveScale
                            height: 8 * Appearance.effectiveScale
                            radius: 4 * Appearance.effectiveScale
                            color: Appearance.colors.colError
                            Layout.alignment: Qt.AlignVCenter
                        }

                        MaterialSymbol {
                            text: "chevron_right"
                            iconSize: 20 * Appearance.effectiveScale
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }

            // ── System Information ──
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4 * Appearance.effectiveScale
                
                SearchHandler { 
                    searchString: "System Information"
                    aliases: ["OS", "Distro", "Kernel", "Hostname"]
                }

                RowLayout {
                    spacing: 12 * Appearance.effectiveScale
                    Layout.bottomMargin: 8 * Appearance.effectiveScale
                    MaterialSymbol {
                        text: "info"
                        iconSize: 24 * Appearance.effectiveScale
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
                    spacing: 4 * Appearance.effectiveScale

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
                spacing: 4 * Appearance.effectiveScale
                
                SearchHandler { 
                    searchString: "Hardware"
                    aliases: ["CPU", "GPU", "Memory", "RAM", "Specs"]
                }

                RowLayout {
                    spacing: 12 * Appearance.effectiveScale
                    Layout.bottomMargin: 8 * Appearance.effectiveScale
                    MaterialSymbol {
                        text: "memory"
                        iconSize: 24 * Appearance.effectiveScale
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
                    spacing: 4 * Appearance.effectiveScale

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
                spacing: 4 * Appearance.effectiveScale

                RowLayout {
                    spacing: 12 * Appearance.effectiveScale
                    Layout.bottomMargin: 8 * Appearance.effectiveScale
                    MaterialSymbol {
                        text: "link"
                        iconSize: 24 * Appearance.effectiveScale
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: "Links & Resources"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4 * Appearance.effectiveScale

                    SegmentedWrapper {
                        id: onboardingLinkWrapper
                        Layout.fillWidth: true
                        implicitHeight: 52 * Appearance.effectiveScale
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh

                        RippleButton {
                            anchors.fill: parent
                            colBackground: "transparent"
                            onClicked: {
                                GlobalStates.settingsOpen = false;
                                GlobalStates.onboardingOpen = true;
                            }
                            
                            // Explicitly inherit radii from SegmentedWrapper for hover alignment
                            topLeftRadius: onboardingLinkWrapper.rTopLeft
                            topRightRadius: onboardingLinkWrapper.rTopRight
                            bottomLeftRadius: onboardingLinkWrapper.rBottomLeft
                            bottomRightRadius: onboardingLinkWrapper.rBottomRight

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 20 * Appearance.effectiveScale
                                anchors.rightMargin: 12 * Appearance.effectiveScale
                                spacing: 12 * Appearance.effectiveScale
                                
                                MaterialSymbol {
                                    text: "explore"
                                    iconSize: 20 * Appearance.effectiveScale
                                    color: Appearance.colors.colPrimary
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: "Start Onboarding Tour"
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnLayer0
                                }
                                MaterialSymbol {
                                    text: "chevron_right"
                                    iconSize: 20 * Appearance.effectiveScale
                                    color: Appearance.colors.colSubtext
                                }
                            }
                        }
                    }

                    SegmentedWrapper {
                        id: ipcLinkWrapper
                        Layout.fillWidth: true
                        implicitHeight: 52 * Appearance.effectiveScale
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh

                        RippleButton {
                            anchors.fill: parent
                            colBackground: "transparent"
                            onClicked: {
                                GlobalStates.settingsOpen = false;
                                GlobalStates.onboardingStep = 5; // Jump to IPC step
                                GlobalStates.onboardingOpen = true;
                            }
                            
                            // Explicitly inherit radii from SegmentedWrapper for hover alignment
                            topLeftRadius: ipcLinkWrapper.rTopLeft
                            topRightRadius: ipcLinkWrapper.rTopRight
                            bottomLeftRadius: ipcLinkWrapper.rBottomLeft
                            bottomRightRadius: ipcLinkWrapper.rBottomRight

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 20 * Appearance.effectiveScale
                                anchors.rightMargin: 12 * Appearance.effectiveScale
                                spacing: 12 * Appearance.effectiveScale
                                
                                MaterialSymbol {
                                    text: "terminal"
                                    iconSize: 20 * Appearance.effectiveScale
                                    color: Appearance.colors.colPrimary
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: "IPC Integration Guide"
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnLayer0
                                }
                                MaterialSymbol {
                                    text: "chevron_right"
                                    iconSize: 20 * Appearance.effectiveScale
                                    color: Appearance.colors.colSubtext
                                }
                            }
                        }
                    }

                    SegmentedWrapper {
                        id: sourceLinkWrapper
                        Layout.fillWidth: true
                        implicitHeight: 52 * Appearance.effectiveScale
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh

                        RippleButton {
                            anchors.fill: parent
                            colBackground: "transparent"
                            onClicked: Qt.openUrlExternally("https://github.com/na-ive/nandoroid-shell")
                            
                            // Explicitly inherit radii from SegmentedWrapper for hover alignment
                            topLeftRadius: sourceLinkWrapper.rTopLeft
                            topRightRadius: sourceLinkWrapper.rTopRight
                            bottomLeftRadius: sourceLinkWrapper.rBottomLeft
                            bottomRightRadius: sourceLinkWrapper.rBottomRight

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 20 * Appearance.effectiveScale
                                anchors.rightMargin: 20 * Appearance.effectiveScale
                                spacing: 12 * Appearance.effectiveScale
                                
                                MaterialSymbol {
                                    text: "code"
                                    iconSize: 20 * Appearance.effectiveScale
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
                                }
                            }
                        }
                    }

                    SegmentedWrapper {
                        id: creditsLinkWrapper
                        Layout.fillWidth: true
                        implicitHeight: 52 * Appearance.effectiveScale
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh

                        RippleButton {
                            anchors.fill: parent
                            colBackground: "transparent"
                            onClicked: pushView("credits")
                            
                            // Explicitly inherit radii from SegmentedWrapper for hover alignment
                            topLeftRadius: creditsLinkWrapper.rTopLeft
                            topRightRadius: creditsLinkWrapper.rTopRight
                            bottomLeftRadius: creditsLinkWrapper.rBottomLeft
                            bottomRightRadius: creditsLinkWrapper.rBottomRight

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 20 * Appearance.effectiveScale
                                anchors.rightMargin: 12 * Appearance.effectiveScale
                                spacing: 12 * Appearance.effectiveScale
                                
                                MaterialSymbol {
                                    text: "favorite"
                                    iconSize: 20 * Appearance.effectiveScale
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
                                    iconSize: 20 * Appearance.effectiveScale
                                    color: Appearance.colors.colSubtext
                                }
                            }
                        }
                    }
                }
            }


        // ── Update Sub-page ──

    }

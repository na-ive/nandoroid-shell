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

    property bool updateAvailable: VersionService.updateAvailable


            spacing: 24 * Appearance.effectiveScale

            // ── Top Branding & Distro Cards (50:50) ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 12 * Appearance.effectiveScale

                BrandingCard {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    title: I18nService.tr("Shell")
                    name: "NAnDoroid"
                    subText: I18nService.tr("Version ") + version
                    accentColor: Appearance.colors.colPrimary
                    icon: "verified_user"
                    logoSource: "nandoroid-symbolic"
                    shapeName: "SoftBurst"
                }

                BrandingCard {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    title: I18nService.tr("Distro")
                    name: SystemInfo.distroName
                    subText: I18nService.tr("Kernel ") + SystemInfo.kernel
                    accentColor: Appearance.m3colors.m3tertiary
                    icon: "terminal"
                    logoSource: SystemInfo.distroIcon || SystemInfo.logo
                    shapeName: "Puffy"
                }
            }

            // ── Update & Dependencies ──
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12 * Appearance.effectiveScale

                RippleButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64 * Appearance.effectiveScale
                    buttonRadius: 32 * Appearance.effectiveScale
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    onClicked: pushView( "update")
                    
                    SearchHandler {
                        searchString: "Shell Update"
                        aliases: ["Update"]
                    }
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16 * Appearance.effectiveScale
                        anchors.rightMargin: 16 * Appearance.effectiveScale
                        spacing: 16 * Appearance.effectiveScale
                        MaterialSymbol {
                            text: "system_update"
                            iconSize: 24 * Appearance.effectiveScale
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: I18nService.tr("Shell Update")
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: I18nService.tr("Update available")
                            color: Appearance.colors.colError
                            font.pixelSize: Appearance.font.pixelSize.small
                            visible: updateAvailable
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
                    Layout.preferredHeight: 64 * Appearance.effectiveScale
                    buttonRadius: 32 * Appearance.effectiveScale
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    onClicked: pushView( "dependency")
                    
                    SearchHandler {
                        searchString: "Dependency Check"
                        aliases: ["Dependencies"]
                    }
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16 * Appearance.effectiveScale
                        anchors.rightMargin: 16 * Appearance.effectiveScale
                        spacing: 16 * Appearance.effectiveScale
                        MaterialSymbol {
                            text: "verified"
                            iconSize: 24 * Appearance.effectiveScale
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: I18nService.tr("Dependency Check")
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
                        text: I18nService.tr("System Information")
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.family: Appearance.font.family.title
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4 * Appearance.effectiveScale

                    InfoRow { label: I18nService.tr("Distro"); value: SystemInfo.distroName }
                    InfoRow { label: I18nService.tr("Username"); value: SystemInfo.username }
                    InfoRow { label: I18nService.tr("Host"); value: SystemInfo.hostname }
                    InfoRow { label: I18nService.tr("Kernel"); value: SystemInfo.kernel }
                    InfoRow { label: I18nService.tr("Shell"); value: "nandoroid-shell" }
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
                        text: I18nService.tr("Hardware")
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.family: Appearance.font.family.title
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4 * Appearance.effectiveScale

                    InfoRow { label: I18nService.tr("Processor"); value: SystemInfo.cpu }
                    InfoRow { label: "GPU"; value: SystemInfo.gpu }
                    InfoRow { label: I18nService.tr("Memory"); value: SystemInfo.memory }
                    InfoRow { label: I18nService.tr("Storage"); value: SystemInfo.storage }
                    InfoRow { label: I18nService.tr("Displays"); value: HyprlandData.monitors.length + I18nService.tr(" connected") }
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
                        text: I18nService.tr("Links & Resources")
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.family: Appearance.font.family.title
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
                        implicitHeight: Math.max(64 * Appearance.effectiveScale, onboardLinkRow.implicitHeight)
                        orientation: Qt.Vertical
                        color: Appearance.m3colors.m3surfaceContainerHigh

                        RippleButton {
                            anchors.fill: parent
                            colBackground: "transparent"
                            onClicked: {
                                GlobalStates.settingsOpen = false;
                                GlobalStates.onboardingOpen = true;
                            }

                            SearchHandler {
                                searchString: "Onboarding"
                                aliases: ["Tour", "Guide"]
                            }

                            // Explicitly inherit radii from SegmentedWrapper for hover alignment
                            topLeftRadius: onboardingLinkWrapper.rTopLeft
                            topRightRadius: onboardingLinkWrapper.rTopRight
                            bottomLeftRadius: onboardingLinkWrapper.rBottomLeft
                            bottomRightRadius: onboardingLinkWrapper.rBottomRight

                            RowLayout {
                                id: onboardLinkRow
                                anchors.fill: parent
                                anchors {
                                    leftMargin: 16 * Appearance.effectiveScale
                                    rightMargin: 16 * Appearance.effectiveScale
                                }
                                spacing: 16 * Appearance.effectiveScale

                                MaterialSymbol {
                                    text: "explore"
                                    iconSize: 24 * Appearance.effectiveScale
                                    color: Appearance.colors.colPrimary
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: I18nService.tr("Start Onboarding Tour")
                                    color: Appearance.colors.colOnLayer1
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
                        implicitHeight: Math.max(64 * Appearance.effectiveScale, ipcLinkRow.implicitHeight)
                        orientation: Qt.Vertical
                        color: Appearance.m3colors.m3surfaceContainerHigh

                        RippleButton {
                            anchors.fill: parent
                            colBackground: "transparent"
                            onClicked: {
                                GlobalStates.settingsOpen = false;
                                GlobalStates.onboardingStep = 5; // Jump to IPC step
                                GlobalStates.onboardingOpen = true;
                            }

                            SearchHandler {
                                searchString: "IPC Guide"
                                aliases: ["IPC", "API", "Integration"]
                            }

                            // Explicitly inherit radii from SegmentedWrapper for hover alignment
                            topLeftRadius: ipcLinkWrapper.rTopLeft
                            topRightRadius: ipcLinkWrapper.rTopRight
                            bottomLeftRadius: ipcLinkWrapper.rBottomLeft
                            bottomRightRadius: ipcLinkWrapper.rBottomRight

                            RowLayout {
                                id: ipcLinkRow
                                anchors.fill: parent
                                anchors {
                                    leftMargin: 16 * Appearance.effectiveScale
                                    rightMargin: 16 * Appearance.effectiveScale
                                }
                                spacing: 16 * Appearance.effectiveScale

                                MaterialSymbol {
                                    text: "terminal"
                                    iconSize: 24 * Appearance.effectiveScale
                                    color: Appearance.colors.colPrimary
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: I18nService.tr("IPC Integration Guide")
                                    color: Appearance.colors.colOnLayer1
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
                        implicitHeight: Math.max(64 * Appearance.effectiveScale, sourceLinkRow.implicitHeight)
                        orientation: Qt.Vertical
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
                                id: sourceLinkRow
                                anchors.fill: parent
                                anchors {
                                    leftMargin: 16 * Appearance.effectiveScale
                                    rightMargin: 16 * Appearance.effectiveScale
                                }
                                spacing: 16 * Appearance.effectiveScale

                                MaterialSymbol {
                                    text: "code"
                                    iconSize: 24 * Appearance.effectiveScale
                                    color: Appearance.colors.colPrimary
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: I18nService.tr("Source Code")
                                    color: Appearance.colors.colOnLayer1
                                }
                                StyledText {
                                    text: I18nService.tr("GitHub Repository")
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colPrimary
                                }
                            }
                        }
                    }

                    SegmentedWrapper {
                        id: creditsLinkWrapper
                        Layout.fillWidth: true
                        implicitHeight: Math.max(64 * Appearance.effectiveScale, creditsLinkRow.implicitHeight)
                        orientation: Qt.Vertical
                        color: Appearance.m3colors.m3surfaceContainerHigh

                        RippleButton {
                            anchors.fill: parent
                            colBackground: "transparent"
                            onClicked: pushView("credits")

                            SearchHandler {
                                searchString: "Special Thanks"
                                aliases: ["Credits"]
                            }

                            // Explicitly inherit radii from SegmentedWrapper for hover alignment
                            topLeftRadius: creditsLinkWrapper.rTopLeft
                            topRightRadius: creditsLinkWrapper.rTopRight
                            bottomLeftRadius: creditsLinkWrapper.rBottomLeft
                            bottomRightRadius: creditsLinkWrapper.rBottomRight

                            RowLayout {
                                id: creditsLinkRow
                                anchors.fill: parent
                                anchors {
                                    leftMargin: 16 * Appearance.effectiveScale
                                    rightMargin: 16 * Appearance.effectiveScale
                                }
                                spacing: 16 * Appearance.effectiveScale

                                MaterialSymbol {
                                    text: "favorite"
                                    iconSize: 24 * Appearance.effectiveScale
                                    color: "#ff4081"
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: I18nService.tr("Special Thanks")
                                    color: Appearance.colors.colOnLayer1
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

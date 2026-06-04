import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import "pages"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

/**
 * Main Onboarding Application Window.
 * Guides new users through Nandoroid's features.
 */
Scope {
    id: root

    FloatingWindow {
        id: onboardingWindow
        visible: GlobalStates.onboardingOpen
        title: "Welcome to NAnDoroid"
        
        readonly property var screen: Quickshell.screens[0]

        color: "transparent"

        implicitWidth: Math.min(1100 * Appearance.effectiveScale, screen.width * 0.85)
        implicitHeight: Math.min(800 * Appearance.effectiveScale, screen.height * 0.8)

        onVisibleChanged: {
            if (!visible) {
                GlobalStates.onboardingOpen = false;
            }
        }

        // Reset to first page when opened
        Connections {
            target: GlobalStates
            function onOnboardingOpenChanged() {
                if (!GlobalStates.onboardingOpen) {
                    Config.options.system.onboardingCompleted = true;
                    // reset step when closed
                    GlobalStates.onboardingStep = 0;
                }
            }
        }

        Component.onCompleted: {
            MaterialThemeLoader.reapplyTheme()
        }

        Rectangle {
            id: contentContainer
            anchors.fill: parent

            focus: visible
            Keys.onEscapePressed: GlobalStates.onboardingOpen = false

            color: Appearance.colors.colLayer0
            border.color: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.12)
            border.width: Math.max(1, 1 * Appearance.effectiveScale)
            radius: 20 * Appearance.effectiveScale

            TapHandler {}

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24 * Appearance.effectiveScale
                spacing: 24 * Appearance.effectiveScale

                // ── Global Header ──
                Item {
                    id: headerWrapper
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52 * Appearance.effectiveScale

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20 * Appearance.effectiveScale
                        anchors.rightMargin: 0
                        spacing: 20 * Appearance.effectiveScale

                        StyledText {
                            text: "Welcome to NAnDoroid"
                            font.pixelSize: 24 * Appearance.effectiveScale
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer0
                            Layout.alignment: Qt.AlignVCenter
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Item {
                            Layout.preferredWidth: 200 * Appearance.effectiveScale
                            Layout.fillHeight: true

                            RippleButton {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: 36 * Appearance.effectiveScale
                                implicitHeight: 36 * Appearance.effectiveScale
                                buttonRadius: 18 * Appearance.effectiveScale
                                colBackground: "transparent"
                                onClicked: GlobalStates.onboardingOpen = false
                                
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "close"
                                    iconSize: 22 * Appearance.effectiveScale
                                    color: Appearance.colors.colSubtext
                                }
                            }
                        }
                    }
                }

                // Main Content Area
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Appearance.colors.colLayer1
                    radius: 28 * Appearance.effectiveScale
                    clip: true

                    Loader {
                        id: stepLoader
                        anchors.fill: parent
                        anchors.margins: 24 * Appearance.effectiveScale
                        
                        source: {
                            switch(GlobalStates.onboardingStep) {
                                case 0: return "pages/IntroStep.qml";
                                case 1: return "pages/DependencyStep.qml";
                                case 2: return "pages/WelcomeStep.qml";
                                case 3: return "pages/IslandStep.qml";
                                case 4: return "pages/GesturesStep.qml";
                                case 5: return "pages/IpcStep.qml";
                                case 6: return "pages/FinishStep.qml";
                                default: return "pages/FinishStep.qml";
                            }
                        }
                    }
                }
                
                // Footer Navigation
                RowLayout {
                    Layout.fillWidth: true
                    visible: GlobalStates.onboardingStep > 0
                    
                    RippleButton {
                        implicitWidth: 120 * Appearance.effectiveScale
                        implicitHeight: 40 * Appearance.effectiveScale
                        buttonRadius: 20 * Appearance.effectiveScale
                        colBackground: Appearance.colors.colLayer1
                        visible: GlobalStates.onboardingStep > 0
                        onClicked: GlobalStates.onboardingStep--
                        
                        StyledText {
                            anchors.centerIn: parent
                            text: "Back"
                            font.pixelSize: 14 * Appearance.effectiveScale
                            color: Appearance.colors.colOnLayer1
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    RippleButton {
                        implicitWidth: 120 * Appearance.effectiveScale
                        implicitHeight: 40 * Appearance.effectiveScale
                        buttonRadius: 20 * Appearance.effectiveScale
                        colBackground: Appearance.colors.colPrimary
                        onClicked: {
                            if (GlobalStates.onboardingStep >= 6) {
                                Config.options.system.onboardingCompleted = true;
                                GlobalStates.onboardingOpen = false;
                            } else {
                                GlobalStates.onboardingStep++;
                            }
                        }
                        
                        StyledText {
                            anchors.centerIn: parent
                            text: GlobalStates.onboardingStep === 0 ? "Start" : (GlobalStates.onboardingStep >= 6 ? "Finish" : "Next")
                            font.pixelSize: 14 * Appearance.effectiveScale
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnPrimary
                        }
                    }
                }
            }
        }
    }
}

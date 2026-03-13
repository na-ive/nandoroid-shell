pragma ComponentBehavior: Bound

import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

/**
 * Polkit authentication panel.
 * Mirroring the 'ii' example's fullscreen overlay style.
 */
Scope {
    id: root

    Loader {
        active: PolkitService.active
        sourceComponent: Variants {
            model: Quickshell.screens
            delegate: PanelWindow {
                id: panelWindow
                required property var modelData
                screen: modelData
                
                readonly property bool isActive: GlobalStates.activeScreen === modelData
                visible: PolkitService.active && isActive

                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }

                color: "transparent"
                WlrLayershell.namespace: "nandoroid:polkit"
                WlrLayershell.keyboardFocus: (PolkitService.active && isActive) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
                WlrLayershell.layer: (PolkitService.active && isActive) ? WlrLayer.Overlay : WlrLayer.Background
                exclusionMode: ExclusionMode.Ignore

                // ── Scrim ──
                Rectangle {
                    anchors.fill: parent
                    color: Functions.ColorUtils.applyAlpha(Appearance.colors.colLayer0, 0.6)
                    opacity: (PolkitService.active && isActive) ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                // ── Auth Dialog ──
                Rectangle {
                    id: dialog
                    anchors.centerIn: parent
                    width: 450
                    implicitHeight: contentCol.implicitHeight + 40
                    radius: Appearance.rounding.card
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    
                    ColumnLayout {
                        id: contentCol
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 20

                        // Icon
                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: "security"
                            iconSize: 32
                            color: Appearance.colors.colPrimary
                        }

                        // Title
                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: qsTr("Authentication Required")
                            font.pixelSize: Appearance.font.pixelSize.large
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnLayer1
                        }

                        // Message
                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: PolkitService.cleanMessage
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colSubtext
                            wrapMode: Text.Wrap
                        }

                        // Password Field Section
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                id: inputContainer
                                Layout.fillWidth: true
                                Layout.preferredHeight: 52
                                radius: 8 // Reduced rounding as requested
                                color: "transparent" // Same as background
                                border.width: passwordInput.activeFocus || PolkitService.failed ? 2 : 1
                                border.color: PolkitService.failed ? Appearance.m3colors.m3error : (passwordInput.activeFocus ? Appearance.m3colors.m3primary : Appearance.m3colors.m3outline)

                                // Floating Label (Simulated)
                                Rectangle {
                                    x: 12
                                    y: -8
                                    width: labelText.width + 8
                                    height: 16
                                    color: Appearance.m3colors.m3surfaceContainerHigh // Match dialog background
                                    
                                    StyledText {
                                        id: labelText
                                        anchors.centerIn: parent
                                        text: qsTr("Password")
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        font.weight: Font.Medium
                                        color: PolkitService.failed ? Appearance.m3colors.m3error : (passwordInput.activeFocus ? Appearance.m3colors.m3primary : Appearance.m3colors.m3outline)
                                    }
                                }

                                TextInput {
                                    id: passwordInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    verticalAlignment: TextInput.AlignVCenter
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnLayer1
                                    echoMode: PolkitService.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                                    selectionColor: Appearance.colors.colPrimary
                                    enabled: PolkitService.interactionAvailable
                                    
                                    focus: true
                                    onAccepted: PolkitService.submit(text)
                                    onTextChanged: if (PolkitService.failed) PolkitService.failed = false

                                    Text {
                                        anchors.centerIn: parent
                                        visible: !passwordInput.text && !passwordInput.activeFocus
                                        text: PolkitService.cleanPrompt
                                        color: Appearance.colors.colSubtext
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                    }
                                }
                            }

                            // Error Message
                            StyledText {
                                Layout.fillWidth: true
                                visible: PolkitService.failed
                                text: qsTr("Authentication failed, please try again")
                                color: Appearance.m3colors.m3error
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                horizontalAlignment: Text.AlignLeft
                                leftPadding: 4
                            }
                        }

                        // Buttons
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 12
                            spacing: 12

                            Item { Layout.fillWidth: true }

                            RippleButton {
                                Layout.preferredWidth: 100
                                Layout.preferredHeight: 40
                                buttonRadius: Appearance.rounding.button
                                buttonText: qsTr("Cancel")
                                colBackground: "transparent"
                                colBackgroundHover: Appearance.colors.colLayer2Hover
                                onClicked: PolkitService.cancel()
                            }

                            RippleButton {
                                Layout.preferredWidth: 100
                                Layout.preferredHeight: 40
                                buttonRadius: Appearance.rounding.button
                                buttonText: qsTr("OK")
                                colBackground: Appearance.colors.colPrimary
                                colText: Appearance.colors.colOnPrimary
                                enabled: PolkitService.interactionAvailable
                                onClicked: PolkitService.submit(passwordInput.text)
                            }
                        }
                    }

                    // Key Handling
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            PolkitService.cancel();
                            event.accepted = true;
                        }
                    }

                    Connections {
                        target: PolkitService
                        function onInteractionAvailableChanged() {
                            if (PolkitService.interactionAvailable) {
                                passwordInput.text = "";
                                passwordInput.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }
    }
}

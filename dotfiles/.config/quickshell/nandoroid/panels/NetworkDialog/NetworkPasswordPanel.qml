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
 * WiFi password prompt — fullscreen overlay like PolkitPanel / AddNetworkPanel.
 * Opened from Settings → Network for unsaved secured networks.
 */
Scope {
    id: root

    // Apply "connect automatically = off" once the connection exists.
    Timer {
        id: autoconnectOffTimer
        interval: 4000
        repeat: false
        property string ssid: ""
        onTriggered: if (ssid !== "") Network.setAutoConnect(ssid, false)
    }

    Loader {
        active: GlobalStates.networkPasswordDialogOpen
        sourceComponent: Variants {
            model: Quickshell.screens
            delegate: PanelWindow {
                id: panelWindow
                required property var modelData
                screen: modelData

                readonly property bool isActive: GlobalStates.activeScreen === modelData
                readonly property var target: GlobalStates.networkPasswordTarget
                visible: GlobalStates.networkPasswordDialogOpen && isActive

                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }

                color: "transparent"
                WlrLayershell.namespace: "nandoroid:networkpassword"
                WlrLayershell.keyboardFocus: (GlobalStates.networkPasswordDialogOpen && isActive) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
                WlrLayershell.layer: (GlobalStates.networkPasswordDialogOpen && isActive) ? WlrLayer.Overlay : WlrLayer.Background
                exclusionMode: ExclusionMode.Ignore

                // Local dialog state (per-screen copy)
                property bool showPassword: false
                property bool autoconnect: true
                property bool failed: false

                function closeDialog() {
                    passInput.text = "";
                    panelWindow.showPassword = false;
                    panelWindow.autoconnect = true;
                    panelWindow.failed = false;
                    GlobalStates.closeNetworkPassword();
                }

                readonly property bool editMode: GlobalStates.networkPasswordEditMode

                function tryConnect() {
                    const t = panelWindow.target;
                    if (!t) return;
                    if (passInput.text.length === 0) {
                        panelWindow.failed = true;
                        return;
                    }
                    if (panelWindow.editMode) {
                        // Save new PSK into the stored profile (reconnect if active).
                        Network.updateConnectionPassword(t.ssid, passInput.text, !!t.active);
                        panelWindow.closeDialog();
                        return;
                    }
                    Network.connectWithPassword(t.ssid, passInput.text, false, panelWindow.autoconnect);
                    if (!panelWindow.autoconnect) {
                        autoconnectOffTimer.ssid = t.ssid;
                        autoconnectOffTimer.restart();
                    }
                    // Stay open: auto-close on success, show error on failure.
                }

                Connections {
                    target: Network
                    function onWifiNetworksChanged() {
                        const t = panelWindow.target;
                        if (!t || panelWindow.editMode || !GlobalStates.networkPasswordDialogOpen) return;
                        if (t.askingPassword) {
                            t.askingPassword = false;
                            panelWindow.failed = true;
                        } else if (Network.activeNetwork && Network.activeNetwork.ssid === t.ssid) {
                            panelWindow.closeDialog();
                        }
                    }
                }

                Connections {
                    target: GlobalStates
                    function onNetworkPasswordDialogOpenChanged() {
                        if (GlobalStates.networkPasswordDialogOpen) {
                            panelWindow.failed = false;
                            panelWindow.autoconnect = true;
                            Qt.callLater(() => {
                                const t = panelWindow.target;
                                if (t && (t.isSecure || panelWindow.editMode)) passInput.forceActiveFocus();
                            });
                        }
                    }
                }

                // Close when clicking outside
                MouseArea {
                    anchors.fill: parent
                    onClicked: panelWindow.closeDialog()
                }

                // Esc to close
                Shortcut {
                    sequence: "Escape"
                    onActivated: panelWindow.closeDialog()
                    enabled: panelWindow.visible
                }

                // Scrim (fullscreen)
                Rectangle {
                    anchors.fill: parent
                    color: Functions.ColorUtils.applyAlpha(Appearance.colors.colLayer0, 0.6)
                    opacity: (GlobalStates.networkPasswordDialogOpen && isActive) ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                // Dialog content: same metrics as PolkitPanel.
                Rectangle {
                    id: dialog
                    anchors.centerIn: parent
                    width: Math.max(280 * Appearance.effectiveScale, Math.min(parent.width - 48 * Appearance.effectiveScale, 560 * Appearance.effectiveScale))
                    implicitHeight: contentCol.implicitHeight + (48 * Appearance.effectiveScale)
                    radius: 28 * Appearance.effectiveScale
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    StyledRectangularShadow {
                        target: dialog
                        z: -1
                    }

                    MouseArea {
                        anchors.fill: parent
                        // Prevent click-through to the background scrim
                    }

                    ColumnLayout {
                        id: contentCol
                        anchors.fill: parent
                        anchors.margins: 24 * Appearance.effectiveScale
                        spacing: 0

                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: panelWindow.editMode ? "edit" : "wifi_password"
                            iconSize: 24 * Appearance.effectiveScale
                            color: Appearance.m3colors.m3secondary
                        }

                        StyledText {
                            Layout.fillWidth: true
                            Layout.topMargin: 16 * Appearance.effectiveScale
                            horizontalAlignment: Text.AlignHCenter
                            text: panelWindow.target ? panelWindow.target.ssid : ""
                            font.pixelSize: Appearance.font.pixelSize.huge
                            font.family: Appearance.font.family.title
                            font.weight: Font.Normal
                            color: Appearance.colors.colOnLayer1
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            Layout.topMargin: 16 * Appearance.effectiveScale
                            horizontalAlignment: Text.AlignHCenter
                            text: panelWindow.editMode ? I18nService.tr("Update the password saved for this network.") : I18nService.tr("Enter the password to connect to this network.")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.m3colors.m3onSurfaceVariant
                            wrapMode: Text.Wrap
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 24 * Appearance.effectiveScale
                            spacing: 8 * Appearance.effectiveScale

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 52 * Appearance.effectiveScale
                                radius: 8 * Appearance.effectiveScale
                                color: "transparent"
                                border.width: passInput.input.activeFocus || panelWindow.failed ? Math.max(1, 2 * Appearance.effectiveScale) : Math.max(1, 1 * Appearance.effectiveScale)
                                border.color: panelWindow.failed ? Appearance.m3colors.m3error : (passInput.input.activeFocus ? Appearance.m3colors.m3primary : Appearance.m3colors.m3outline)

                                Rectangle {
                                    x: 12 * Appearance.effectiveScale
                                    y: -8 * Appearance.effectiveScale
                                    width: labelText.width + (8 * Appearance.effectiveScale)
                                    height: 16 * Appearance.effectiveScale
                                    color: Appearance.m3colors.m3surfaceContainerHigh

                                    StyledText {
                                        id: labelText
                                        anchors.centerIn: parent
                                        text: I18nService.tr("Password")
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        font.weight: Font.Medium
                                        color: panelWindow.failed ? Appearance.m3colors.m3error : (passInput.input.activeFocus ? Appearance.m3colors.m3primary : Appearance.m3colors.m3outline)
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16 * Appearance.effectiveScale
                                    anchors.rightMargin: 8 * Appearance.effectiveScale

                                    StyledTextInput {
                                        id: passInput
                                        Layout.fillWidth: true
                                        echoMode: panelWindow.showPassword ? TextInput.Normal : TextInput.Password
                                        placeholder: I18nService.tr("Enter Password...")
                                        backgroundColor: "transparent"
                                        inputRadius: 0
                                        showActiveBorder: false
                                        borderInactiveWidth: 0
                                        leftMargin: 0
                                        rightMargin: 0
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                        onAccepted: panelWindow.tryConnect()
                                        onTextChanged: if (panelWindow.failed) panelWindow.failed = false
                                    }

                                    RippleButton {
                                        implicitWidth: 32 * Appearance.effectiveScale
                                        implicitHeight: 32 * Appearance.effectiveScale
                                        buttonRadius: 16 * Appearance.effectiveScale
                                        colBackground: "transparent"
                                        onClicked: panelWindow.showPassword = !panelWindow.showPassword
                                        contentItem: MaterialSymbol {
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            text: panelWindow.showPassword ? "visibility_off" : "visibility"
                                            iconSize: 20 * Appearance.effectiveScale
                                            color: Appearance.colors.colSubtext
                                        }
                                    }
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                visible: panelWindow.failed
                                text: I18nService.tr("Wrong password or connection failed, please try again")
                                color: Appearance.m3colors.m3error
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                leftPadding: 4 * Appearance.effectiveScale
                            }
                        }

                        StyledCheckbox {
                            Layout.fillWidth: true
                            Layout.topMargin: 16 * Appearance.effectiveScale
                            visible: !panelWindow.editMode
                            text: I18nService.tr("Connect automatically")
                            checked: panelWindow.autoconnect
                            onToggled: panelWindow.autoconnect = checked
                            textColor: Appearance.colors.colOnLayer1
                            font.pixelSize: Appearance.font.pixelSize.normal
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 24 * Appearance.effectiveScale
                            spacing: 8 * Appearance.effectiveScale

                            Item { Layout.fillWidth: true }

                            RippleButton {
                                implicitHeight: 40 * Appearance.effectiveScale
                                buttonRadius: 20 * Appearance.effectiveScale
                                buttonText: I18nService.tr("Cancel")
                                colBackground: "transparent"
                                colBackgroundHover: Appearance.colors.colLayer2Hover
                                colText: Appearance.m3colors.m3primary
                                onClicked: panelWindow.closeDialog()
                            }

                            RippleButton {
                                implicitHeight: 40 * Appearance.effectiveScale
                                buttonRadius: 20 * Appearance.effectiveScale
                                buttonText: panelWindow.editMode ? I18nService.tr("Save") : I18nService.tr("Connect")
                                colBackground: "transparent"
                                colBackgroundHover: Appearance.colors.colLayer2Hover
                                colText: Appearance.m3colors.m3primary
                                enabled: passInput.text.length > 0
                                onClicked: panelWindow.tryConnect()
                            }
                        }
                    }
                }
            }
        }
    }
}

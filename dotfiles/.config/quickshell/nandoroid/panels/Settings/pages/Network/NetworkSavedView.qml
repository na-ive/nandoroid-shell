import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

                // Tap = details only; arrow button = Forget / Share actions.
                ColumnLayout {
                    id: savedViewCol
                    Layout.fillWidth: true
                    visible: root.currentView === "saved"
                    spacing: 24 * Appearance.effectiveScale

                    StyledText {
                        text: I18nService.tr("You have ") + Network.savedConnections.length + I18nService.tr(" saved networks")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colSubtext
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2 * Appearance.effectiveScale

                        Repeater {
                            model: Network.savedConnections
                            delegate: SegmentedWrapper {
                                id: segSaved
                                Layout.fillWidth: true
                                orientation: Qt.Vertical
                                forceFirst: index === 0
                                forceLast: index === Network.savedConnections.length - 1
                                color: Appearance.m3colors.m3surfaceContainerHigh
                                implicitHeight: savedInner.implicitHeight

                                ColumnLayout {
                                    id: savedInner
                                    width: parent.width
                                    spacing: 0
                                    property bool expanded: false

                                    RippleButton {
                                        Layout.fillWidth: true
                                        implicitHeight: 64 * Appearance.effectiveScale
                                        topLeftRadius: segSaved.rTopLeft
                                        topRightRadius: segSaved.rTopRight
                                        bottomLeftRadius: savedInner.expanded ? 0 : segSaved.rBottomLeft
                                        bottomRightRadius: savedInner.expanded ? 0 : segSaved.rBottomRight
                                        colBackground: "transparent"
                                        colBackgroundHover: Appearance.colors.colLayer1Hover
                                        onClicked: root.openSavedDetails(modelData)

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16 * Appearance.effectiveScale
                                            anchors.rightMargin: 16 * Appearance.effectiveScale
                                            spacing: 16 * Appearance.effectiveScale

                                            MaterialSymbol {
                                                text: "wifi"
                                                iconSize: 24 * Appearance.effectiveScale
                                                color: Appearance.colors.colSubtext
                                            }

                                            StyledText {
                                                text: modelData
                                                font.pixelSize: Appearance.font.pixelSize.normal
                                                color: Appearance.colors.colOnLayer1
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }

                                            // Inner button only expands actions (consumes the tap)
                                            RippleButton {
                                                implicitWidth: 32 * Appearance.effectiveScale
                                                implicitHeight: 32 * Appearance.effectiveScale
                                                buttonRadius: 16 * Appearance.effectiveScale
                                                colBackground: "transparent"
                                                onClicked: savedInner.expanded = !savedInner.expanded
                                                contentItem: MaterialSymbol {
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                    text: "settings"
                                                    iconSize: 20 * Appearance.effectiveScale
                                                    color: Appearance.colors.colSubtext
                                                    rotation: savedInner.expanded ? 180 : 0
                                                    Behavior on rotation { NumberAnimation { duration: 200 } }
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: savedInner.expanded ? (savedActionCol.implicitHeight + 24 * Appearance.effectiveScale) : 0
                                        visible: Layout.preferredHeight > 0
                                        clip: true
                                        color: Appearance.colors.colLayer2
                                        Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                                        ColumnLayout {
                                            id: savedActionCol
                                            anchors.fill: parent
                                            anchors.margins: 16 * Appearance.effectiveScale
                                            spacing: 16 * Appearance.effectiveScale

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 12 * Appearance.effectiveScale

                                                StyledText {
                                                    id: savedPassLabel
                                                    visible: text.length > 0
                                                    text: ""
                                                    font.pixelSize: Appearance.font.pixelSize.small
                                                    color: Appearance.colors.colPrimary
                                                    font.weight: Font.DemiBold
                                                    Layout.alignment: Qt.AlignVCenter
                                                    Layout.fillWidth: true
                                                    wrapMode: Text.WrapAnywhere
                                                }

                                                Item { Layout.fillWidth: true; visible: savedPassLabel.text.length === 0 }

                                                RippleButton {
                                                    buttonText: I18nService.tr("Forget")
                                                    implicitWidth: 90 * Appearance.effectiveScale
                                                    implicitHeight: 36 * Appearance.effectiveScale
                                                    buttonRadius: 18 * Appearance.effectiveScale
                                                    colBackground: Appearance.m3colors.m3error
                                                    colText: Appearance.m3colors.m3onError
                                                    onClicked: Network.forgetNetwork(modelData)
                                                }

                                                RippleButton {
                                                    buttonText: savedPassLabel.text.length > 0 ? I18nService.tr("Hide") : I18nService.tr("Share")
                                                    implicitWidth: 100 * Appearance.effectiveScale
                                                    implicitHeight: 36 * Appearance.effectiveScale
                                                    buttonRadius: 18 * Appearance.effectiveScale
                                                    colBackground: Appearance.colors.colPrimary
                                                    colText: Appearance.colors.colOnPrimary
                                                    onClicked: {
                                                        if (savedPassLabel.text.length > 0) {
                                                            savedPassLabel.text = "";
                                                        } else {
                                                            Network.getSavedPassword(modelData);
                                                        }
                                                    }
                                                }
                                            }

                                            Connections {
                                                target: Network
                                                function onPasswordRecovered(password) {
                                                    if (savedInner.expanded) {
                                                        savedPassLabel.text = I18nService.tr("Password: ") + password;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } // End savedViewCol

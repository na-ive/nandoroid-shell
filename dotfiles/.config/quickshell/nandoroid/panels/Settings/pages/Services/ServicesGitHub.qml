import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

/**
 * Services Settings — GitHub Configuration
 * Adds GitHub username and API token fields for the Dashboard GitHub tracker.
 */
ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 4

    // Section Header
    RowLayout {
        spacing: 12
        Layout.bottomMargin: 8
        MaterialSymbol {
            text: "code"
            iconSize: 24
            color: Appearance.colors.colPrimary
        }
        StyledText {
            text: "GitHub"
            font.pixelSize: Appearance.font.pixelSize.large
            font.weight: Font.Medium
            color: Appearance.colors.colOnLayer1
        }
    }

    StyledText {
        text: "Configure your GitHub account for the Dashboard GitHub tracker. An API token is required for private repositories."
        font.pixelSize: Appearance.font.pixelSize.small
        color: Appearance.colors.colSubtext
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.bottomMargin: 8
    }

    // Settings card
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: cardCol.implicitHeight + 32
        radius: Appearance.rounding.normal
        color: Appearance.m3colors.m3surfaceContainerHigh

        ColumnLayout {
            id: cardCol
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Username field
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                StyledText {
                    text: "GitHub Username"
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 44
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer1
                    border.color: usernameField.activeFocus
                        ? Appearance.colors.colPrimary
                        : Appearance.colors.colOutlineVariant
                    border.width: usernameField.activeFocus ? 2 : 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        MaterialSymbol {
                            text: "person"
                            iconSize: 18
                            color: Appearance.colors.colSubtext
                        }

                        TextInput {
                            id: usernameField
                            Layout.fillWidth: true
                            text: Config.ready && Config.options.github ? Config.options.github.githubUsername : ""
                            font.family: Appearance.font.family.main
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                            verticalAlignment: TextInput.AlignVCenter
                            onEditingFinished: {
                                if (Config.ready && Config.options.github)
                                    Config.options.github.githubUsername = text
                            }

                            StyledText {
                                anchors.fill: parent
                                text: "e.g. octocat"
                                color: Appearance.colors.colSubtext
                                visible: !parent.text && !parent.activeFocus
                                font.pixelSize: Appearance.font.pixelSize.normal
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
            }

            // Separator
            Rectangle {
                Layout.fillWidth: true; height: 1
                color: Appearance.colors.colOutlineVariant; opacity: 0.4
            }

            // Token field
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    StyledText {
                        text: "Personal Access Token"
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                        Layout.fillWidth: true
                    }
                    StyledText {
                        text: "Optional · for private repos"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 44
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer1
                    border.color: tokenField.activeFocus
                        ? Appearance.colors.colPrimary
                        : Appearance.colors.colOutlineVariant
                    border.width: tokenField.activeFocus ? 2 : 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        MaterialSymbol {
                            text: "key"
                            iconSize: 18
                            color: Appearance.colors.colSubtext
                        }

                        TextInput {
                            id: tokenField
                            Layout.fillWidth: true
                            text: Config.ready && Config.options.github ? Config.options.github.githubToken : ""
                            echoMode: showToken.checked ? TextInput.Normal : TextInput.Password
                            font.family: Appearance.font.family.main
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                            verticalAlignment: TextInput.AlignVCenter
                            onEditingFinished: {
                                if (Config.ready && Config.options.github)
                                    Config.options.github.githubToken = text
                            }

                            StyledText {
                                anchors.fill: parent
                                text: "ghp_xxxxxxxxxxxxxxxxxxxx"
                                color: Appearance.colors.colSubtext
                                visible: !parent.text && !parent.activeFocus
                                font.pixelSize: Appearance.font.pixelSize.normal
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        // Toggle visibility
                        RippleButton {
                            property bool checked: false
                            implicitWidth: 32; implicitHeight: 32; buttonRadius: 16
                            colBackground: "transparent"
                            onClicked: checked = !checked
                            id: showToken
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: showToken.checked ? "visibility_off" : "visibility"
                                iconSize: 18
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }
                }

                StyledText {
                    text: "Create a token at GitHub → Settings → Developer settings → Personal access tokens"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    opacity: 0.8
                }
            }
        }
    }
}

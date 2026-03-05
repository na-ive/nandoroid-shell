import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

/**
 * Services Settings — GitHub Configuration
 * Matches the SegmentedWrapper style used by ServicesWeather etc.
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
        text: "Configure your GitHub account for the Dashboard GitHub tracker. A Personal Access Token is required for private repos and the contribution heatmap."
        font.pixelSize: Appearance.font.pixelSize.small
        color: Appearance.colors.colSubtext
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.bottomMargin: 8
    }

    // ── Username card (top, full radius) ──
    SegmentedWrapper {
        Layout.fillWidth: true
        implicitHeight: usernameContent.implicitHeight + 40
        orientation: Qt.Vertical
        color: Appearance.m3colors.m3surfaceContainerHigh
        smallRadius: 8
        fullRadius: 20

        RowLayout {
            id: usernameContent
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            MaterialSymbol {
                text: "person"
                iconSize: 18
                color: Appearance.colors.colSubtext
            }

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                StyledText {
                    text: "GitHub Username"
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
                TextInput {
                    id: usernameField
                    Layout.fillWidth: true
                    text: Config.ready && Config.options.github ? Config.options.github.githubUsername : ""
                    font.family: Appearance.font.family.main
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                    selectionColor: Appearance.colors.colPrimaryContainer
                    selectedTextColor: Appearance.colors.colOnPrimaryContainer
                    clip: true
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

    // ── Personal Access Token card (bottom, full radius) ──
    SegmentedWrapper {
        Layout.fillWidth: true
        implicitHeight: tokenContent.implicitHeight + 40
        orientation: Qt.Vertical
        color: Appearance.m3colors.m3surfaceContainerHigh
        smallRadius: 8
        fullRadius: 20

        ColumnLayout {
            id: tokenContent
            anchors.fill: parent
            anchors.margins: 20
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                MaterialSymbol {
                    text: "key"
                    iconSize: 18
                    color: Appearance.colors.colSubtext
                }

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true

                    RowLayout {
                        Layout.fillWidth: true
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

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        TextInput {
                            id: tokenField
                            Layout.fillWidth: true
                            // clip so the dots don't overflow the container
                            clip: true
                            text: Config.ready && Config.options.github ? Config.options.github.githubToken : ""
                            echoMode: showToken.showingToken ? TextInput.Normal : TextInput.Password
                            font.family: Appearance.font.family.main
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                            selectionColor: Appearance.colors.colPrimaryContainer
                            selectedTextColor: Appearance.colors.colOnPrimaryContainer
                            onEditingFinished: {
                                if (Config.ready && Config.options.github)
                                    Config.options.github.githubToken = text
                            }
                            StyledText {
                                anchors.fill: parent
                                text: "ghp_xxxxxxxxxxxx"
                                color: Appearance.colors.colSubtext
                                visible: !parent.text && !parent.activeFocus
                                font.pixelSize: Appearance.font.pixelSize.normal
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                        RippleButton {
                            id: showToken
                            property bool showingToken: false
                            implicitWidth: 28; implicitHeight: 28; buttonRadius: 14
                            colBackground: "transparent"
                            onClicked: showingToken = !showingToken
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: showToken.showingToken ? "visibility_off" : "visibility"
                                iconSize: 16
                                color: Appearance.colors.colSubtext
                            }
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
                opacity: 0.75
            }
        }
    }
}

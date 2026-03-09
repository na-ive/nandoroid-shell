import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

/**
 * Services Settings — GitHub Configuration
 * Field style matches ServicesDisk: Rectangle { radius:12; color:m3surfaceContainerLow }
 */
ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 4
    
    SearchHandler { searchString: "GitHub" }

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

    // ── Username card ──
    SegmentedWrapper {
        Layout.fillWidth: true
        implicitHeight: usernameInner.implicitHeight + 40
        orientation: Qt.Vertical
        color: Appearance.m3colors.m3surfaceContainerHigh
        smallRadius: 8
        fullRadius: 20

        ColumnLayout {
            id: usernameInner
            anchors.fill: parent
            anchors.margins: 20
            spacing: 8

            RowLayout {
                spacing: 10
                MaterialSymbol {
                    text: "person"
                    iconSize: 18
                    color: Appearance.colors.colSubtext
                    Layout.alignment: Qt.AlignVCenter
                }
                StyledText {
                    text: "GitHub Username"
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }
            }

            // Input field — disk-monitoring style
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: 12
                color: Appearance.m3colors.m3surfaceContainerLow
                border.width: usernameField.activeFocus ? 2 : 0
                border.color: Appearance.colors.colPrimary

                TextInput {
                    id: usernameField
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    text: Config.ready && Config.options.github ? Config.options.github.githubUsername : ""
                    font.family: Appearance.font.family.main
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                    selectionColor: Appearance.colors.colPrimaryContainer
                    selectedTextColor: Appearance.colors.colOnPrimaryContainer
                    onEditingFinished: {
                        if (Config.ready && Config.options.github)
                            Config.options.github.githubUsername = text
                    }

                    StyledText {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "e.g. octocat"
                        color: Appearance.colors.colSubtext
                        visible: parent.text === "" && !parent.activeFocus
                        font.pixelSize: Appearance.font.pixelSize.normal
                    }
                }
            }
        }
    }

    // ── Personal Access Token card ──
    SegmentedWrapper {
        Layout.fillWidth: true
        implicitHeight: tokenInner.implicitHeight + 40
        orientation: Qt.Vertical
        color: Appearance.m3colors.m3surfaceContainerHigh
        smallRadius: 8
        fullRadius: 20

        ColumnLayout {
            id: tokenInner
            anchors.fill: parent
            anchors.margins: 20
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                MaterialSymbol {
                    text: "key"
                    iconSize: 18
                    color: Appearance.colors.colSubtext
                    Layout.alignment: Qt.AlignVCenter
                }
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

            // Input field — disk-monitoring style with show/hide toggle
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: 12
                color: Appearance.m3colors.m3surfaceContainerLow
                border.width: tokenField.activeFocus ? 2 : 0
                border.color: Appearance.colors.colPrimary

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 8
                    spacing: 4

                    TextInput {
                        id: tokenField
                        Layout.fillWidth: true
                        verticalAlignment: TextInput.AlignVCenter
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
                            verticalAlignment: Text.AlignVCenter
                            text: "ghp_xxxxxxxxxxxx"
                            color: Appearance.colors.colSubtext
                            visible: parent.text === "" && !parent.activeFocus
                            font.pixelSize: Appearance.font.pixelSize.normal
                        }
                    }

                    RippleButton {
                        id: showToken
                        property bool showingToken: false
                        implicitWidth: 32; implicitHeight: 32; buttonRadius: 16
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

            // Help text — aligned with the input field (no leading filler)
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

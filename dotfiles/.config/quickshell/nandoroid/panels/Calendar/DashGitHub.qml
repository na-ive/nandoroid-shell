import "../../core"
import "../../widgets"
import "../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

/**
 * Dashboard Tab 4: GitHub Profile Tracker
 * Fetches profile + repos via curl. Supports API token for private repos.
 */
Item {
    id: root

    readonly property string username: Config.ready && Config.options.github ? (Config.options.github.githubUsername || "") : ""
    readonly property string token: Config.ready && Config.options.github ? (Config.options.github.githubToken || "") : ""

    property var profile: null
    property var repos: []
    property bool loading: false
    property string errorMsg: ""

    function fetch() {
        if (!username) return
        root.profile = null
        root.repos = []
        root.errorMsg = ""
        root.loading = true
        profileProc.running = false
        profileProc.running = true
    }

    onUsernameChanged: fetch()
    Component.onCompleted: fetch()

    // ── Profile fetch ──
    Process {
        id: profileProc
        command: {
            let args = ["curl", "-s", "-f"]
            if (root.token) args = args.concat(["-H", "Authorization: token " + root.token])
            return args.concat(["https://api.github.com/users/" + root.username])
        }
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.profile = JSON.parse(this.text)
                    reposProc.running = true
                } catch(e) {
                    root.errorMsg = "Failed to load profile"
                    root.loading = false
                }
            }
        }
        onExited: (code) => { if (code !== 0) { root.errorMsg = "Network error"; root.loading = false } }
    }

    // ── Repos fetch ──
    Process {
        id: reposProc
        command: {
            let args = ["curl", "-s", "-f"]
            if (root.token) args = args.concat(["-H", "Authorization: token " + root.token])
            return args.concat(["https://api.github.com/users/" + root.username + "/repos?sort=pushed&per_page=6&type=all"])
        }
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.repos = JSON.parse(this.text)
                } catch(e) {}
                root.loading = false
            }
        }
        onExited: (code) => { root.loading = false }
    }

    // ── Empty state (no username) ──
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 16
        visible: !root.username && !root.loading

        MaterialSymbol { Layout.alignment: Qt.AlignHCenter; text: "code"; iconSize: 56; color: Appearance.colors.colSubtext }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "GitHub Profile Tracker"
            font.pixelSize: Appearance.font.pixelSize.large
            font.weight: Font.Bold
            color: Appearance.colors.colOnLayer1
        }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            text: "Configure your GitHub username in\nSettings → Services → GitHub"
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.normal
        }
    }

    // ── Loading state ──
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12
        visible: root.loading

        // Spinner
        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 40; implicitHeight: 40

            Rectangle {
                anchors.centerIn: parent
                width: 36; height: 36; radius: 18
                color: "transparent"
                border.color: Appearance.colors.colPrimary
                border.width: 3
                opacity: 0.3
            }

            Rectangle {
                anchors.centerIn: parent
                width: 36; height: 36; radius: 18
                color: "transparent"
                border.color: Appearance.colors.colPrimary
                border.width: 3
                border.color: "transparent"

                Rectangle {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 3; height: 18; radius: 2
                    color: Appearance.colors.colPrimary
                }

                RotationAnimation on rotation {
                    from: 0; to: 360; duration: 800
                    loops: Animation.Infinite; running: root.loading
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "Loading..."
            color: Appearance.colors.colSubtext
        }
    }

    // ── Error state ──
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12
        visible: root.errorMsg !== "" && !root.loading

        MaterialSymbol { Layout.alignment: Qt.AlignHCenter; text: "error_outline"; iconSize: 40; color: Appearance.colors.colError }
        StyledText { Layout.alignment: Qt.AlignHCenter; text: root.errorMsg; color: Appearance.colors.colError }
        RippleButton {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 100; implicitHeight: 36; buttonRadius: 18
            colBackground: Appearance.colors.colLayer1
            onClicked: root.fetch()
            StyledText { anchors.centerIn: parent; text: "Retry"; color: Appearance.colors.colOnLayer1 }
        }
    }

    // ── Profile content ──
    ColumnLayout {
        anchors.fill: parent
        spacing: 12
        visible: root.profile !== null && !root.loading

        // Header profile card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: profileRow.implicitHeight + 24
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            RowLayout {
                id: profileRow
                anchors.fill: parent; anchors.margins: 12
                spacing: 16

                // Avatar
                Rectangle {
                    width: 64; height: 64; radius: 32
                    color: Appearance.colors.colLayer2
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: root.profile ? root.profile.avatar_url : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                // Name + stats
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        text: root.profile ? (root.profile.name || root.profile.login) : ""
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: root.profile ? "@" + root.profile.login : ""
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: root.profile ? (root.profile.bio || "") : ""
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        visible: root.profile && root.profile.bio
                    }
                }

                // Followers / Following
                ColumnLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignVCenter

                    RowLayout {
                        spacing: 4
                        MaterialSymbol { text: "group"; iconSize: 14; color: Appearance.colors.colSubtext }
                        StyledText {
                            text: root.profile ? root.profile.followers + " followers" : ""
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                    }
                    RowLayout {
                        spacing: 4
                        MaterialSymbol { text: "person_add"; iconSize: 14; color: Appearance.colors.colSubtext }
                        StyledText {
                            text: root.profile ? root.profile.following + " following" : ""
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                    }

                    // Refresh button
                    RippleButton {
                        implicitWidth: 30; implicitHeight: 30; buttonRadius: 15
                        colBackground: "transparent"
                        onClicked: root.fetch()
                        MaterialSymbol { anchors.centerIn: parent; text: "refresh"; iconSize: 16; color: Appearance.colors.colSubtext }
                        StyledToolTip { text: "Refresh" }
                    }
                }
            }
        }

        // Repos
        StyledText {
            text: "Repositories"
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer1
        }

        // Repo grid
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 8
            columnSpacing: 8

            Repeater {
                model: root.repos.slice(0, 6)
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    implicitHeight: repoCol.implicitHeight + 16
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer1

                    RippleButton {
                        anchors.fill: parent; buttonRadius: parent.radius; colBackground: "transparent"
                        onClicked: Qt.openUrlExternally(modelData.html_url)
                    }

                    ColumnLayout {
                        id: repoCol
                        anchors.fill: parent; anchors.margins: 10
                        spacing: 3

                        RowLayout {
                            spacing: 4
                            MaterialSymbol {
                                text: modelData.private ? "lock" : "folder_open"
                                iconSize: 13; color: Appearance.colors.colSubtext
                            }
                            StyledText {
                                text: modelData.name
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        StyledText {
                            visible: modelData.description
                            text: modelData.description || ""
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            opacity: 0.8
                        }

                        RowLayout {
                            spacing: 8
                            RowLayout {
                                spacing: 3
                                MaterialSymbol { text: "star"; iconSize: 11; color: Appearance.colors.colSubtext }
                                StyledText { text: modelData.stargazers_count; font.pixelSize: 11; color: Appearance.colors.colSubtext }
                            }
                            StyledText {
                                text: modelData.language || ""
                                font.pixelSize: 11
                                color: Appearance.colors.colPrimary
                                visible: modelData.language
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}

import "../../core"
import "../../widgets"
import "../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import QtQuick.Effects

/**
 * Dashboard Tab 4: GitHub Profile Tracker
 * Fetches user profile and contribution heatmap.
 */
Item {
    id: root
    property string username: (Config.ready && Config.options.github) ? Config.options.github.githubUsername : ""
    property var profile: null
    property var contribWeeks: []
    property int totalContribs: 0
    property var repos: []
    property bool loading: false
    property string errorMsg: ""

    // Matugen colors
    readonly property color contentColor: Appearance.colors.colOnLayer1
    readonly property real midOpacity: 0.7
    readonly property real lowOpacity: 0.45

    onUsernameChanged: { if (username) fetch() }
    Component.onCompleted: { if (username) fetch() }

    function fetch() {
        if (!username) return;
        loading = true;
        errorMsg = "";
        profileProc.running = true;
        reposProc.running = true;
        contribProc.running = true;
    }

    // ── Data Processors ──
    
    // 1. User Profile
    Process {
        id: profileProc
        command: ["sh", "-c", `curl -s -H "Authorization: token ${Config.ready ? Config.options.github.githubToken : ""}" https://api.github.com/users/${root.username}`]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text)
                    if (data.login) root.profile = data
                    else root.errorMsg = data.message || "User not found"
                } catch(e) { root.errorMsg = "Parse error" }
            }
        }
        onExited: (code) => { if (code !== 0) root.errorMsg = "Request failed" }
    }

    // 2. Repositories
    Process {
        id: reposProc
        command: ["sh", "-c", `curl -s -H "Authorization: token ${Config.ready ? Config.options.github.githubToken : ""}" "https://api.github.com/users/${root.username}/repos?sort=updated&per_page=6"`]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text)
                    if (Array.isArray(data)) root.repos = data
                } catch(e) {}
            }
        }
    }

    // 3. Contributions Heatmap (GraphQL for precision)
    Process {
        id: contribProc
        command: ["sh", "-c", `curl -s -H "Authorization: token ${Config.ready ? Config.options.github.githubToken : ""}" -X POST -d '{"query": "query { user(login: \\"${root.username}\\") { contributionsCollection { contributionCalendar { totalContributions weeks { contributionDays { contributionCount color } } } } } }"}' https://api.github.com/graphql`]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text)
                    let cal = data.data.user.contributionsCollection.contributionCalendar
                    root.totalContribs = cal.totalContributions
                    root.contribWeeks = cal.weeks
                } catch(e) {}
                root.loading = false
            }
        }
        onExited: (code) => { root.loading = false }
    }

    // ── Empty state (no username) ──
    ColumnLayout {
        anchors.centerIn: parent; spacing: 16 * Appearance.effectiveScale
        visible: !root.username && !root.loading

        MaterialSymbol { Layout.alignment: Qt.AlignHCenter; text: "hub"; iconSize: 56 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "GitHub Profile Tracker"
            font.pixelSize: Appearance.font.pixelSize.large; font.weight: Font.Bold
            color: Appearance.colors.colOnLayer1
        }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "Set your username in config to track stats"
            color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.normal
        }
    }

    // ── Loading spinner ──
    Item {
        anchors.centerIn: parent; visible: root.loading
        implicitWidth: 44 * Appearance.effectiveScale; implicitHeight: 44 * Appearance.effectiveScale

        Canvas {
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.beginPath(); ctx.arc(width/2, height/2, 16 * Appearance.effectiveScale, 0, Math.PI * 2)
                ctx.strokeStyle = Appearance.m3colors.m3outlineVariant
                ctx.lineWidth = 4 * Appearance.effectiveScale; ctx.stroke()
            }
        }
        Rectangle {
            anchors.centerIn: parent; width: 32 * Appearance.effectiveScale; height: 32 * Appearance.effectiveScale; radius: 16 * Appearance.effectiveScale
            color: "transparent"
            Rectangle {
                anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                width: 4 * Appearance.effectiveScale; height: 16 * Appearance.effectiveScale; radius: 2 * Appearance.effectiveScale; color: Appearance.m3colors.m3primary
            }
            RotationAnimation on rotation {
                from: 0; to: 360; duration: 800
                loops: Animation.Infinite; running: root.loading
            }
        }
    }

    // ── Error state ──
    ColumnLayout {
        anchors.centerIn: parent; spacing: 12 * Appearance.effectiveScale
        visible: root.errorMsg !== "" && !root.loading
        MaterialSymbol { Layout.alignment: Qt.AlignHCenter; text: "error_outline"; iconSize: 40 * Appearance.effectiveScale; color: Appearance.colors.colError }
        StyledText { Layout.alignment: Qt.AlignHCenter; text: root.errorMsg; color: Appearance.colors.colError }
        RippleButton {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 100 * Appearance.effectiveScale; implicitHeight: 36 * Appearance.effectiveScale; buttonRadius: 18 * Appearance.effectiveScale
            colBackground: Appearance.m3colors.m3surfaceContainer
            onClicked: root.fetch()
            StyledText { anchors.centerIn: parent; text: "Retry"; color: Appearance.colors.colOnLayer1 }
        }
    }

    // ── Profile content ──
    ColumnLayout {
        anchors.fill: parent; spacing: 10 * Appearance.effectiveScale
        visible: root.profile !== null && !root.loading

        // ─ Profile header card ─
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: profileRow.implicitHeight + 20 * Appearance.effectiveScale
            radius: Appearance.rounding.normal; color: Appearance.m3colors.m3surfaceContainer

            RowLayout {
                id: profileRow; anchors.fill: parent; anchors.margins: 12 * Appearance.effectiveScale; spacing: 14 * Appearance.effectiveScale

                // Avatar
                Rectangle {
                    id: avatarContainer
                    Layout.preferredWidth: 52 * Appearance.effectiveScale
                    Layout.preferredHeight: 52 * Appearance.effectiveScale
                    width: Layout.preferredWidth
                    height: Layout.preferredHeight
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer2
                    
                    Image {
                        id: avatarImg
                        width: avatarContainer.width
                        height: avatarContainer.height
                        source: root.profile ? root.profile.avatar_url : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: false
                        // Force render size to match scaled container
                        sourceSize.width: avatarContainer.width
                        sourceSize.height: avatarContainer.height
                    }
                    
                    Rectangle {
                        id: avatarMask
                        width: avatarContainer.width
                        height: avatarContainer.height
                        radius: avatarContainer.radius
                        visible: false
                        layer.enabled: true
                    }

                    MultiEffect {
                        width: avatarContainer.width
                        height: avatarContainer.height
                        source: avatarImg
                        maskEnabled: true
                        maskSource: avatarMask
                    }
                }

                // Name / login / bio
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2 * Appearance.effectiveScale
                    StyledText {
                        text: root.profile ? (root.profile.name || root.profile.login) : ""
                        font.pixelSize: Appearance.font.pixelSize.large; font.weight: Font.Bold
                        color: Appearance.colors.colOnLayer1; elide: Text.ElideRight; Layout.fillWidth: true
                    }
                    StyledText {
                        text: "@" + (root.profile ? root.profile.login : "")
                        font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colPrimary
                        Layout.fillWidth: true
                    }
                    StyledText {
                        visible: !!(root.profile && root.profile.bio)
                        text: root.profile ? root.profile.bio : ""
                        font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext
                        maximumLineCount: 2; elide: Text.ElideRight; Layout.fillWidth: true; wrapMode: Text.Wrap
                    }
                }

                // Stats column
                ColumnLayout {
                    spacing: 3 * Appearance.effectiveScale; Layout.alignment: Qt.AlignVCenter

                    Repeater {
                        model: [
                            { icon: "folder", value: root.profile ? root.profile.public_repos : 0, label: "repos" },
                            { icon: "group", value: root.profile ? root.profile.followers : 0, label: "followers" },
                            { icon: "person_add", value: root.profile ? root.profile.following : 0, label: "following" }
                        ]
                        delegate: RowLayout {
                            spacing: 4 * Appearance.effectiveScale
                            MaterialSymbol { text: modelData.icon; iconSize: 13 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                            StyledText {
                                text: modelData.value + " " + modelData.label
                                font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext
                            }
                        }
                    }
                }
            }
        }

        // ─ Contribution heatmap ─
        ColumnLayout {
            Layout.fillWidth: true; spacing: 4 * Appearance.effectiveScale
            visible: root.contribWeeks.length > 0

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: root.totalContribs + " contributions in the last year"
                    font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1; Layout.fillWidth: true
                }
                // Refresh button moved here for easy access
                RippleButton {
                    implicitWidth: 28 * Appearance.effectiveScale; implicitHeight: 28 * Appearance.effectiveScale; buttonRadius: 14 * Appearance.effectiveScale; colBackground: "transparent"
                    onClicked: root.fetch()
                    MaterialSymbol { anchors.centerIn: parent; text: "refresh"; iconSize: 15 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                    StyledToolTip { text: "Refresh GitHub data" }
                }
            }

            // Heatmap grid — 52 columns (weeks) × 7 rows (days)
            // Each column is ALWAYS 7 cells tall so widths are perfectly uniform
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: heatGrid.implicitHeight + 16 * Appearance.effectiveScale
                radius: Appearance.rounding.normal
                color: Appearance.m3colors.m3surfaceContainer

                Row {
                    id: heatGrid
                    anchors.centerIn: parent
                    spacing: 3 * Appearance.effectiveScale

                    Repeater {
                        model: root.contribWeeks
                        delegate: Column {
                            required property var modelData
                            required property int index
                            spacing: 3 * Appearance.effectiveScale

                            Repeater {
                                // Always 7 rows — pad short weeks with empty slots
                                model: 7
                                delegate: Rectangle {
                                    required property int index
                                    readonly property var dayData: {
                                        const days = modelData.contributionDays
                                        return index < days.length ? days[index] : null
                                    }
                                    readonly property int count: dayData ? dayData.contributionCount : 0
                                    readonly property bool padded: dayData === null
                                    width: 10 * Appearance.effectiveScale; height: 10 * Appearance.effectiveScale; radius: 2 * Appearance.effectiveScale
                                    color: padded
                                        ? "transparent"
                                        : count === 0
                                            ? Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, 0.10)
                                            : Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 
                                                Math.min(0.2 + (count / 10), 1.0))
                                }
                            }
                        }
                    }
                }
            }
        }

        StyledText {
            text: "Recent Repositories"
            font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer1
        }

        GridLayout {
            Layout.fillWidth: true; columns: 2; rowSpacing: 6 * Appearance.effectiveScale; columnSpacing: 6 * Appearance.effectiveScale
            visible: root.repos.length > 0

            Repeater {
                model: root.repos.slice(0, 6)
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    implicitHeight: repoCol.implicitHeight + 14 * Appearance.effectiveScale
                    radius: Appearance.rounding.small; color: Appearance.m3colors.m3surfaceContainer

                    RippleButton { anchors.fill: parent; buttonRadius: parent.radius; colBackground: "transparent"; onClicked: Qt.openUrlExternally(modelData.html_url) }

                    ColumnLayout {
                        id: repoCol; anchors.fill: parent; anchors.margins: 10 * Appearance.effectiveScale; spacing: 2 * Appearance.effectiveScale
                        RowLayout {
                            spacing: 4 * Appearance.effectiveScale
                            MaterialSymbol { text: modelData.private ? "lock" : "folder_open"; iconSize: 12 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                            StyledText {
                                text: modelData.name; font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1; elide: Text.ElideRight; Layout.fillWidth: true
                            }
                        }
                        RowLayout {
                            spacing: 8 * Appearance.effectiveScale
                            RowLayout {
                                spacing: 3 * Appearance.effectiveScale
                                MaterialSymbol { text: "star"; iconSize: 11 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                                StyledText { text: modelData.stargazers_count; font.pixelSize: 11 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                            }
                            StyledText { visible: !!modelData.language; text: modelData.language || ""; font.pixelSize: 11 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}

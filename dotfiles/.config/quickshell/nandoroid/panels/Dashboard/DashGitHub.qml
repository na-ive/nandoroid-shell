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
 * Shows avatar, stats, contribution heatmap (52 weeks × 7 days), and top repos.
 * Uses curl + GitHub GraphQL API for contribution graph (token required for GraphQL).
 */
Item {
    id: root

    readonly property string username: Config.ready && Config.options.github ? (Config.options.github.githubUsername || "") : ""
    readonly property string token: Config.ready && Config.options.github ? (Config.options.github.githubToken || "") : ""

    property var profile: null
    property var contribWeeks: []   // [{contributionDays: [{date, contributionCount, color},...]}]
    property int totalContribs: 0
    property var repos: []
    property bool loading: false
    property string errorMsg: ""

    // ── max contribution count for shade normalisation ──
    readonly property int maxCount: {
        let m = 1
        for (let w of contribWeeks) for (let d of w.contributionDays) if (d.contributionCount > m) m = d.contributionCount
        return m
    }

    function fetch() {
        if (!username) { root.loading = false; return }
        root.profile = null; root.contribWeeks = []; root.repos = []
        root.errorMsg = ""; root.loading = true
        profileProc.running = true
    }

    property bool fetchedOnce: false

    // Fetch as soon as the configuration is fully loaded
    function checkAndFetch() {
        if (Config.ready && !fetchedOnce && !loading) {
            fetchedOnce = true
            fetch()
        }
    }

    Connections {
        target: Config
        function onReadyChanged() { checkAndFetch() }
    }

    Component.onCompleted: checkAndFetch()

    // ── Profile REST fetch ──
    Process {
        id: profileProc
        command: {
            let args = ["curl", "-s", "-f", "--max-time", "10"]
            if (root.token) args = args.concat(["-H", "Authorization: token " + root.token])
            return args.concat(["https://api.github.com/users/" + root.username])
        }
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(this.text)
                    if (parsed && parsed.login) {
                        root.profile = parsed
                        root.errorMsg = ""
                        // Start next step in chain
                        if (root.token) {
                            contribProc.running = true
                        } else {
                            reposProc.running = true
                        }
                    } else {
                        root.errorMsg = "GitHub API error: " + (parsed.message || "unknown")
                        root.loading = false
                    }
                } catch(e) {
                    root.errorMsg = "Failed to parse profile"
                    root.loading = false
                }
            }
        }
        onExited: (code) => {
            // Only handle real errors (not SIGTERM=15/SIGKILL=9)
            if (code !== 0 && code !== 15 && code !== 9 && root.profile === null) {
                root.errorMsg = "Network error: curl " + code + (code === 22 ? " (rate limited?)" : "")
                root.loading = false
            }
        }
    }

    // ── Contributions GraphQL fetch (token required) ──
    Process {
        id: contribProc
        command: {
            const query = '{"query":"{ user(login: \\"' + root.username + '\\") { contributionsCollection { contributionCalendar { totalContributions weeks { contributionDays { date contributionCount } } } } } }"}'
            return ["curl", "-s", "-f", "--max-time", "10",
                    "-H", "Authorization: bearer " + root.token,
                    "-H", "Content-Type: application/json",
                    "-d", query,
                    "https://api.github.com/graphql"]
        }
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text)
                    const cal = data.data.user.contributionsCollection.contributionCalendar
                    root.totalContribs = cal.totalContributions
                    root.contribWeeks = cal.weeks
                } catch(e) {}
                // Always proceed to repos regardless of contrib result
                reposProc.running = true
            }
        }
        onExited: (code) => {
            // If contribProc fails without producing output, still fetch repos
            if (code !== 0 && !reposProc.running) reposProc.running = true
        }
    }

    // ── Repos REST fetch ──
    Process {
        id: reposProc
        command: {
            let args = ["curl", "-s", "-f", "--max-time", "10"]
            if (root.token) args = args.concat(["-H", "Authorization: token " + root.token])
            return args.concat(["https://api.github.com/users/" + root.username + "/repos?sort=pushed&per_page=6&type=all"])
        }
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.repos = JSON.parse(this.text) } catch(e) {}
                root.loading = false
            }
        }
        onExited: (code) => { root.loading = false }
    }

    // ── Empty state (no username) ──
    ColumnLayout {
        anchors.centerIn: parent; spacing: 16
        visible: !root.username && !root.loading

        MaterialSymbol { Layout.alignment: Qt.AlignHCenter; text: "hub"; iconSize: 56; color: Appearance.colors.colSubtext }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "GitHub Profile Tracker"
            font.pixelSize: Appearance.font.pixelSize.large; font.weight: Font.Bold
            color: Appearance.colors.colOnLayer1
        }
        StyledText {
            Layout.alignment: Qt.AlignHCenter; horizontalAlignment: Text.AlignHCenter
            text: "Configure your GitHub username in\nSettings → Services → GitHub"
            color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.normal
        }
    }

    // ── Loading spinner ──
    Item {
        anchors.centerIn: parent; visible: root.loading
        implicitWidth: 44; implicitHeight: 44

        Canvas {
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.beginPath(); ctx.arc(width/2, height/2, 16, 0, Math.PI * 2)
                ctx.strokeStyle = Appearance.m3colors.m3outlineVariant
                ctx.lineWidth = 4; ctx.stroke()
            }
        }
        Rectangle {
            anchors.centerIn: parent; width: 32; height: 32; radius: 16
            color: "transparent"
            Rectangle {
                anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                width: 4; height: 16; radius: 2; color: Appearance.m3colors.m3primary
            }
            RotationAnimation on rotation {
                from: 0; to: 360; duration: 800
                loops: Animation.Infinite; running: root.loading
            }
        }
    }

    // ── Error state ──
    ColumnLayout {
        anchors.centerIn: parent; spacing: 12
        visible: root.errorMsg !== "" && !root.loading
        MaterialSymbol { Layout.alignment: Qt.AlignHCenter; text: "error_outline"; iconSize: 40; color: Appearance.colors.colError }
        StyledText { Layout.alignment: Qt.AlignHCenter; text: root.errorMsg; color: Appearance.colors.colError }
        RippleButton {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 100; implicitHeight: 36; buttonRadius: 18
            colBackground: Appearance.m3colors.m3surfaceContainer
            onClicked: root.fetch()
            StyledText { anchors.centerIn: parent; text: "Retry"; color: Appearance.colors.colOnLayer1 }
        }
    }

    // ── Profile content ──
    ColumnLayout {
        anchors.fill: parent; spacing: 10
        visible: root.profile !== null && !root.loading

        // ─ Profile header card ─
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: profileRow.implicitHeight + 20
            radius: Appearance.rounding.normal; color: Appearance.m3colors.m3surfaceContainer

            RowLayout {
                id: profileRow; anchors.fill: parent; anchors.margins: 12; spacing: 14

                // Avatar
                Rectangle {
                    id: avatarContainer
                    width: 52; height: 52; radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer2
                    
                    Image {
                        id: avatarImg
                        anchors.fill: parent
                        source: root.profile ? root.profile.avatar_url : ""
                        fillMode: Image.PreserveAspectCrop; asynchronous: true
                        visible: false // Hidden because mask renders it
                    }

                    Rectangle {
                        id: avatarMask
                        anchors.fill: parent
                        radius: Appearance.rounding.normal
                        visible: false
                        layer.enabled: true
                    }

                    MultiEffect {
                        anchors.fill: avatarImg
                        source: avatarImg
                        maskEnabled: true
                        maskSource: avatarMask
                    }
                }

                // Name / login / bio
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    StyledText {
                        text: root.profile ? (root.profile.name || root.profile.login) : ""
                        font.pixelSize: Appearance.font.pixelSize.large; font.weight: Font.Bold
                        color: Appearance.colors.colOnLayer1; elide: Text.ElideRight; Layout.fillWidth: true
                    }
                    StyledText {
                        text: root.profile ? "@" + root.profile.login : ""
                        font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        visible: root.profile && root.profile.bio
                        text: root.profile ? (root.profile.bio || "") : ""
                        font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext
                        elide: Text.ElideRight; Layout.fillWidth: true
                    }
                }

                // Stats column
                ColumnLayout {
                    spacing: 3; Layout.alignment: Qt.AlignVCenter

                    Repeater {
                        model: [
                            { icon: "folder", value: root.profile ? root.profile.public_repos : 0, label: "repos" },
                            { icon: "group", value: root.profile ? root.profile.followers : 0, label: "followers" },
                            { icon: "person_add", value: root.profile ? root.profile.following : 0, label: "following" }
                        ]
                        delegate: RowLayout {
                            spacing: 4
                            MaterialSymbol { text: modelData.icon; iconSize: 13; color: Appearance.colors.colSubtext }
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
            Layout.fillWidth: true; spacing: 4
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
                    implicitWidth: 28; implicitHeight: 28; buttonRadius: 14; colBackground: "transparent"
                    onClicked: root.fetch()
                    MaterialSymbol { anchors.centerIn: parent; text: "refresh"; iconSize: 15; color: Appearance.colors.colSubtext }
                    StyledToolTip { text: "Refresh GitHub data" }
                }
            }

            // Heatmap grid — 52 columns (weeks) × 7 rows (days)
            // Each column is ALWAYS 7 cells tall so widths are perfectly uniform
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: heatGrid.implicitHeight + 16
                radius: Appearance.rounding.normal
                color: Appearance.m3colors.m3surfaceContainer

                Row {
                    id: heatGrid
                    anchors.centerIn: parent
                    spacing: 3

                    Repeater {
                        model: root.contribWeeks
                        delegate: Column {
                            required property var modelData
                            required property int index
                            spacing: 3

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
                                    width: 10; height: 10; radius: 2
                                    color: padded
                                        ? "transparent"
                                        : count === 0
                                            ? Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, 0.10)
                                            : Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b,
                                                0.25 + 0.75 * (count / root.maxCount))
                                    StyledToolTip {
                                        text: dayData ? (dayData.date + ": " + count + " contribution" + (count !== 1 ? "s" : "")) : ""
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ─ No-token note for heatmap ─
        StyledText {
            visible: root.profile !== null && !root.loading && root.contribWeeks.length === 0
            text: "Add a GitHub API token in Settings → Services → GitHub to show the contribution graph"
            font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext
            wrapMode: Text.WordWrap; Layout.fillWidth: true; opacity: 0.7
        }

        // ─ Top repos ─
        StyledText {
            visible: root.repos.length > 0
            text: "Recent Repositories"
            font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer1
        }

        GridLayout {
            Layout.fillWidth: true; columns: 2; rowSpacing: 6; columnSpacing: 6
            visible: root.repos.length > 0

            Repeater {
                model: root.repos.slice(0, 6)
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    implicitHeight: repoCol.implicitHeight + 14
                    radius: Appearance.rounding.small; color: Appearance.m3colors.m3surfaceContainer

                    RippleButton { anchors.fill: parent; buttonRadius: parent.radius; colBackground: "transparent"; onClicked: Qt.openUrlExternally(modelData.html_url) }

                    ColumnLayout {
                        id: repoCol; anchors.fill: parent; anchors.margins: 10; spacing: 2
                        RowLayout {
                            spacing: 4
                            MaterialSymbol { text: modelData.private ? "lock" : "folder_open"; iconSize: 12; color: Appearance.colors.colSubtext }
                            StyledText {
                                text: modelData.name; font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1; elide: Text.ElideRight; Layout.fillWidth: true
                            }
                        }
                        RowLayout {
                            spacing: 8
                            RowLayout {
                                spacing: 3
                                MaterialSymbol { text: "star"; iconSize: 11; color: Appearance.colors.colSubtext }
                                StyledText { text: modelData.stargazers_count; font.pixelSize: 11; color: Appearance.colors.colSubtext }
                            }
                            StyledText { visible: !!modelData.language; text: modelData.language || ""; font.pixelSize: 11; color: Appearance.colors.colPrimary }
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}

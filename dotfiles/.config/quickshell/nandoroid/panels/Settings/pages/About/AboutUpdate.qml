import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Io

/**
 * Shell update page, modelled after the ii "About & Updates" flow:
 *  - a clear pending-update log, commits grouped by kind (feat/fix/...)
 *  - a per-version release history, each version an accordion with its
 *    full release note text plus the commits that version contains.
 *
 * Everything is resolved with local git only (no network beyond
 * `git fetch`), so the page works offline and shows the same data
 * the updater acts on.
 */
ColumnLayout {
    id: updateRoot
    spacing: 24 * Appearance.effectiveScale

    // ── State ──────────────────────────────────────────────
    FileView {
        id: installStateView
        path: Directories.home.replace("file://", "") + "/.config/nandoroid/install_state.json"
        watchChanges: true
        JsonAdapter {
            id: installState
            property bool inject: false
            property string install_dir: ""
            property string channel: "stable"
        }
    }

    // Full CHANGELOG.md text of the checkout, parsed per version below.
    // Falls back to the annotated tag message when a section is missing.
    FileView {
        id: changelogView
        path: installState.install_dir !== "" ? installState.install_dir + "/CHANGELOG.md" : ""
        watchChanges: false
        onLoaded: updateRoot.parseChangelog(text())
        onLoadFailed: updateRoot.changelogMap = ({})
    }

    property string updateType: "" // "shell" or "all"
    property string installTagTarget: ""

    // Resolved refs for the active channel.
    property string localSha: ""
    property string remoteSha: ""
    property string latestTag: ""
    property int behindCount: 0
    property int aheadCount: 0
    property bool revLoading: false
    // Direction-aware: only "behind" counts as an update. A checkout that is
    // ahead (e.g. local dev commits) is never an update.
    readonly property bool hasUpdate: behindCount > 0
    readonly property bool isAhead: aheadCount > 0 && behindCount === 0 && remoteSha !== ""
    readonly property bool isDiverged: aheadCount > 0 && behindCount > 0

    // Commit models, newest first.
    // Each entry: { sha, author, date, subject, body, type, scope, summary, breaking }
    property var pendingCommits: []
    property var aheadCommits: []
    property bool aheadLoading: false
    property var recentCommits: []
    property bool recentLoading: false

    // Release history, newest first.
    // Each entry: { name, date, subject, body, tagObj, tagCommit }
    property var tagList: []
    property bool tagsLoading: false
    property int expandedTagIndex: 0

    property string gitRemoteUrl: ""
    property var changelogMap: ({})
    property bool isDevSymlink: false

    // Live update run (visible, streaming).
    property bool updateRunning: false
    property string updateLog: ""
    property bool updateLogVisible: false
    property int updateExitCode: 0
    property int _outLen: 0
    property int _errLen: 0
    property real lastCheckTs: 0

    function scrollUpdateLog() {
        Qt.callLater(function () {
            updateLogFlick.contentY = Math.max(0, updateLogFlick.contentHeight - updateLogFlick.height);
        });
    }

    function launchUpdate(type) {
        if (updateRoot.updateRunning || installState.install_dir === "")
            return;
        updateRoot.updateType = type;
        updateRoot.updateLog = "";
        updateRoot._outLen = 0;
        updateRoot._errLen = 0;
        updateRoot.updateExitCode = 0;
        updateRoot.updateLogVisible = true;
        runUpdateProc.running = true;
    }

    readonly property var whatsNewCommits: behindCount > 0 ? pendingCommits : (aheadCount > 0 ? aheadCommits : recentCommits)
    readonly property string repoSlug: updateRoot.githubSlug(gitRemoteUrl)

    // ── Helpers (same "type(scope): summary" convention as ii) ──
    function parseSubject(subject) {
        var text = String(subject || "").trim();
        var m = text.match(/^([a-zA-Z]+)(?:\(([^)]*)\))?(!)?:\s*(.+)$/);
        if (!m)
            return { type: "", scope: "", summary: text, breaking: false };
        return { type: m[1].toLowerCase(), scope: (m[2] || "").trim(), summary: m[4].trim(), breaking: m[3] === "!" };
    }

    function parseCommitLog(raw) {
        var out = [];
        var records = String(raw || "").split("\u001e");
        for (var i = 0; i < records.length; i++) {
            var rec = records[i].trim();
            if (rec === "")
                continue;
            var f = rec.split("\u001f");
            if (f.length < 4 || f[0] === "")
                continue;
            var parsed = updateRoot.parseSubject(f[3]);
            out.push({
                sha: f[0],
                author: f.length > 1 ? f[1] : "",
                date: f.length > 2 ? f[2] : "",
                subject: f[3],
                body: f.slice(4).join("\u001f").trim(),
                type: parsed.type,
                scope: parsed.scope,
                summary: parsed.summary,
                breaking: parsed.breaking
            });
        }
        return out;
    }

    readonly property var groupDefs: [
        { id: "feat", title: I18nService.tr("New"), icon: "auto_awesome", types: ["feat", "feature", "add"] },
        { id: "fix", title: I18nService.tr("Fixes"), icon: "build", types: ["fix", "bugfix", "hotfix"] },
        { id: "perf", title: I18nService.tr("Performance"), icon: "speed", types: ["perf"] },
        { id: "style", title: I18nService.tr("Look"), icon: "palette", types: ["style", "ui"] },
        { id: "internal", title: I18nService.tr("Internals"), icon: "construction", types: ["refactor", "chore", "build", "ci", "test", "docs", "revert"] },
        { id: "other", title: I18nService.tr("Other"), icon: "commit", types: [] }
    ]

    function groupCommits(commits) {
        var src = Array.from(commits || []);
        var buckets = updateRoot.groupDefs.map(function (def) {
            return { id: def.id, title: def.title, icon: def.icon, types: def.types, commits: [] };
        });
        var other = buckets[buckets.length - 1];
        for (var i = 0; i < src.length; i++) {
            var c = src[i];
            var found = null;
            for (var j = 0; j < buckets.length - 1; j++) {
                if (buckets[j].types.indexOf(c.type) >= 0) {
                    found = buckets[j];
                    break;
                }
            }
            (found || other).commits.push(c);
        }
        return buckets.filter(function (b) { return b.commits.length > 0; });
    }

    function groupColor(id) {
        if (id === "feat")
            return Appearance.m3colors.m3primaryContainer;
        if (id === "fix")
            return Appearance.m3colors.m3errorContainer;
        if (id === "perf" || id === "style")
            return Appearance.m3colors.m3tertiaryContainer;
        return Appearance.m3colors.m3secondaryContainer;
    }

    function groupTextColor(id) {
        if (id === "feat")
            return Appearance.m3colors.m3onPrimaryContainer;
        if (id === "fix")
            return Appearance.m3colors.m3onErrorContainer;
        if (id === "perf" || id === "style")
            return Appearance.m3colors.m3onTertiaryContainer;
        return Appearance.m3colors.m3onSecondaryContainer;
    }

    function githubSlug(remote) {
        if (!remote)
            return "";
        var m = String(remote).match(/github\.com[:\/]+([^\/]+)\/([^\/]+?)(?:\.git)?\/?$/);
        return m ? (m[1] + "/" + m[2]) : "";
    }

    function commitUrl(sha) {
        if (updateRoot.repoSlug === "" || !sha)
            return "";
        return "https://github.com/" + updateRoot.repoSlug + "/commit/" + sha;
    }

    function tagUrl(tag) {
        if (updateRoot.repoSlug === "" || !tag)
            return "";
        return "https://github.com/" + updateRoot.repoSlug + "/releases/tag/" + tag;
    }

    function compareUrl() {
        if (updateRoot.repoSlug === "" || !updateRoot.hasUpdate)
            return "";
        return "https://github.com/" + updateRoot.repoSlug + "/compare/" + updateRoot.localSha + "..." + updateRoot.remoteSha;
    }

    function parseTagList(raw) {
        var out = [];
        var records = String(raw || "").split("\u001e");
        for (var i = 0; i < records.length; i++) {
            var rec = records[i];
            if (rec.trim() === "")
                continue;
            var f = rec.split("\u001f");
            if (f.length < 1 || String(f[0]).trim() === "")
                continue;
            out.push({
                name: String(f[0]).trim(),
                date: f.length > 1 ? String(f[1]).trim() : "",
                subject: f.length > 2 ? String(f[2]).trim() : "",
                body: f.length > 3 ? String(f[3]).trim() : "",
                tagObj: f.length > 4 ? String(f[4]).trim() : "",
                tagCommit: f.length > 5 ? String(f[5]).trim() : ""
            });
        }
        return out;
    }

    // "# Nandoroid Shell v1.5.0 Release Notes" -> { "v1.5.0": "...", "1.5.0": "..." }
    function parseChangelog(text) {
        var map = {};
        var src = String(text || "");
        if (src === "") {
            updateRoot.changelogMap = map;
            return;
        }
        var re = /^#\s+.*?v?(\d[\w.\-]*)\s*.*$/gm;
        var matches = [];
        var m;
        while ((m = re.exec(src)) !== null)
            matches.push({ idx: m.index, ver: m[1] });
        for (var i = 0; i < matches.length; i++) {
            var eol = src.indexOf("\n", matches[i].idx);
            var end = (i + 1 < matches.length) ? matches[i + 1].idx : src.length;
            var body = src.substring(eol + 1, end).trim();
            var core = String(matches[i].ver).replace(/[^0-9.\-a-z]/gi, "");
            if (core !== "") {
                map["v" + core] = body;
                map[core] = body;
            }
        }
        updateRoot.changelogMap = map;
    }

    function changelogFor(tagName) {
        var key = String(tagName || "").trim();
        if (key === "")
            return "";
        if (Object.prototype.hasOwnProperty.call(updateRoot.changelogMap, key))
            return updateRoot.changelogMap[key];
        var stripped = key.replace(/^v/, "");
        if (Object.prototype.hasOwnProperty.call(updateRoot.changelogMap, stripped))
            return updateRoot.changelogMap[stripped];
        return "";
    }

    function refreshAll() {
        if (installState.install_dir === "")
            return;
        remoteUrlProc.running = false;
        revProc.running = false;
        tagListProc.running = false;
        remoteUrlProc.running = true;
        revProc.running = true;
        tagListProc.running = true;
    }

    // ── Shared: grouped commit list (ala ii ShellUpdateChangelog) ──
    component GroupedCommitList: ColumnLayout {
        id: groupList
        property var commits: []
        spacing: 10 * Appearance.effectiveScale

        Repeater {
            model: updateRoot.groupCommits(groupList.commits)
            delegate: ColumnLayout {
                id: groupItem
                required property var modelData
                Layout.fillWidth: true
                spacing: 4 * Appearance.effectiveScale

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6 * Appearance.effectiveScale
                    MaterialSymbol {
                        text: groupItem.modelData.icon
                        iconSize: 16 * Appearance.effectiveScale
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        text: groupItem.modelData.title
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        text: groupItem.modelData.commits.length
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        opacity: 0.8
                    }
                    Item { Layout.fillWidth: true }
                }

                Repeater {
                    model: groupItem.modelData.commits
                    delegate: Rectangle {
                        id: commitRow
                        required property var modelData
                        Layout.fillWidth: true
                        readonly property int pad: 8 * Appearance.effectiveScale
                        implicitHeight: commitRowLayout.implicitHeight + pad * 2
                        radius: 8 * Appearance.effectiveScale
                        color: commitHover.hovered ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2
                        property bool hovered: commitHover.hovered
                        HoverHandler { id: commitHover }

                        RowLayout {
                            id: commitRowLayout
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: commitRow.pad
                                rightMargin: commitRow.pad
                            }
                            spacing: 8 * Appearance.effectiveScale

                            Rectangle {
                                visible: commitRow.modelData.scope !== "" || commitRow.modelData.breaking
                                radius: 4 * Appearance.effectiveScale
                                color: commitRow.modelData.breaking ? Appearance.colors.colError : updateRoot.groupColor(groupItem.modelData.id)
                                implicitWidth: scopeText.implicitWidth + 12 * Appearance.effectiveScale
                                implicitHeight: scopeText.implicitHeight + 4 * Appearance.effectiveScale
                                StyledText {
                                    id: scopeText
                                    anchors.centerIn: parent
                                    text: commitRow.modelData.breaking ? I18nService.tr("breaking") : commitRow.modelData.scope
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    font.weight: Font.DemiBold
                                    color: commitRow.modelData.breaking ? Appearance.colors.colOnError : updateRoot.groupTextColor(groupItem.modelData.id)
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2 * Appearance.effectiveScale
                                StyledText {
                                    Layout.fillWidth: true
                                    text: commitRow.modelData.summary || commitRow.modelData.subject
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colOnLayer1
                                    elide: Text.ElideRight
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 3
                                }
                                StyledText {
                                    visible: commitRow.modelData.author !== "" || commitRow.modelData.date !== ""
                                    Layout.fillWidth: true
                                    text: (commitRow.modelData.author || "") + (commitRow.modelData.date !== "" ? " · " + commitRow.modelData.date : "")
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    color: Appearance.colors.colSubtext
                                    elide: Text.ElideRight
                                }
                            }

                            StyledText {
                                text: String(commitRow.modelData.sha || "").substring(0, 7)
                                font.family: Appearance.font.family.monospace
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                            }

                            MaterialSymbol {
                                visible: updateRoot.commitUrl(commitRow.modelData.sha) !== ""
                                text: "open_in_new"
                                iconSize: 16 * Appearance.effectiveScale
                                color: Appearance.colors.colSubtext
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: updateRoot.commitUrl(commitRow.modelData.sha) !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                var url = updateRoot.commitUrl(commitRow.modelData.sha);
                                if (url !== "")
                                    Qt.openUrlExternally(url);
                            }
                        }

                        StyledToolTip {
                            text: String(commitRow.modelData.body || "").trim()
                            extraVisibleCondition: commitHover.hovered && String(commitRow.modelData.body || "").trim() !== ""
                        }
                    }
                }
            }
        }
    }

    // ── Background resolvers ───────────────────────────────────
    Process {
        id: remoteUrlProc
        command: ["bash", "-c", `cd '${installState.install_dir}' 2>/dev/null && git remote get-url origin 2>/dev/null`]
        stdout: StdioCollector {
            onStreamFinished: updateRoot.gitRemoteUrl = text.trim()
        }
        running: updateRoot.visible && installState.install_dir !== ""
    }

    // Resolves LOCAL / REMOTE / latest tag / behind count for the channel.
    Process {
        id: revProc
        command: ["bash", "-c", `
            cd '${installState.install_dir}' || exit
            git fetch origin >/dev/null 2>&1
            git fetch --tags >/dev/null 2>&1
            LOCAL=$(git rev-parse HEAD 2>/dev/null)
            if [ '${installState.channel}' = 'stable' ]; then
                LATEST=$(git describe --tags $(git rev-list --tags --max-count=1 2>/dev/null) 2>/dev/null)
            else
                LATEST=""
            fi
            if [ -n "$LATEST" ]; then
                REMOTE=$(git rev-list -n 1 "$LATEST" 2>/dev/null)
            else
                REMOTE=$(git rev-parse origin/main 2>/dev/null || git rev-parse origin/HEAD 2>/dev/null)
            fi
            BEHIND=0
            AHEAD=0
            if [ -n "$LOCAL" ] && [ -n "$REMOTE" ]; then
                if [ "$LOCAL" != "$REMOTE" ]; then
                    BEHIND=$(git rev-list --count "$LOCAL..$REMOTE" 2>/dev/null || echo 0)
                fi
                AHEAD=$(git rev-list --count "$REMOTE..$LOCAL" 2>/dev/null || echo 0)
            fi
            printf '%s\\x1f%s\\x1f%s\\x1f%s\\x1f%s' "$LOCAL" "$REMOTE" "$LATEST" "$BEHIND" "$AHEAD"
        `]
        stdout: StdioCollector {
            id: revCollector
            onStreamFinished: {
                var f = String(text).split("\u001f");
                updateRoot.localSha = (f.length > 0 ? String(f[0]).trim() : "");
                updateRoot.remoteSha = (f.length > 1 ? String(f[1]).trim() : "");
                updateRoot.latestTag = (f.length > 2 ? String(f[2]).trim() : "");
                var n = parseInt(f.length > 3 ? f[3] : "0");
                updateRoot.behindCount = isNaN(n) ? 0 : n;
                var m = parseInt(f.length > 4 ? f[4] : "0");
                updateRoot.aheadCount = isNaN(m) ? 0 : m;
                updateRoot.revLoading = false;
                updateRoot.lastCheckTs = Date.now();
                if (updateRoot.behindCount > 0) {
                    pendingLogProc.running = false;
                    pendingLogProc.running = true;
                }
                if (updateRoot.aheadCount > 0) {
                    aheadLogProc.running = false;
                    aheadLogProc.running = true;
                }
                if (updateRoot.behindCount === 0 && updateRoot.aheadCount === 0) {
                    recentLogProc.running = false;
                    recentLogProc.running = true;
                }
            }
        }
        running: updateRoot.visible && installState.install_dir !== ""
        onRunningChanged: if (running) updateRoot.revLoading = true
    }

    // Commits waiting to be installed (LOCAL..REMOTE).
    Process {
        id: pendingLogProc
        command: ["bash", "-c", `cd '${installState.install_dir}' && git log '${updateRoot.localSha}..${updateRoot.remoteSha}' --pretty=format:'%H%x1f%an%x1f%ad%x1f%s%x1f%b%x1e' --date=short 2>/dev/null`]
        stdout: StdioCollector {
            onStreamFinished: {
                updateRoot.pendingCommits = updateRoot.parseCommitLog(text);
            }
        }
    }

    // Commits only on the local checkout (REMOTE..LOCAL): dev work / unpushed.
    Process {
        id: aheadLogProc
        command: ["bash", "-c", `cd '${installState.install_dir}' && git log '${updateRoot.remoteSha}..${updateRoot.localSha}' --pretty=format:'%H%x1f%an%x1f%ad%x1f%s%x1f%b%x1e' --date=short 2>/dev/null`]
        stdout: StdioCollector {
            onStreamFinished: {
                updateRoot.aheadCommits = updateRoot.parseCommitLog(text);
                updateRoot.aheadLoading = false;
            }
        }
        onRunningChanged: if (running) updateRoot.aheadLoading = true
    }

    // Newest commits when already up to date.
    Process {
        id: recentLogProc
        command: ["bash", "-c", `cd '${installState.install_dir}' && git log -n 15 --pretty=format:'%H%x1f%an%x1f%ad%x1f%s%x1f%b%x1e' --date=short 2>/dev/null`]
        stdout: StdioCollector {
            onStreamFinished: {
                updateRoot.recentCommits = updateRoot.parseCommitLog(text);
                updateRoot.recentLoading = false;
            }
        }
        onRunningChanged: if (running) updateRoot.recentLoading = true
    }

    // All tags, newest first, with full annotated release-note text.
    Process {
        id: tagListProc
        command: ["bash", "-c", `cd '${installState.install_dir}' && FS=$(printf '\\x1f') && RS=$(printf '\\x1e') && git for-each-ref --sort=-creatordate --format="%(refname:short)\${FS}%(creatordate:short)\${FS}%(subject)\${FS}%(body)\${FS}%(objectname:short)\${FS}%(*objectname:short)\${RS}" refs/tags 2>/dev/null`]
        stdout: StdioCollector {
            onStreamFinished: {
                updateRoot.tagList = updateRoot.parseTagList(text);
                updateRoot.tagsLoading = false;
            }
        }
        running: updateRoot.visible && installState.install_dir !== ""
        onRunningChanged: if (running) updateRoot.tagsLoading = true
    }

    /**
     * UPDATE RUNNER with a visible live log.
     * update.sh streams stdout/stderr here while it fetches, pulls and
     * copies files; on success the shell reloads after a short beat so the
     * result stays readable. On failure the log is kept for inspection.
     */
    Process {
        id: runUpdateProc
        command: ["bash", "-c", `${installState.install_dir}/update.sh ${updateRoot.updateType} ${installState.channel}`]
        stdout: StdioCollector {
            id: updateOut
            onTextChanged: {
                updateRoot.updateLog += text.substring(updateRoot._outLen);
                updateRoot._outLen = text.length;
                updateRoot.updateLogVisible = true;
                updateRoot.scrollUpdateLog();
            }
        }
        stderr: StdioCollector {
            id: updateErr
            onTextChanged: {
                updateRoot.updateLog += text.substring(updateRoot._errLen);
                updateRoot._errLen = text.length;
                updateRoot.updateLogVisible = true;
                updateRoot.scrollUpdateLog();
            }
        }
        onRunningChanged: updateRoot.updateRunning = running
        onExited: exitCode => {
            updateRoot.updateRunning = false;
            updateRoot.updateExitCode = exitCode;
            // Reconcile any tail output that arrived without a textChanged signal.
            updateRoot.updateLog += updateOut.text.substring(updateRoot._outLen);
            updateRoot._outLen = updateOut.text.length;
            updateRoot.updateLog += updateErr.text.substring(updateRoot._errLen);
            updateRoot._errLen = updateErr.text.length;
            if (exitCode === 0) {
                updateRoot.updateLog += "\n✓ " + I18nService.tr("Update successful — restarting shell…");
                updateRestartTimer.restart();
            } else {
                updateRoot.updateLog += "\n✗ " + I18nService.tr("Update failed (exit %1). See the log above.").arg(exitCode);
            }
            updateRoot.scrollUpdateLog();
        }
    }

    Timer {
        id: updateRestartTimer
        interval: 2500
        onTriggered: Quickshell.reload()
    }

    Process {
        id: devSymlinkCheckProc
        command: ["bash", "-c", `[ -L "$HOME/.config/quickshell/nandoroid" ] && echo yes || echo no`]
        stdout: StdioCollector {
            onStreamFinished: updateRoot.isDevSymlink = text.trim() === "yes"
        }
        running: updateRoot.visible
    }

    // Checkout an arbitrary released version from its accordion.
    Process {
        id: installTagProc
        command: ["bash", "-c", `cd '${installState.install_dir}' && git fetch --tags >/dev/null 2>&1 && git checkout '${updateRoot.installTagTarget}'`]
        stdout: StdioCollector { id: installTagCollector }
        stderr: StdioCollector { id: installTagErr }
        onExited: {
            Quickshell.reload();
        }
    }

    // --- 1. Hero: identity, channel, status & actions (ala ii About) ---
    Rectangle {
        id: hero
        Layout.fillWidth: true
        implicitHeight: heroCol.implicitHeight + (48 * Appearance.effectiveScale)
        radius: 20 * Appearance.effectiveScale
        color: Appearance.m3colors.m3surfaceContainerHigh
        visible: installState.install_dir !== ""

        readonly property real s: Appearance.effectiveScale
        readonly property color statusBg: {
            if (updateRoot.revLoading)
                return Appearance.colors.colSecondaryContainer;
            if (updateRoot.localSha === "" || updateRoot.remoteSha === "")
                return Appearance.colors.colLayer2;
            if (updateRoot.hasUpdate)
                return Appearance.colors.colTertiaryContainer;
            if (updateRoot.aheadCount > 0)
                return Appearance.colors.colSecondaryContainer;
            return Appearance.colors.colPrimaryContainer;
        }
        readonly property color statusFg: {
            if (updateRoot.revLoading)
                return Appearance.colors.colOnSecondaryContainer;
            if (updateRoot.localSha === "" || updateRoot.remoteSha === "")
                return Appearance.colors.colSubtext;
            if (updateRoot.hasUpdate)
                return Appearance.colors.colOnTertiaryContainer;
            if (updateRoot.aheadCount > 0)
                return Appearance.colors.colOnSecondaryContainer;
            return Appearance.colors.colOnPrimaryContainer;
        }
        readonly property string statusIcon: {
            if (updateRoot.hasUpdate)
                return "update";
            if (updateRoot.aheadCount > 0 && updateRoot.remoteSha !== "")
                return "publish";
            if (updateRoot.localSha !== "" && updateRoot.remoteSha === "")
                return "cloud_off";
            if (updateRoot.localSha !== "")
                return "check_circle";
            return "help";
        }
        readonly property string statusShort: {
            if (updateRoot.revLoading)
                return I18nService.tr("Checking…");
            if (updateRoot.localSha === "" || updateRoot.remoteSha === "")
                return I18nService.tr("Unknown");
            if (updateRoot.isDiverged)
                return I18nService.tr("Diverged");
            if (updateRoot.hasUpdate)
                return I18nService.tr("%1 behind").arg(updateRoot.behindCount);
            if (updateRoot.aheadCount > 0)
                return I18nService.tr("Ahead %1").arg(updateRoot.aheadCount);
            return I18nService.tr("Up to date");
        }
        readonly property string statusDetail: {
            if (updateRoot.revLoading)
                return I18nService.tr("Checking...");
            if (updateRoot.localSha === "")
                return I18nService.tr("Fetch the latest changes from the repository.");
            if (updateRoot.remoteSha === "")
                return I18nService.tr("Remote unreachable — showing local state.");
            if (updateRoot.isDiverged)
                return I18nService.tr("Diverged: %1 behind · %2 ahead").arg(updateRoot.behindCount).arg(updateRoot.aheadCount);
            if (updateRoot.hasUpdate) {
                if (installState.channel === "stable" && updateRoot.latestTag !== "")
                    return I18nService.tr("Switch Available: %1 (%2 commits)").arg(updateRoot.latestTag).arg(updateRoot.behindCount);
                return I18nService.tr("Update Available (%1 new commits)").arg(updateRoot.behindCount);
            }
            if (updateRoot.isAhead) {
                if (installState.channel === "stable" && updateRoot.latestTag !== "")
                    return I18nService.tr("Ahead of %1 (%2 local commits)").arg(updateRoot.latestTag).arg(updateRoot.aheadCount);
                return I18nService.tr("Ahead of remote (%1 local commits)").arg(updateRoot.aheadCount);
            }
            return I18nService.tr("Up to date · %1").arg(updateRoot.localSha.substring(0, 7));
        }

        ColumnLayout {
            id: heroCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 24 * hero.s
            }
            spacing: 20 * hero.s

            RowLayout {
                Layout.fillWidth: true
                spacing: 20 * hero.s

                CustomIcon {
                    Layout.preferredWidth: 84 * hero.s
                    Layout.preferredHeight: 84 * hero.s
                    Layout.alignment: Qt.AlignVCenter
                    source: "nandoroid-symbolic"
                    colorize: true
                    color: Appearance.colors.colPrimary
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 8 * hero.s

                    StyledText {
                        text: "NAnDoroid"
                        font.pixelSize: 30 * hero.s
                        font.family: Appearance.font.family.title
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnLayer1
                    }

                    RowLayout {
                        spacing: 8 * hero.s

                        StyledText {
                            text: VersionService.version
                            font.family: Appearance.font.family.monospace
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }

                        Rectangle {
                            implicitWidth: channelPillLbl.implicitWidth + 16 * hero.s
                            implicitHeight: channelPillLbl.implicitHeight + 6 * hero.s
                            radius: 10 * hero.s
                            color: installState.channel === "stable" ? Appearance.colors.colPrimaryContainer : Appearance.colors.colTertiaryContainer
                            StyledText {
                                id: channelPillLbl
                                anchors.centerIn: parent
                                text: installState.channel === "stable" ? I18nService.tr("Release") : I18nService.tr("Latest")
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                font.weight: Font.DemiBold
                                color: installState.channel === "stable" ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnTertiaryContainer
                            }
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: hero.statusDetail
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: updateRoot.hasUpdate ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                        elide: Text.ElideRight
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    spacing: 6 * hero.s

                    Rectangle {
                        Layout.alignment: Qt.AlignRight
                        implicitWidth: statusPillRow.implicitWidth + 24 * hero.s
                        implicitHeight: 36 * hero.s
                        radius: 18 * hero.s
                        color: hero.statusBg
                        Behavior on color { ColorAnimation { duration: 200 } }

                        RowLayout {
                            id: statusPillRow
                            anchors.centerIn: parent
                            spacing: 6 * hero.s

                            MaterialLoadingIndicator {
                                visible: updateRoot.revLoading
                                implicitSize: 16 * hero.s
                            }
                            MaterialSymbol {
                                visible: !updateRoot.revLoading
                                text: hero.statusIcon
                                iconSize: 18 * hero.s
                                color: hero.statusFg
                            }
                            StyledText {
                                text: hero.statusShort
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.DemiBold
                                color: hero.statusFg
                            }
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignRight
                        Layout.maximumWidth: 210 * hero.s
                        visible: updateRoot.lastCheckTs > 0
                        text: I18nService.tr("Checked %1").arg(new Date(updateRoot.lastCheckTs).toLocaleString(Qt.locale(), Locale.ShortFormat))
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colSubtext
                        horizontalAlignment: Text.AlignRight
                        wrapMode: Text.Wrap
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1 * hero.s
                color: Appearance.m3colors.m3outlineVariant
                opacity: 0.5
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 16 * hero.s

                MaterialSymbol {
                    text: "sync_alt"
                    iconSize: 24 * hero.s
                    color: Appearance.colors.colPrimary
                }

                ColumnLayout {
                    spacing: 2 * hero.s
                    Layout.fillWidth: true

                    StyledText {
                        text: I18nService.tr("Update Channel")
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: I18nService.tr("Choose between Release (Tags) and Latest (Commits).")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                        Layout.fillWidth: true
                    }
                }

                RowLayout {
                    spacing: 2 * hero.s

                    Repeater {
                        model: [
                            { label: I18nService.tr("Release"), value: "stable" },
                            { label: I18nService.tr("Latest"), value: "canary" }
                        ]
                        delegate: SegmentedButton {
                            required property var modelData
                            isHighlighted: installState.channel === modelData.value

                            buttonText: modelData.label
                            leftPadding: 16 * hero.s
                            rightPadding: 16 * hero.s

                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary
                            colInactive: Appearance.m3colors.m3surfaceContainerLow

                            onClicked: {
                                installState.channel = modelData.value;
                                installStateView.writeAdapter();
                                updateRoot.refreshAll();
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * hero.s

                RippleButton {
                    Layout.preferredHeight: 44 * hero.s
                    implicitWidth: updateBtnRow.implicitWidth + 32 * hero.s
                    implicitHeight: 44 * hero.s
                    buttonRadius: 22 * hero.s
                    colBackground: updateRoot.hasUpdate ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
                    enabled: !updateRoot.updateRunning
                    onClicked: updateRoot.launchUpdate("shell")

                    StyledToolTip {
                        text: I18nService.tr("Runs update.sh with live output below. The shell restarts when it finishes.")
                    }

                    RowLayout {
                        id: updateBtnRow
                        anchors.centerIn: parent
                        spacing: 8 * hero.s
                        MaterialSymbol {
                            text: "terminal"
                            iconSize: 18 * hero.s
                            color: updateRoot.hasUpdate ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                        }
                        StyledText {
                            text: updateRoot.hasUpdate ? I18nService.tr("Update now") : I18nService.tr("Update")
                            font.weight: Font.Medium
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: updateRoot.hasUpdate ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                        }
                    }
                }

                RippleButton {
                    Layout.preferredHeight: 44 * hero.s
                    implicitWidth: checkBtnRow.implicitWidth + 32 * hero.s
                    implicitHeight: 44 * hero.s
                    buttonRadius: 22 * hero.s
                    colBackground: Appearance.colors.colSecondaryContainer
                    enabled: !updateRoot.revLoading && !updateRoot.updateRunning
                    onClicked: updateRoot.refreshAll()

                    RowLayout {
                        id: checkBtnRow
                        anchors.centerIn: parent
                        spacing: 8 * hero.s
                        MaterialSymbol {
                            text: "refresh"
                            iconSize: 18 * hero.s
                            color: Appearance.colors.colOnSecondaryContainer
                        }
                        StyledText {
                            text: I18nService.tr("Check now")
                            font.weight: Font.Medium
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnSecondaryContainer
                        }
                    }
                }

                RippleButton {
                    visible: updateRoot.repoSlug !== ""
                    Layout.preferredHeight: 44 * hero.s
                    implicitWidth: gitBtnRow.implicitWidth + 32 * hero.s
                    implicitHeight: 44 * hero.s
                    buttonRadius: 22 * hero.s
                    colBackground: Appearance.colors.colSecondaryContainer
                    onClicked: Qt.openUrlExternally(updateRoot.hasUpdate && updateRoot.compareUrl() !== "" ? updateRoot.compareUrl() : ("https://github.com/" + updateRoot.repoSlug))

                    RowLayout {
                        id: gitBtnRow
                        anchors.centerIn: parent
                        spacing: 8 * hero.s
                        MaterialSymbol {
                            text: "open_in_new"
                            iconSize: 18 * hero.s
                            color: Appearance.colors.colOnSecondaryContainer
                        }
                        StyledText {
                            text: updateRoot.hasUpdate && updateRoot.compareUrl() !== "" ? I18nService.tr("Compare") : I18nService.tr("GitHub")
                            font.weight: Font.Medium
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnSecondaryContainer
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                RippleButton {
                    visible: installState.inject
                    Layout.preferredHeight: 44 * hero.s
                    implicitWidth: allFilesBtnRow.implicitWidth + 32 * hero.s
                    implicitHeight: 44 * hero.s
                    buttonRadius: 22 * hero.s
                    colBackground: "transparent"
                    enabled: !updateRoot.updateRunning
                    onClicked: updateRoot.launchUpdate("all")

                    StyledToolTip {
                        text: I18nService.tr("Updates every managed config, not just the shell.")
                    }

                    RowLayout {
                        id: allFilesBtnRow
                        anchors.centerIn: parent
                        spacing: 8 * hero.s
                        MaterialSymbol {
                            text: "downloading"
                            iconSize: 18 * hero.s
                            color: Appearance.colors.colError
                        }
                        StyledText {
                            text: I18nService.tr("Update All Files")
                            font.weight: Font.Medium
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colError
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: devBannerRow.implicitHeight + (24 * Appearance.effectiveScale)
        radius: 20 * Appearance.effectiveScale
        color: Appearance.colors.colTertiaryContainer
        visible: updateRoot.isDevSymlink && installState.install_dir !== ""

        RowLayout {
            id: devBannerRow
            anchors.fill: parent
            anchors {
                leftMargin: 16 * Appearance.effectiveScale
                rightMargin: 16 * Appearance.effectiveScale
                topMargin: 12 * Appearance.effectiveScale
                bottomMargin: 12 * Appearance.effectiveScale
            }
            spacing: 12 * Appearance.effectiveScale

            MaterialSymbol {
                text: "code"
                iconSize: 20 * Appearance.effectiveScale
                color: Appearance.colors.colOnTertiaryContainer
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2 * Appearance.effectiveScale
                StyledText {
                    Layout.fillWidth: true
                    text: I18nService.tr("Dev mode — symlink detected")
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnTertiaryContainer
                }
                StyledText {
                    Layout.fillWidth: true
                    text: I18nService.tr("Updates are blocked to protect your symlink. Use git pull in your dev checkout instead.")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnTertiaryContainer
                    wrapMode: Text.Wrap
                }
            }
        }
    }

    // --- 2. Live update log (visible pull process) ---

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: updateLogCol.implicitHeight + (40 * Appearance.effectiveScale)
        radius: 20 * Appearance.effectiveScale
        color: Appearance.m3colors.m3surfaceContainerHigh
        visible: updateRoot.updateLogVisible && installState.install_dir !== ""

        ColumnLayout {
            id: updateLogCol
            anchors.fill: parent
            anchors.margins: 20 * Appearance.effectiveScale
            spacing: 12 * Appearance.effectiveScale

            RowLayout {
                Layout.fillWidth: true
                spacing: 10 * Appearance.effectiveScale

                MaterialLoadingIndicator {
                    visible: updateRoot.updateRunning
                    implicitSize: 20 * Appearance.effectiveScale
                }
                MaterialSymbol {
                    visible: !updateRoot.updateRunning
                    text: updateRoot.updateLog === "" ? "terminal" : (updateRoot.updateExitCode === 0 ? "check_circle" : "error")
                    iconSize: 20 * Appearance.effectiveScale
                    color: updateRoot.updateLog !== "" && updateRoot.updateExitCode !== 0 ? Appearance.colors.colError : Appearance.colors.colPrimary
                }
                StyledText {
                    Layout.fillWidth: true
                    text: updateRoot.updateRunning ? I18nService.tr("Updating… live output below") : (updateRoot.updateExitCode === 0 ? I18nService.tr("Update log") : I18nService.tr("Update log — failed"))
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }

                RippleButton {
                    visible: !updateRoot.updateRunning
                    implicitWidth: 90 * Appearance.effectiveScale
                    implicitHeight: 34 * Appearance.effectiveScale
                    buttonRadius: 17 * Appearance.effectiveScale
                    colBackground: Appearance.colors.colSecondaryContainer
                    onClicked: updateRoot.updateLogVisible = false
                    StyledText {
                        anchors.centerIn: parent
                        text: I18nService.tr("Clear")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnSecondaryContainer
                    }
                }
            }

            Flickable {
                id: updateLogFlick
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(updateLogText.implicitHeight, 280 * Appearance.effectiveScale)
                contentHeight: updateLogText.implicitHeight
                clip: true
                StyledText {
                    id: updateLogText
                    width: updateLogFlick.width
                    text: updateRoot.updateLog === "" ? I18nService.tr("Waiting for output…") : updateRoot.updateLog
                    font.family: Appearance.font.family.monospace
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.WrapAnywhere
                }
            }
        }
    }

    // --- 4. What's New: clear grouped update log (ala ii) ---
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 10 * Appearance.effectiveScale
        visible: installState.install_dir !== ""

        RowLayout {
            spacing: 10 * Appearance.effectiveScale
            MaterialSymbol {
                text: updateRoot.hasUpdate ? "new_releases" : (updateRoot.aheadCount > 0 && updateRoot.remoteSha !== "" ? "publish" : "history")
                iconSize: 20 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                Layout.fillWidth: true
                text: {
                    if (updateRoot.hasUpdate)
                        return I18nService.tr("What's new (%1)").arg(updateRoot.whatsNewCommits.length);
                    if (updateRoot.aheadCount > 0 && updateRoot.remoteSha !== "")
                        return I18nService.tr("Your local commits (%1)").arg(updateRoot.aheadCommits.length);
                    return I18nService.tr("Recent changes");
                }
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
            RippleButton {
                visible: updateRoot.compareUrl() !== ""
                implicitWidth: 150 * Appearance.effectiveScale
                implicitHeight: 34 * Appearance.effectiveScale
                buttonRadius: 17 * Appearance.effectiveScale
                colBackground: Appearance.colors.colSecondaryContainer
                onClicked: Qt.openUrlExternally(updateRoot.compareUrl())
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6 * Appearance.effectiveScale
                    MaterialSymbol {
                        text: "compare_arrows"
                        iconSize: 16 * Appearance.effectiveScale
                        color: Appearance.colors.colOnSecondaryContainer
                    }
                    StyledText {
                        text: I18nService.tr("Compare")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnSecondaryContainer
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: whatsNewBody.implicitHeight + (40 * Appearance.effectiveScale)
            radius: 20 * Appearance.effectiveScale
            color: Appearance.m3colors.m3surfaceContainerHigh

            ColumnLayout {
                id: whatsNewBody
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                spacing: 12 * Appearance.effectiveScale

                RowLayout {
                    visible: updateRoot.revLoading || updateRoot.recentLoading || updateRoot.aheadLoading
                    spacing: 8 * Appearance.effectiveScale
                    MaterialLoadingIndicator { implicitSize: 20 * Appearance.effectiveScale }
                    StyledText {
                        text: I18nService.tr("Fetching commits…")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }

                StyledText {
                    visible: !updateRoot.revLoading && !updateRoot.recentLoading && !updateRoot.aheadLoading && updateRoot.whatsNewCommits.length === 0
                    Layout.fillWidth: true
                    text: I18nService.tr("No commits found. Check your connection, then press Check Now.")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.Wrap
                }

                GroupedCommitList {
                    Layout.fillWidth: true
                    visible: updateRoot.whatsNewCommits.length > 0
                    commits: updateRoot.whatsNewCommits
                }

                StyledText {
                    visible: updateRoot.isDiverged && updateRoot.aheadCommits.length > 0
                    Layout.fillWidth: true
                    Layout.topMargin: 8 * Appearance.effectiveScale
                    text: I18nService.tr("Not on the remote yet (%1)").arg(updateRoot.aheadCommits.length)
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colSubtext
                }

                GroupedCommitList {
                    Layout.fillWidth: true
                    visible: updateRoot.isDiverged && updateRoot.aheadCommits.length > 0
                    commits: updateRoot.aheadCommits
                }
            }
        }
    }

    // --- 5. Release history: one accordion per version ---
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 10 * Appearance.effectiveScale
        visible: installState.install_dir !== ""

        RowLayout {
            spacing: 10 * Appearance.effectiveScale
            MaterialSymbol {
                text: "local_offer"
                iconSize: 20 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                Layout.fillWidth: true
                text: I18nService.tr("Release history (%1)").arg(updateRoot.tagList.length)
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
            RippleButton {
                visible: updateRoot.tagUrl(updateRoot.latestTag) !== ""
                implicitWidth: 150 * Appearance.effectiveScale
                implicitHeight: 34 * Appearance.effectiveScale
                buttonRadius: 17 * Appearance.effectiveScale
                colBackground: Appearance.colors.colSecondaryContainer
                onClicked: Qt.openUrlExternally(updateRoot.tagUrl(updateRoot.latestTag))
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6 * Appearance.effectiveScale
                    MaterialSymbol {
                        text: "open_in_new"
                        iconSize: 16 * Appearance.effectiveScale
                        color: Appearance.colors.colOnSecondaryContainer
                    }
                    StyledText {
                        text: I18nService.tr("Releases")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnSecondaryContainer
                    }
                }
            }
        }

        RowLayout {
            visible: updateRoot.tagsLoading
            spacing: 8 * Appearance.effectiveScale
            MaterialLoadingIndicator { implicitSize: 20 * Appearance.effectiveScale }
            StyledText {
                text: I18nService.tr("Fetching releases…")
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
            }
        }

        StyledText {
            visible: !updateRoot.tagsLoading && updateRoot.tagList.length === 0
            Layout.fillWidth: true
            text: I18nService.tr("No releases found yet.")
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
        }

        Repeater {
            model: updateRoot.tagList
            delegate: Item {
                id: versionItem
                required property var modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: versionContent.implicitHeight

                readonly property string tagName: String(modelData.name || "")
                readonly property string tagDate: String(modelData.date || "")
                readonly property string tagSubject: String(modelData.subject || "")
                readonly property string tagBody: String(modelData.body || "")
                readonly property string prevTag: (index + 1 < updateRoot.tagList.length) ? String(updateRoot.tagList[index + 1].name || "") : ""
                readonly property string logRange: prevTag === "" ? tagName : (prevTag + ".." + tagName)
                readonly property bool isLatest: index === 0
                readonly property bool isInstalled: {
                    var short_local = updateRoot.localSha.substring(0, 7);
                    if (short_local === "")
                        return false;
                    return String(modelData.tagCommit || "") === short_local || (String(modelData.tagCommit || "") === "" && String(modelData.tagObj || "") === short_local);
                }
                readonly property string fullNotes: updateRoot.changelogFor(tagName)

                property bool expanded: updateRoot.expandedTagIndex === index
                property var versionCommits: []
                property bool versionLoaded: false
                property bool versionLoading: false

                function toggle() {
                    updateRoot.expandedTagIndex = versionItem.expanded ? -1 : versionItem.index;
                }

                Process {
                    id: versionLogProc
                    command: ["bash", "-c", `cd '${installState.install_dir}' && git log ${versionItem.logRange} --pretty=format:'%H%x1f%an%x1f%ad%x1f%s%x1f%b%x1e' --date=short 2>/dev/null`]
                    running: versionItem.expanded && !versionItem.versionLoaded && !versionItem.versionLoading && installState.install_dir !== ""
                    onRunningChanged: if (running) versionItem.versionLoading = true
                    stdout: StdioCollector {
                        onStreamFinished: {
                            versionItem.versionCommits = updateRoot.parseCommitLog(text);
                            versionItem.versionLoaded = true;
                            versionItem.versionLoading = false;
                        }
                    }
                }

                onExpandedChanged: {
                    if (expanded && !versionLoaded && !versionLoading && !versionLogProc.running && installState.install_dir !== "") {
                        versionLoading = true;
                        versionLogProc.running = false;
                        versionLogProc.running = true;
                    }
                }

                ColumnLayout {
                    id: versionContent
                    width: parent.width
                    spacing: 0

                    // Accordion header
                    RippleButton {
                        id: versionHeader
                        Layout.fillWidth: true
                        implicitHeight: 64 * Appearance.effectiveScale
                        buttonRadius: 16 * Appearance.effectiveScale
                        colBackground: versionItem.expanded ? Appearance.colors.colLayer1Hover : Appearance.m3colors.m3surfaceContainerHigh
                        onClicked: versionItem.toggle()

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16 * Appearance.effectiveScale
                            anchors.rightMargin: 12 * Appearance.effectiveScale
                            spacing: 12 * Appearance.effectiveScale

                            Rectangle {
                                implicitWidth: 40 * Appearance.effectiveScale
                                implicitHeight: 40 * Appearance.effectiveScale
                                radius: 20 * Appearance.effectiveScale
                                color: versionItem.isInstalled ? Appearance.colors.colPrimaryContainer : Appearance.colors.colSecondaryContainer
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: versionItem.isInstalled ? "check_circle" : "local_offer"
                                    iconSize: 20 * Appearance.effectiveScale
                                    color: versionItem.isInstalled ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSecondaryContainer
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2 * Appearance.effectiveScale
                                RowLayout {
                                    spacing: 8 * Appearance.effectiveScale
                                    StyledText {
                                        text: versionItem.tagName
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                        font.weight: Font.DemiBold
                                        color: Appearance.colors.colOnLayer1
                                    }
                                    Rectangle {
                                        visible: versionItem.isLatest
                                        implicitWidth: latestLbl.implicitWidth + 16 * Appearance.effectiveScale
                                        implicitHeight: latestLbl.implicitHeight + 6 * Appearance.effectiveScale
                                        radius: 10 * Appearance.effectiveScale
                                        color: Appearance.colors.colPrimary
                                        StyledText {
                                            id: latestLbl
                                            anchors.centerIn: parent
                                            text: I18nService.tr("Latest")
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                            font.weight: Font.DemiBold
                                            color: Appearance.colors.colOnPrimary
                                        }
                                    }
                                    Rectangle {
                                        visible: versionItem.isInstalled
                                        implicitWidth: instLbl.implicitWidth + 16 * Appearance.effectiveScale
                                        implicitHeight: instLbl.implicitHeight + 6 * Appearance.effectiveScale
                                        radius: 10 * Appearance.effectiveScale
                                        color: Appearance.colors.colPrimaryContainer
                                        StyledText {
                                            id: instLbl
                                            anchors.centerIn: parent
                                            text: I18nService.tr("Installed")
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                            font.weight: Font.DemiBold
                                            color: Appearance.colors.colOnPrimaryContainer
                                        }
                                    }
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: (versionItem.tagDate !== "" ? versionItem.tagDate + " · " : "") + (versionItem.tagSubject !== "" ? versionItem.tagSubject : I18nService.tr("Release"))
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colSubtext
                                    elide: Text.ElideRight
                                }
                            }

                            MaterialSymbol {
                                text: versionItem.expanded ? "expand_less" : "expand_more"
                                iconSize: 20 * Appearance.effectiveScale
                                color: Appearance.colors.colSubtext
                            }
                        }

                        // Merge header with body when open
                        Rectangle {
                            anchors.fill: parent
                            visible: versionItem.expanded
                            color: versionHeader.colBackground
                            z: -1
                            radius: 16 * Appearance.effectiveScale
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: 16 * Appearance.effectiveScale
                                color: parent.color
                            }
                        }
                    }

                    // Accordion body
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: versionItem.expanded ? (versionBody.implicitHeight + (32 * Appearance.effectiveScale)) : 0
                        clip: true
                        color: Appearance.colors.colLayer2
                        radius: 16 * Appearance.effectiveScale
                        opacity: versionItem.expanded ? 1 : 0
                        visible: Layout.preferredHeight > 0
                        Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        Rectangle {
                            width: parent.width
                            height: 16 * Appearance.effectiveScale
                            anchors.top: parent.top
                            color: parent.color
                        }

                        ColumnLayout {
                            id: versionBody
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: 16 * Appearance.effectiveScale
                            }
                            spacing: 12 * Appearance.effectiveScale

                            // Full release-note text: CHANGELOG section wins, tag message is the fallback.
                            StyledText {
                                visible: versionItem.fullNotes !== ""
                                Layout.fillWidth: true
                                text: versionItem.fullNotes
                                textFormat: Text.MarkdownText
                                wrapMode: Text.Wrap
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer1
                                onLinkActivated: link => Qt.openUrlExternally(link)
                            }
                            StyledText {
                                visible: versionItem.fullNotes === "" && versionItem.tagBody !== ""
                                Layout.fillWidth: true
                                text: versionItem.tagBody
                                textFormat: Text.MarkdownText
                                wrapMode: Text.Wrap
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer1
                                onLinkActivated: link => Qt.openUrlExternally(link)
                            }

                            RowLayout {
                                visible: versionItem.versionLoading
                                spacing: 8 * Appearance.effectiveScale
                                MaterialLoadingIndicator { implicitSize: 18 * Appearance.effectiveScale }
                                StyledText {
                                    text: I18nService.tr("Loading commits for %1…").arg(versionItem.tagName)
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colSubtext
                                }
                            }

                            StyledText {
                                visible: versionItem.versionLoaded
                                Layout.fillWidth: true
                                text: I18nService.tr("%1 commits in %2").arg(versionItem.versionCommits.length).arg(versionItem.tagName)
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colSubtext
                            }

                            GroupedCommitList {
                                Layout.fillWidth: true
                                visible: versionItem.versionLoaded && versionItem.versionCommits.length > 0
                                commits: versionItem.versionCommits
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8 * Appearance.effectiveScale

                                RippleButton {
                                    visible: updateRoot.tagUrl(versionItem.tagName) !== ""
                                    implicitHeight: 36 * Appearance.effectiveScale
                                    implicitWidth: 150 * Appearance.effectiveScale
                                    buttonRadius: 18 * Appearance.effectiveScale
                                    colBackground: Appearance.colors.colSecondaryContainer
                                    onClicked: Qt.openUrlExternally(updateRoot.tagUrl(versionItem.tagName))
                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 6 * Appearance.effectiveScale
                                        MaterialSymbol {
                                            text: "open_in_new"
                                            iconSize: 16 * Appearance.effectiveScale
                                            color: Appearance.colors.colOnSecondaryContainer
                                        }
                                        StyledText {
                                            text: I18nService.tr("GitHub")
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            color: Appearance.colors.colOnSecondaryContainer
                                        }
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                RippleButton {
                                    visible: !versionItem.isInstalled
                                    implicitHeight: 36 * Appearance.effectiveScale
                                    implicitWidth: 190 * Appearance.effectiveScale
                                    buttonRadius: 18 * Appearance.effectiveScale
                                    colBackground: Appearance.colors.colPrimary
                                    onClicked: {
                                        updateRoot.installTagTarget = versionItem.tagName;
                                        installTagProc.running = false;
                                        installTagProc.running = true;
                                    }
                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 6 * Appearance.effectiveScale
                                        MaterialSymbol {
                                            text: "download"
                                            iconSize: 16 * Appearance.effectiveScale
                                            color: Appearance.colors.colOnPrimary
                                        }
                                        StyledText {
                                            text: I18nService.tr("Install this version")
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            font.weight: Font.Medium
                                            color: Appearance.colors.colOnPrimary
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    StyledText {
        visible: installState.install_dir === ""
        text: I18nService.tr("Update system unavailable. Installation state missing.")
        color: Appearance.colors.colError
        Layout.alignment: Qt.AlignHCenter
    }
}

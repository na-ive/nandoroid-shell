import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import "."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 4 * Appearance.effectiveScale

    SearchHandler {
        searchString: "Sounds"
        aliases: ["Notification Sound", "Ringtone", "Alarm", "Timer", "Audio Theme"]
    }

    RowLayout {
        spacing: 12 * Appearance.effectiveScale
        Layout.bottomMargin: 8 * Appearance.effectiveScale
        MaterialSymbol {
            text: "music_note"
            iconSize: 24 * Appearance.effectiveScale
            color: Appearance.colors.colPrimary
        }
        StyledText {
            text: I18nService.tr("Sounds")
            font.pixelSize: Appearance.font.pixelSize.large
            font.family: Appearance.font.family.title
            font.weight: Font.Medium
            color: Appearance.colors.colOnLayer1
        }
    }

    readonly property string notificationSound: (Config.ready && Config.options.sounds) ? Config.options.sounds.notification : ""
    property string previewing: "" // "notification" | "alarm" | "ringtone" | ""

    function _baseName(path) { return path.split("/").pop() || path; }

    // Resolve .oga/.ogg at runtime for theme defaults (oxygen ships only .ogg).
    // ~/.local/share/sounds wins over /usr/share/sounds; falls back to the
    // freedesktop theme when a custom theme lacks the sound.
    function previewCommand(kind) {
        const custom = (Config.ready && Config.options.sounds) ? Config.options.sounds[kind] : "";
        if (custom !== "") return ["ffplay", "-nodisp", "-autoexit", "-loglevel", "quiet", custom];
        const name = kind === "notification" ? "message-new-instant"
            : kind === "alarm" ? "alarm-clock-elapsed"
            : "complete";
        const local = `${Directories.home.replace("file://", "")}/.local/share/sounds/${Audio.audioTheme}/stereo/${name}`;
        const system = `/usr/share/sounds/${Audio.audioTheme}/stereo/${name}`;
        const freedesktop = `/usr/share/sounds/freedesktop/stereo/${name}`;
        return ["bash", "-c", `f='${local}.oga'; [ -f "$f" ] || f='${local}.ogg'; [ -f "$f" ] || f='${system}.oga'; [ -f "$f" ] || f='${system}.ogg'; [ -f "$f" ] || f='${freedesktop}.oga'; [ -f "$f" ] || f='${freedesktop}.ogg'; exec ffplay -nodisp -autoexit -loglevel quiet "$f"`];
    }

    // Toggle preview: play once, or stop the running one so sounds never stack.
    // Killing the process delivers onExited asynchronously — route it through a
    // short timer so the exit of a REPLACED preview never clears the new one
    function togglePreview(kind) {
        if (root.previewing === kind) {
            previewProc.running = false;
            root.previewing = "";
            return;
        }
        previewProc.running = false;
        previewProc.command = root.previewCommand(kind);
        previewProc.running = true;
        root.previewing = kind;
    }

    Process {
        id: previewProc
        command: []
        onExited: previewClearTimer.restart()
    }

    Timer {
        id: previewClearTimer
        interval: 150
        onTriggered: if (!previewProc.running) root.previewing = ""
    }

    // ── Sound Theme Card ──
    SegmentedWrapper {
        id: themeCard
        Layout.fillWidth: true
        implicitHeight: Math.max(64 * Appearance.effectiveScale, themeRow.implicitHeight)
        orientation: Qt.Vertical
        color: Appearance.m3colors.m3surfaceContainerHigh

        // Card-wide click toggles the dropdown (same pattern as SysLanguage)
        RippleButton {
            id: themeClickArea
            anchors.fill: parent
            colBackground: Appearance.m3colors.m3surfaceContainerHigh
            colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
            buttonRadius: 0
            topLeftRadius: themeCard.rTopLeft
            topRightRadius: themeCard.rTopRight
            bottomLeftRadius: themeCard.rBottomLeft
            bottomRightRadius: themeCard.rBottomRight

            property real comboClosedAt: 0

            onClicked: {
                if (Date.now() - comboClosedAt < 250) return;
                themeCombo.isOpened = !themeCombo.isOpened;
            }

            Connections {
                target: themeCombo
                function onIsOpenedChanged() {
                    if (!themeCombo.isOpened) themeClickArea.comboClosedAt = Date.now();
                }
            }

            StyledToolTip {
                extraVisibleCondition: themeClickArea.hovered || themeClickArea.realHovered
                text: I18nService.tr("System sounds source (~/.local/share/sounds, /usr/share/sounds)")
            }
        }

        RowLayout {
            id: themeRow
            anchors.fill: parent
            anchors {
                leftMargin: 16 * Appearance.effectiveScale
                rightMargin: 16 * Appearance.effectiveScale
            }
            spacing: 16 * Appearance.effectiveScale

            MaterialSymbol { Layout.alignment: Qt.AlignVCenter; text: "palette"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }

            StyledText {
                text: I18nService.tr("Sound Theme")
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }

            StyledComboBox {
                id: themeCombo
                Layout.preferredWidth: 220 * Appearance.effectiveScale
                Layout.alignment: Qt.AlignVCenter
                bgRadius: height / 2
                searchable: false
                placeholder: ""
                model: themeListProc.output
                text: (Config.ready && Config.options.sounds) ? Config.options.sounds.theme : "freedesktop"
                onAccepted: (val) => {
                    if (Config.ready && Config.options.sounds) Config.options.sounds.theme = val;
                }
            }
        }
    }

    // ── Notification Sound Card ──
    SegmentedWrapper {
        Layout.fillWidth: true
        implicitHeight: Math.max(64 * Appearance.effectiveScale, notifRow.implicitHeight)
        orientation: Qt.Vertical
        color: Appearance.m3colors.m3surfaceContainerHigh

        RowLayout {
            id: notifRow
            anchors.fill: parent
            anchors {
                leftMargin: 16 * Appearance.effectiveScale
                rightMargin: 16 * Appearance.effectiveScale
            }
            spacing: 16 * Appearance.effectiveScale

            MaterialSymbol { Layout.alignment: Qt.AlignVCenter; text: "notifications"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }

            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                StyledText {
                    text: I18nService.tr("Notification Sound")
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    text: root.notificationSound !== "" ? root._baseName(root.notificationSound) : I18nService.tr("Theme default")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                spacing: 8 * Appearance.effectiveScale
                Layout.alignment: Qt.AlignVCenter

                RippleButton {
                    implicitWidth: 120 * Appearance.effectiveScale
                    implicitHeight: 36 * Appearance.effectiveScale
                    buttonRadius: 18 * Appearance.effectiveScale
                    colBackground: Appearance.m3colors.m3primaryContainer

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6 * Appearance.effectiveScale
                        MaterialSymbol {
                            text: root.previewing === "notification" ? "stop" : "play_arrow"
                            iconSize: 16 * Appearance.effectiveScale
                            color: Appearance.m3colors.m3onPrimaryContainer
                        }
                        StyledText {
                            text: root.previewing === "notification" ? I18nService.tr("Stop") : I18nService.tr("Preview")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.m3colors.m3onPrimaryContainer
                        }
                    }

                    onClicked: root.togglePreview("notification")
                }

                RippleButton {
                    implicitWidth: 120 * Appearance.effectiveScale
                    implicitHeight: 36 * Appearance.effectiveScale
                    buttonRadius: 18 * Appearance.effectiveScale
                    colBackground: Appearance.m3colors.m3primaryContainer

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6 * Appearance.effectiveScale
                        MaterialSymbol {
                            text: "folder_open"
                            iconSize: 16 * Appearance.effectiveScale
                            color: Appearance.m3colors.m3onPrimaryContainer
                        }
                        StyledText {
                            text: I18nService.tr("Browse")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.m3colors.m3onPrimaryContainer
                        }
                    }

                    onClicked: soundPickerProc.open("notification")
                }

                Item {
                    visible: root.notificationSound !== ""
                    implicitWidth: 120 * Appearance.effectiveScale
                    implicitHeight: 36 * Appearance.effectiveScale

                    Rectangle {
                        anchors.fill: parent
                        radius: 18 * Appearance.effectiveScale
                        color: "transparent"
                        border.width: 1 * Appearance.effectiveScale
                        border.color: Appearance.colors.colError
                        opacity: notifClearArea.containsMouse ? 0.8 : 1
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6 * Appearance.effectiveScale
                        MaterialSymbol {
                            text: "close"
                            iconSize: 16 * Appearance.effectiveScale
                            color: Appearance.colors.colError
                        }
                        StyledText {
                            text: I18nService.tr("Clear")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colError
                        }
                    }

                    MouseArea {
                        id: notifClearArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: if (Config.ready) Config.options.sounds.notification = ""
                    }
                }
            }
        }
    }

    // ── Alarm / Timer Sound Cards (independent ringtones) ──
    Repeater {
        model: [
            { kind: "alarm", icon: "alarm", title: I18nService.tr("Alarm Sound") },
            { kind: "ringtone", icon: "timer", title: I18nService.tr("Timer Sound") }
        ]

        delegate: SegmentedWrapper {
            id: soundCard
            required property var modelData
            readonly property string kind: modelData.kind
            readonly property string soundPath: (Config.ready && Config.options.sounds) ? Config.options.sounds[kind] : ""
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, soundRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            RowLayout {
                id: soundRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol { Layout.alignment: Qt.AlignVCenter; text: soundCard.modelData.icon; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }

                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true
                    StyledText {
                        text: soundCard.modelData.title
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: soundCard.soundPath !== "" ? root._baseName(soundCard.soundPath) : I18nService.tr("Theme default")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                    }
                }

                RowLayout {
                    spacing: 8 * Appearance.effectiveScale
                    Layout.alignment: Qt.AlignVCenter

                    RippleButton {
                        implicitWidth: 120 * Appearance.effectiveScale
                        implicitHeight: 36 * Appearance.effectiveScale
                        buttonRadius: 18 * Appearance.effectiveScale
                        colBackground: Appearance.m3colors.m3primaryContainer

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6 * Appearance.effectiveScale
                            MaterialSymbol {
                                text: root.previewing === soundCard.kind ? "stop" : "play_arrow"
                                iconSize: 16 * Appearance.effectiveScale
                                color: Appearance.m3colors.m3onPrimaryContainer
                            }
                            StyledText {
                                text: root.previewing === soundCard.kind ? I18nService.tr("Stop") : I18nService.tr("Preview")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.m3colors.m3onPrimaryContainer
                            }
                        }

                        onClicked: root.togglePreview(soundCard.kind)
                    }

                    RippleButton {
                        implicitWidth: 120 * Appearance.effectiveScale
                        implicitHeight: 36 * Appearance.effectiveScale
                        buttonRadius: 18 * Appearance.effectiveScale
                        colBackground: Appearance.m3colors.m3primaryContainer

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6 * Appearance.effectiveScale
                            MaterialSymbol {
                                text: "folder_open"
                                iconSize: 16 * Appearance.effectiveScale
                                color: Appearance.m3colors.m3onPrimaryContainer
                            }
                            StyledText {
                                text: I18nService.tr("Browse")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.m3colors.m3onPrimaryContainer
                            }
                        }

                        onClicked: soundPickerProc.open(soundCard.kind)
                    }

                    Item {
                        visible: soundCard.soundPath !== ""
                        implicitWidth: 120 * Appearance.effectiveScale
                        implicitHeight: 36 * Appearance.effectiveScale

                        Rectangle {
                            anchors.fill: parent
                            radius: 18 * Appearance.effectiveScale
                            color: "transparent"
                            border.width: 1 * Appearance.effectiveScale
                            border.color: Appearance.colors.colError
                            opacity: clearArea.containsMouse ? 0.8 : 1
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6 * Appearance.effectiveScale
                            MaterialSymbol {
                                text: "close"
                                iconSize: 16 * Appearance.effectiveScale
                                color: Appearance.colors.colError
                            }
                            StyledText {
                                text: I18nService.tr("Clear")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colError
                            }
                        }

                        MouseArea {
                            id: clearArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: if (Config.ready) Config.options.sounds[soundCard.kind] = ""
                        }
                    }
                }
            }
        }
    }

    // ── File picker (zenity) ──
    Process {
        id: soundPickerProc
        property string target: "notification"
        function open(which) {
            soundPickerProc.target = which;
            soundPickerProc.running = true;
        }
        command: [
            "zenity", "--file-selection", "--title=Select Sound",
            "--file-filter=Audio | *.oga *.ogg *.wav *.mp3 *.flac *.m4a",
            "--file-filter=All files | *"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const path = this.text.trim();
                if (path === "" || !Config.ready || !Config.options.sounds) return;
                Config.options.sounds[soundPickerProc.target] = path;
            }
        }
    }

    // ── Available sound themes ──
    Process {
        id: themeListProc
        property var output: ["freedesktop"]
        // NOTE: plain string (not template literal) — ${d} must reach bash verbatim.
        // XDG data dir (~/.local/share/sounds, where KDE installs) is scanned first
        command: ["bash", "-c", "for d in \"$HOME\"/.local/share/sounds/*/ /usr/share/sounds/*/; do [ -d \"${d}stereo\" ] && basename \"$d\"; done | awk '!seen[$0]++'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n").map(l => l.trim()).filter(l => l !== "");
                if (lines.length > 0) themeListProc.output = lines;
            }
        }
    }
}

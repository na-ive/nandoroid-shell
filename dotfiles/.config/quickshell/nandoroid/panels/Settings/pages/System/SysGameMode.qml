import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    SearchHandler {
        searchString: "Game Mode"
        aliases: ["Gaming", "Do Not Disturb", "DND", "Keep Awake", "Caffeine", "Performance", "Performance Mode", "Power Profile", "Auto DND"]
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4 * Appearance.effectiveScale

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 8 * Appearance.effectiveScale
            MaterialSymbol {
                text: "gamepad"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: I18nService.tr("Game Mode")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }

        // Auto DND in Game Mode (whole card clickable)
        SegmentedWrapper {
            id: autoDndCard
            Layout.fillWidth: true
            implicitHeight: autoDndRow.implicitHeight + (24 * Appearance.effectiveScale)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh
            smallRadius: 8 * Appearance.effectiveScale
            fullRadius: 20 * Appearance.effectiveScale

            RippleButton {
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: autoDndCard.rTopLeft
                topRightRadius: autoDndCard.rTopRight
                bottomLeftRadius: autoDndCard.rBottomLeft
                bottomRightRadius: autoDndCard.rBottomRight
                onClicked: toggleAutoDnd()

                StyledToolTip {
                    extraVisibleCondition: parent.hovered || parent.realHovered
                    text: I18nService.tr("Automatically enable Do Not Disturb when Game Mode turns on, and restore it afterwards.")
                }
            }

            RowLayout {
                id: autoDndRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                    topMargin: 12 * Appearance.effectiveScale
                    bottomMargin: 12 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "notifications_off"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Auto Do Not Disturb")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                AndroidToggle {
                    checked: Config.ready && (Config.options.gameModeState.autoDnd ?? true)
                    onToggled: toggleAutoDnd()
                }
            }
        }

        // Keep awake in Game Mode (whole card clickable)
        SegmentedWrapper {
            id: keepAwakeCard
            Layout.fillWidth: true
            implicitHeight: keepAwakeRow.implicitHeight + (24 * Appearance.effectiveScale)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh
            smallRadius: 8 * Appearance.effectiveScale
            fullRadius: 20 * Appearance.effectiveScale

            RippleButton {
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: keepAwakeCard.rTopLeft
                topRightRadius: keepAwakeCard.rTopRight
                bottomLeftRadius: keepAwakeCard.rBottomLeft
                bottomRightRadius: keepAwakeCard.rBottomRight
                onClicked: toggleKeepAwake()

                StyledToolTip {
                    extraVisibleCondition: parent.hovered || parent.realHovered
                    text: I18nService.tr("Prevent the display from sleeping while Game Mode is on, using Caffeine.")
                }
            }

            RowLayout {
                id: keepAwakeRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                    topMargin: 12 * Appearance.effectiveScale
                    bottomMargin: 12 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "coffee"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Keep Awake")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                AndroidToggle {
                    checked: Config.ready && (Config.options.gameModeState.keepAwake ?? true)
                    onToggled: toggleKeepAwake()
                }
            }
        }

        // Performance Mode in Game Mode (whole card clickable)
        SegmentedWrapper {
            id: performanceCard
            Layout.fillWidth: true
            implicitHeight: performanceRow.implicitHeight + (24 * Appearance.effectiveScale)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh
            smallRadius: 8 * Appearance.effectiveScale
            fullRadius: 20 * Appearance.effectiveScale

            RippleButton {
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: performanceCard.rTopLeft
                topRightRadius: performanceCard.rTopRight
                bottomLeftRadius: performanceCard.rBottomLeft
                bottomRightRadius: performanceCard.rBottomRight
                onClicked: togglePerformance()

                StyledToolTip {
                    extraVisibleCondition: parent.hovered || parent.realHovered
                    text: I18nService.tr("Automatically switch to the Performance power profile when Game Mode turns on, and restore it afterwards.")
                }
            }

            RowLayout {
                id: performanceRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                    topMargin: 12 * Appearance.effectiveScale
                    bottomMargin: 12 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "local_fire_department"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Performance Mode")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                AndroidToggle {
                    checked: Config.ready && (Config.options.gameModeState.autoPerformance ?? true)
                    onToggled: togglePerformance()
                }
            }
        }
    }

    function toggleAutoDnd() {
        if (!Config.ready) return;
        const next = !(Config.options.gameModeState.autoDnd ?? true);
        Config.options.gameModeState.autoDnd = next;
        // Apply immediately if game mode is already active
        if (GameMode.active) {
            if (next) {
                Config.options.gameModeState.prevSilent = Notifications.silent;
                Notifications.silent = true;
            } else {
                Notifications.silent = Config.options.gameModeState.prevSilent ?? false;
            }
        }
    }

    function toggleKeepAwake() {
        if (!Config.ready) return;
        const next = !(Config.options.gameModeState.keepAwake ?? true);
        Config.options.gameModeState.keepAwake = next;
        // Apply immediately if game mode is already active
        if (GameMode.active) {
            if (next) {
                Config.options.gameModeState.prevCaffeine = Config.options.quickSettings.caffeineActive;
                Config.options.quickSettings.caffeineActive = true;
            } else {
                Config.options.quickSettings.caffeineActive = Config.options.gameModeState.prevCaffeine ?? false;
            }
        }
    }

    function togglePerformance() {
        if (!Config.ready) return;
        const next = !(Config.options.gameModeState.autoPerformance ?? true);
        Config.options.gameModeState.autoPerformance = next;
        // Apply immediately if game mode is already active
        if (GameMode.active) {
            if (next) {
                Config.options.gameModeState.prevPowerProfile = PowerProfileService.currentProfile;
                PowerProfileService.setProfile("performance");
            } else {
                PowerProfileService.setProfile(Config.options.gameModeState.prevPowerProfile ?? "daily");
            }
        }
    }
}

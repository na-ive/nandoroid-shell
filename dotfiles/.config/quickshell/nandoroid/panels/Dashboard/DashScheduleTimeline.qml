import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

/**
 * Dashboard Tab 1: Schedule - "Today" timeline (Google Calendar style) with a floating "+" action.
 * State and actions live on the controller (`ctrl` = DashSchedule).
 */
Item {
    id: rootView
    property var ctrl: null
    anchors.fill: parent
    visible: ctrl._view === "timeline"

    function scrollToDayStart() {
        if (ctrl.dayOffset !== 0) {
            timelineFlickable.contentY = 0;
            return;
        }
        ctrl.nowFrac = ctrl._nowFrac();
        const target = ctrl.nowFrac * ctrl.timelineContentHeight;
        const maxScroll = Math.max(0, ctrl.timelineContentHeight - timelineFlickable.height);
        timelineFlickable.contentY = Math.max(0, Math.min(maxScroll, target - timelineFlickable.height / 2));
    }

    // ── Header island: day label + ‹ › (tinted with the Schedule accent) ──
    Rectangle {
        id: headerIsland

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: 56 * Appearance.effectiveScale
        height: 56 * Appearance.effectiveScale
        color: Appearance.colors.colSecondaryContainer
        radius: Appearance.rounding.large

        // ── Day navigation header ──
        RowLayout {
            anchors.fill: parent
            anchors.margins: 12 * Appearance.effectiveScale
            spacing: 8 * Appearance.effectiveScale

            // Interactive day label — click returns to today
            Item {
                id: labelSlot

                implicitWidth: labelText.width + 18 * Appearance.effectiveScale
                implicitHeight: 32 * Appearance.effectiveScale

                Rectangle {
                    id: labelPill

                    anchors.fill: parent
                    radius: 16 * Appearance.effectiveScale
                    visible: ctrl.dayOffset !== 0
                    color: labelMouse.containsMouse ? Appearance.colors.colLayer2 : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }

                    }

                }

                StyledText {
                    id: labelText

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 9 * Appearance.effectiveScale
                    text: (ctrl.dayOffset !== 0 ? "• " : "") + ctrl._dayLabel
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.DemiBold
                    color: Appearance.m3colors.m3onSurface
                }

                MouseArea {
                    id: labelMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: ctrl.dayOffset !== 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (ctrl.dayOffset !== 0)
                            ctrl.dayOffset = 0;

                    }
                }

                StyledToolTip {
                    x: labelText.x + (labelText.width - width) / 2
                    y: 34 * Appearance.effectiveScale
                    text: I18nService.tr("Back to today")
                    alternativeVisibleCondition: labelMouse.containsMouse && ctrl.dayOffset !== 0
                }

            }

            Item {
                Layout.fillWidth: true
                implicitHeight: 32 * Appearance.effectiveScale
            }

            // Navigation group: ‹ ›
            RowLayout {
                spacing: 4 * Appearance.effectiveScale

                RippleButton {
                    implicitWidth: 32 * Appearance.effectiveScale
                    implicitHeight: 32 * Appearance.effectiveScale
                    buttonRadius: 16 * Appearance.effectiveScale
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer2
                    colRipple: Appearance.colors.colLayer2Active
                    onClicked: ctrl.dayOffset -= 1

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "chevron_left"
                        iconSize: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3onSurface
                    }

                    StyledToolTip {
                        text: I18nService.tr("Previous day")
                    }

                }

                RippleButton {
                    implicitWidth: 32 * Appearance.effectiveScale
                    implicitHeight: 32 * Appearance.effectiveScale
                    buttonRadius: 16 * Appearance.effectiveScale
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer2
                    colRipple: Appearance.colors.colLayer2Active
                    onClicked: ctrl.dayOffset += 1

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "chevron_right"
                        iconSize: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3onSurface
                    }

                    StyledToolTip {
                        text: I18nService.tr("Next day")
                    }

                }

            }

        }
    }

    Rectangle {
        id: timelineIsland

        anchors.fill: parent
        anchors.topMargin: (56 + 12) * Appearance.effectiveScale
        color: Appearance.m3colors.m3surfaceContainer
        radius: Appearance.rounding.large

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12 * Appearance.effectiveScale
            spacing: 8 * Appearance.effectiveScale

            // ── Hour grid timeline ──
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
                clip: true

                Flickable {
                    id: timelineFlickable

                    anchors.fill: parent
                    clip: true
                    contentWidth: width
                    contentHeight: ctrl.timelineContentHeight
                    boundsBehavior: Flickable.StopAtBounds

                    Item {
                        width: timelineFlickable.width
                        height: ctrl.timelineContentHeight

                        // Horizontal grid lines
                        Repeater {
                            model: 25

                            delegate: Rectangle {
                                required property int index

                                x: ctrl.gutterWidth
                                y: index * ctrl.hourHeight
                                width: parent.width - ctrl.gutterWidth
                                height: 1
                                color: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.06)
                            }

                        }

                        // Hour label gutter
                        Column {
                            x: 0
                            y: 0
                            width: ctrl.gutterWidth

                            Repeater {
                                model: 24

                                delegate: Item {
                                    required property int index

                                    width: ctrl.gutterWidth
                                    height: ctrl.hourHeight

                                    StyledText {
                                        anchors.topMargin: 2 * Appearance.effectiveScale
                                        anchors.rightMargin: 8 * Appearance.effectiveScale
                                        text: ctrl._hourLabel(index)
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colSubtext
                                        horizontalAlignment: Text.AlignRight

                                        anchors {
                                            top: parent.top
                                            left: parent.left
                                            right: parent.right
                                        }

                                    }

                                }

                            }

                        }

                        // Unified event + reminder blocks (column-layout aware)
                        Item {
                            x: ctrl.gutterWidth
                            y: 0
                            width: parent.width - x
                            height: parent.height

                            Repeater {
                                model: ctrl.dayLayout

                                delegate: Item {

                                    id: blockDelegate
                                    required property var modelData
                                    readonly property bool isRem: modelData.isReminder
                                    readonly property var ev: modelData.isReminder ? ({"title": "", "time": "", "endTime": "", "id": "", "focus": false}) : modelData.item
                                    readonly property var rem: modelData.isReminder ? modelData.item : ({"text": "", "time": "", "id": "", "linkedTitle": ""})

                                    x: modelData.col / modelData.colCount * parent.width
                                    y: modelData.sf * ctrl.timelineContentHeight
                                    width: parent.width / modelData.colCount
                                    height: Math.max(ctrl.minBlockHeight, (modelData.ef - modelData.sf) * ctrl.timelineContentHeight)

                                    // ── Event block ──
                                    Rectangle {
                                        id: evBlock
                                        visible: !blockDelegate.isRem
                                        radius: Appearance.rounding.small
                                        color: blockDelegate.ev.focus ? Appearance.m3colors.m3tertiaryContainer : Appearance.colors.colLayer3
                                        clip: true

                                        anchors {
                                            fill: parent
                                            topMargin: 1 * Appearance.effectiveScale
                                            bottomMargin: 3 * Appearance.effectiveScale
                                            leftMargin: 0
                                            rightMargin: 1 * Appearance.effectiveScale
                                        }

                                        property bool isCompact: height <= (ctrl.hourHeight * 1.05)
                                        property string timeStr: ctrl._displayTime(blockDelegate.ev.time) + (blockDelegate.ev.endTime && blockDelegate.ev.endTime !== blockDelegate.ev.time ? " - " + ctrl._displayTime(blockDelegate.ev.endTime) : "")

                                        Item {
                                            anchors {
                                                fill: parent
                                                topMargin: evBlock.isCompact ? 0 : (6 * Appearance.effectiveScale)
                                                leftMargin: 10 * Appearance.effectiveScale
                                                rightMargin: 8 * Appearance.effectiveScale
                                            }

                                            RowLayout {
                                                visible: evBlock.isCompact
                                                anchors {
                                                    verticalCenter: parent.verticalCenter
                                                    left: parent.left
                                                }
                                                width: Math.min(implicitWidth, parent.width)
                                                spacing: 4 * Appearance.effectiveScale

                                                StyledText {
                                                    text: blockDelegate.ev.title
                                                    font.pixelSize: Appearance.font.pixelSize.small
                                                    font.weight: Font.Medium
                                                    color: blockDelegate.ev.focus ? Appearance.m3colors.m3onTertiaryContainer : Appearance.m3colors.m3onSurface
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }

                                                StyledText {
                                                    visible: evBlock.timeStr !== ""
                                                    text: "\u00b7"
                                                    font.pixelSize: Appearance.font.pixelSize.small
                                                    font.weight: Font.Medium
                                                    color: blockDelegate.ev.focus ? Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onTertiaryContainer, 0.75) : Appearance.colors.colSubtext
                                                    Layout.alignment: Qt.AlignVCenter
                                                }

                                                StyledText {
                                                    visible: evBlock.timeStr !== ""
                                                    text: evBlock.timeStr
                                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                                    color: blockDelegate.ev.focus ? Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onTertiaryContainer, 0.75) : Appearance.colors.colSubtext
                                                    Layout.alignment: Qt.AlignVCenter
                                                }
                                            }

                                            StyledText {
                                                id: evTitle
                                                visible: !evBlock.isCompact
                                                text: blockDelegate.ev.title
                                                font.pixelSize: Appearance.font.pixelSize.small
                                                font.weight: Font.Medium
                                                color: blockDelegate.ev.focus ? Appearance.m3colors.m3onTertiaryContainer : Appearance.m3colors.m3onSurface
                                                wrapMode: Text.Wrap
                                                maximumLineCount: 2
                                                elide: Text.ElideRight
                                                anchors {
                                                    top: parent.top
                                                    left: parent.left
                                                    right: parent.right
                                                }
                                            }

                                            StyledText {
                                                visible: !evBlock.isCompact
                                                text: evBlock.timeStr
                                                font.pixelSize: Appearance.font.pixelSize.smallest
                                                color: blockDelegate.ev.focus ? Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onTertiaryContainer, 0.75) : Appearance.colors.colSubtext
                                                elide: Text.ElideRight
                                                anchors {
                                                    top: evTitle.bottom
                                                    topMargin: 1 * Appearance.effectiveScale
                                                    left: parent.left
                                                    right: parent.right
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: ctrl.openEditorEdit(blockDelegate.ev.id)
                                        }
                                    }

                                    // ── Reminder block ──
                                    Rectangle {
                                        id: remBlock
                                        visible: parent.isRem
                                        radius: Appearance.rounding.small
                                        color: Appearance.m3colors.m3secondaryContainer
                                        clip: true

                                        anchors {
                                            fill: parent
                                            topMargin: 1 * Appearance.effectiveScale
                                            bottomMargin: 3 * Appearance.effectiveScale
                                            leftMargin: 0
                                            rightMargin: 1 * Appearance.effectiveScale
                                        }

                                        property bool isCompact: height <= (ctrl.hourHeight * 1.05)
                                        property string timeStr: ctrl._displayTime(blockDelegate.rem.time) || ""

                                        Item {
                                            anchors {
                                                fill: parent
                                                topMargin: remBlock.isCompact ? 0 : (6 * Appearance.effectiveScale)
                                                leftMargin: 6 * Appearance.effectiveScale
                                                rightMargin: 6 * Appearance.effectiveScale
                                            }

                                            // Compact: icon + text + · + time inline
                                            RowLayout {
                                                visible: remBlock.isCompact
                                                anchors {
                                                    verticalCenter: parent.verticalCenter
                                                    left: parent.left
                                                }
                                                width: Math.min(implicitWidth, parent.width)
                                                spacing: 4 * Appearance.effectiveScale

                                                MaterialSymbol {
                                                    text: {
                                                        if (blockDelegate.rem.type === "notepad") return "edit_note";
                                                        if (blockDelegate.rem.type === "todo") return "check_box";
                                                        return "alarm";
                                                    }
                                                    iconSize: 12 * Appearance.effectiveScale
                                                    color: Appearance.m3colors.m3onSecondaryContainer
                                                    Layout.alignment: Qt.AlignVCenter
                                                }

                                                StyledText {
                                                    text: blockDelegate.rem.text
                                                    font.pixelSize: Appearance.font.pixelSize.small
                                                    font.weight: Font.Medium
                                                    color: Appearance.m3colors.m3onSecondaryContainer
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }

                                                StyledText {
                                                    visible: remBlock.timeStr !== ""
                                                    text: "\u00b7"
                                                    font.pixelSize: Appearance.font.pixelSize.small
                                                    font.weight: Font.Medium
                                                    color: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSecondaryContainer, 0.75)
                                                    Layout.alignment: Qt.AlignVCenter
                                                }

                                                StyledText {
                                                    visible: remBlock.timeStr !== ""
                                                    text: remBlock.timeStr
                                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                                    color: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSecondaryContainer, 0.75)
                                                    Layout.alignment: Qt.AlignVCenter
                                                }
                                            }

                                            // Expanded: icon+text pinned top, time below
                                            RowLayout {
                                                id: remTitleRow
                                                visible: !remBlock.isCompact
                                                spacing: 4 * Appearance.effectiveScale
                                                anchors {
                                                    top: parent.top
                                                    left: parent.left
                                                    right: parent.right
                                                }

                                                MaterialSymbol {
                                                    text: {
                                                        if (blockDelegate.rem.type === "notepad") return "edit_note";
                                                        if (blockDelegate.rem.type === "todo") return "check_box";
                                                        return "alarm";
                                                    }
                                                    iconSize: 14 * Appearance.effectiveScale
                                                    color: Appearance.m3colors.m3onSecondaryContainer
                                                    Layout.alignment: Qt.AlignVCenter
                                                }

                                                StyledText {
                                                    text: blockDelegate.rem.text
                                                    font.pixelSize: Appearance.font.pixelSize.small
                                                    font.weight: Font.Medium
                                                    color: Appearance.m3colors.m3onSecondaryContainer
                                                    wrapMode: Text.Wrap
                                                    maximumLineCount: 2
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            StyledText {
                                                id: remTimeText
                                                visible: !remBlock.isCompact
                                                text: remBlock.timeStr
                                                font.pixelSize: Appearance.font.pixelSize.smallest
                                                color: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSecondaryContainer, 0.75)
                                                elide: Text.ElideRight
                                                anchors {
                                                    top: remTitleRow.bottom
                                                    topMargin: 1 * Appearance.effectiveScale
                                                    left: parent.left
                                                    right: parent.right
                                                }
                                            }

                                            // Linked item subtitle (expanded only, notepad/todo)
                                            StyledText {
                                                visible: !remBlock.isCompact && !!blockDelegate.rem.linkedTitle
                                                text: blockDelegate.rem.linkedTitle || ""
                                                font.pixelSize: Appearance.font.pixelSize.smallest
                                                font.italic: true
                                                color: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSecondaryContainer, 0.6)
                                                elide: Text.ElideRight
                                                anchors {
                                                    top: remTimeText.bottom
                                                    topMargin: 1 * Appearance.effectiveScale
                                                    left: parent.left
                                                    right: parent.right
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: ctrl.openReminderEditorEdit(blockDelegate.rem.id)
                                        }
                                    }
                                }
                            }
                        }

                        // Current time indicator (today only)
                        Item {
                            visible: ctrl.dayOffset === 0
                            x: 0
                            y: ctrl.nowFrac * ctrl.timelineContentHeight - 1 * Appearance.effectiveScale
                            width: parent.width
                            height: 2 * Appearance.effectiveScale

                            Rectangle {
                                x: ctrl.gutterWidth + 5 * Appearance.effectiveScale
                                y: 0
                                width: parent.width - x
                                height: parent.height
                                radius: 1 * Appearance.effectiveScale
                                color: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.85)
                            }

                            Rectangle {
                                width: 10 * Appearance.effectiveScale
                                height: 10 * Appearance.effectiveScale
                                radius: 5 * Appearance.effectiveScale
                                color: Appearance.m3colors.m3onSurface
                                x: ctrl.gutterWidth - 5 * Appearance.effectiveScale
                                y: -4 * Appearance.effectiveScale
                            }
                        }

                    }

                    ScrollBar.vertical: StyledScrollBar {
                    }

                }

                // ── Empty state overlay ──
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8 * Appearance.effectiveScale
                    visible: ctrl.dayEvents.length === 0 && ctrl.dayReminders.length === 0
                    opacity: visible ? 1 : 0

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        text: "event_busy"
                        iconSize: 40 * Appearance.effectiveScale
                        color: Appearance.colors.colSubtext
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: ctrl.dayOffset === 0 ? I18nService.tr("No schedule for today") : I18nService.tr("No schedule for this day")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.m3colors.m3onSurface
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: I18nService.tr("Tap + to add an event")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }

                    }

                }

            }

        }

        // ── Speed Dial FAB ──
        FloatingActionButton {
            anchors.fill: parent
            tooltipText: I18nService.tr("Add")
            tooltipOpenText: I18nService.tr("Close")
            actions: [
                {
                    icon: "event",
                    label: I18nService.tr("New Event"),
                    callback: () => ctrl.openEditorNew()
                },
                {
                    icon: "alarm",
                    label: I18nService.tr("Reminder"),
                    callback: () => ctrl.openReminderEditorNew()
                }
            ]
        }


    }
}

import QtQuick
import QtQuick.Layouts
import "../../../core"
import "../../../services"
import "../../../widgets"

Item {
    id: root
    required property Item di
    anchors.fill: parent

    readonly property string timeText: TimerService.timeString
    readonly property bool isRunning: TimerService.active
    readonly property bool isOverdue: TimerService.isNegative ?? false
    readonly property string subText: isOverdue ? I18nService.tr("Overtime") : (isRunning ? I18nService.tr("Timer") : I18nService.tr("Paused"))
    readonly property bool showExtra: di.timerControlsExpanded

    Item {
        id: content
        anchors.fill: parent
        // NOTE: plain clip, no layer/OpacityMask — rasterizing the row into
        // a layer makes text blurry and stalls expansion while the pill
        // width animates (same fix as PcDiIdle).
        clip: true

        Item {
            id: iconBox
            width: di.isMaterial ? di.pillHeight : di.pillHeight - 8
            height: di.isMaterial ? di.pillHeight : di.pillHeight - 8
            anchors {
                left: parent.left
                leftMargin: di.isMaterial ? 0 : 4
                verticalCenter: parent.verticalCenter
            }

            MaterialShapeWrappedMaterialSymbol {
                anchors.centerIn: parent
                shape: MaterialShape.Shape.Cookie12Sided
                color: root.isOverdue ? Appearance.m3colors.m3error : Appearance.colors.colPrimary
                colSymbol: root.isOverdue ? Appearance.m3colors.m3onError : Appearance.colors.colOnPrimary
                text: "hourglass_top"
                iconSize: di.isMaterial ? 20 : 14
                fill: 1
                padding: 4

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { GlobalStates.dashClockTab = 2; GlobalStates.dashboardOpen = true }
                }
            }
        }

        // Hidden metrics — locked to the maximum so the pill never shakes
        // as the digit count changes ("5" -> "10" -> "1:00")
        StyledText {
            id: timeMetrics
            visible: false
            text: root.timeText
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.DemiBold
            font.family: Appearance.font.family.numbers
        }
        TextMetrics {
            id: maxTimeMetrics
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.DemiBold
            font.family: Appearance.font.family.numbers
            text: "00:00:00"
        }
        StyledText {
            id: subMetrics
            visible: false
            text: root.subText
            font.pixelSize: Appearance.font.pixelSize.smallest
        }

        ColumnLayout {
            id: infoColumn
            anchors {
                left: iconBox.right
                leftMargin: 8
                verticalCenter: parent.verticalCenter
                right: controlsRow.left
                rightMargin: 8
            }
            spacing: di.isMaterial ? -2 : -4

            StyledText {
                Layout.fillWidth: true
                text: root.timeText
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.DemiBold
                font.family: Appearance.font.family.numbers
                font.features: { "tnum": 1 }
                color: root.isOverdue ? Appearance.m3colors.m3error : Appearance.colors.colNotchText
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                maximumLineCount: 1
            }
            StyledText {
                Layout.fillWidth: true
                text: root.subText
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colNotchText
                opacity: 0.7
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                maximumLineCount: 1
            }

            readonly property real widestLineWidth: Math.max(maxTimeMetrics.advanceWidth, subMetrics.implicitWidth)
            readonly property real computedContentWidth: iconBox.width
                + (di.isMaterial ? 8 : 12)
                + infoColumn.widestLineWidth
                + 12
                + controlsRow.implicitWidth
                + (di.isMaterial ? 0 : 4)
                + 10

            onComputedContentWidthChanged: di.countdownTextContentWidth = infoColumn.computedContentWidth
            Component.onCompleted: di.countdownTextContentWidth = infoColumn.computedContentWidth
        }

        RowLayout {
            id: controlsRow
            anchors {
                right: parent.right
                rightMargin: di.isMaterial ? 4 : 8
                verticalCenter: parent.verticalCenter
            }
            spacing: di.isMaterial ? -2 : -4

            // Play stays put on the left, extras (+1m, stop) expand to the right
            Item {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 22
                implicitHeight: 22
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: root.isRunning ? "pause" : "play_arrow"
                    fill: 1
                    iconSize: di.isMaterial ? 20 : 16
                    color: Appearance.colors.colNotchText
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.isRunning ? TimerService.pause() : TimerService.start()
                }
            }

            // Pill-matched slot (same pattern as pomodoro): width follows the
            // pill's 350ms expressive curve so buttons never drift, and the slot
            // stays in the layout at width 0 so there is no spacing jump.
            Item {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: root.showExtra ? 20 : 0
                implicitHeight: 20
                clip: true
                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
                    }
                }
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "add"
                    iconSize: di.isMaterial ? 18 : 14
                    color: Appearance.colors.colNotchText
                    opacity: parent.width > 10 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: root.showExtra
                    cursorShape: Qt.PointingHandCursor
                    onClicked: TimerService.addMinute()
                }
            }

            // Pill-matched slot (same pattern as pomodoro).
            Item {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: root.showExtra ? 22 : 0
                implicitHeight: 22
                clip: true
                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
                    }
                }
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "stop_circle"
                    fill: 1
                    iconSize: di.isMaterial ? 20 : 16
                    color: Appearance.colors.colNotchText
                    opacity: parent.width > 11 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: root.showExtra
                    cursorShape: Qt.PointingHandCursor
                    onClicked: TimerService.reset()
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import "../../../core"
import "../../../services"
import "../../../widgets"

Item {
    id: root
    required property Item di
    anchors.fill: parent

    readonly property string timeText: PomodoroService.timeString
    readonly property bool isRunning: PomodoroService.active
    readonly property string modeText: PomodoroService.modeName ?? "Focus"
    readonly property string subText: (isRunning ? modeText : modeText + " • " + I18nService.tr("Paused"))
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
                color: Appearance.colors.colPrimary
                colSymbol: Appearance.colors.colOnPrimary
                text: "coffee"
                iconSize: di.isMaterial ? 20 : 14
                fill: 1
                padding: 4

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { GlobalStates.dashClockTab = 0; GlobalStates.dashboardOpen = true }
                }
            }
        }

        StyledText {
            id: timeMetrics
            visible: false
            text: root.timeText
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.DemiBold
            font.family: Appearance.font.family.numbers
        }
        // Lock digit width to the maximum so the pill never shakes on minute rollover ("10:00" -> "9:59")
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
                color: Appearance.colors.colNotchText
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

            onComputedContentWidthChanged: di.reportWidth("pomodoroTextContentWidth", infoColumn.computedContentWidth)
            Component.onCompleted: di.reportWidth("pomodoroTextContentWidth", infoColumn.computedContentWidth)
        }

        RowLayout {
            id: controlsRow
            anchors {
                right: parent.right
                rightMargin: di.isMaterial ? 4 : 8
                verticalCenter: parent.verticalCenter
            }
            // Gaps live inside the fixed-width slots, not the layout, so
            // zero-width slots can't shift play via spacing recount.
            spacing: 0

            Item {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: di.isMaterial ? 20 : 18
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
                    onClicked: root.isRunning ? PomodoroService.pause() : PomodoroService.start()
                }
            }

            // Custom hover slot instead of Revealer: a stock Revealer animates
            // with a different curve (400ms emphasizedDecel, no overshoot) than
            // the pill (350ms expressiveDefaultSpatial WITH overshoot), so the
            // row and the pill fall out of sync at the tail of the animation
            // and the play button visibly shifts. This slot uses the exact same
            // curve as the pill, so the row tracks the pill frame-by-frame.
            // A plain Item also stays in the layout at width 0 (no spacing
            // recount), so there is no discrete jump either.
            Item {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: root.showExtra ? (di.isMaterial ? 20 : 18) : 0
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
                    onClicked: PomodoroService.reset()
                }
            }
        }
    }
}

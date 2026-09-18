pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../core"
import "../../services"

Item {
    id: root

    property string style: "bars" // "bars" | "mirror" | "aurora" | "dots" | "wave" (legacy)
    property real sensitivity: 1
    property int bandHeight: 260
    property string colorSource: "theme" // "theme" | "cover"
    property bool isLockscreen: false

    // Legacy wave props (also used as fallback)
    property color baseColor: isLockscreen ? Appearance.lockM3colors.m3primary : Appearance.m3colors.m3primary
    property real opacityMultiplier: 0.15
    property int smoothing: 2
    property real maxVisualizerValue: 1000

    readonly property bool shaderStyle: ["aurora", "dots", "mirror"].includes(style)
    readonly property bool useCoverColors: root.shaderStyle && root.colorSource === "cover"
    readonly property var theme: root.isLockscreen ? Appearance.lockM3colors : Appearance.m3colors

    // Palettes: color1 and color2 carry the shape, color3 the accent
    readonly property var themePalette: {
        const c = root.theme;
        switch (root.style) {
        case "aurora": return [c.m3primary, c.m3tertiary, c.m3secondary];
        case "dots": return [c.m3onBackground, c.m3primary, c.m3error];
        default: return [c.m3primary, c.m3primaryContainer, c.m3tertiary];
        }
    }
    readonly property var coverPalette: {
        const colors = Array.from(coverQuantizer.colors).sort((a, b) => b.hslSaturation - a.hslSaturation);
        if (colors.length < 3) return null;
        const lifted = colors.map(c => Qt.hsla(Math.max(c.hslHue, 0), Math.max(c.hslSaturation, 0.45), Math.min(Math.max(c.hslLightness, 0.62), 0.85), 1));
        return root.style === "dots" ? [root.themePalette[0], lifted[0], lifted[1]] : lifted.slice(0, 3);
    }
    readonly property var visualizerColors: (root.useCoverColors && root.coverPalette) ? root.coverPalette : root.themePalette

    ColorQuantizer {
        id: coverQuantizer
        source: root.useCoverColors ? MprisController.artPathForQuantizer : ""
        depth: 2
        rescaleSize: 64
    }

    VisualizerEngine {
        id: levelEngine
        active: root.shaderStyle && root.visible
        sensitivity: root.sensitivity
    }

    Loader {
        anchors.fill: parent
        active: root.visible && root.style === "bars"
        sourceComponent: BarsVisualizer {}
    }

    Loader {
        anchors.fill: parent
        active: root.visible && root.shaderStyle
        sourceComponent: VisualizerShader {
            style: root.style
            engine: levelEngine
            color1: root.visualizerColors[0]
            color2: root.visualizerColors[1]
            color3: root.visualizerColors[2]
        }
    }

    Loader {
        anchors.fill: parent
        active: root.visible && root.style === "wave"
        sourceComponent: WaveView {
            anchors.fill: parent
            color: root.baseColor
            alpha: root.opacityMultiplier
            smoothing: root.smoothing
            maxValue: root.maxVisualizerValue
        }
    }

    component BarsVisualizer: Item {
        id: bars

        readonly property list<real> points: GlobalStates.visualizerPoints

        property real barWidth: 4
        property real barSpacing: 8
        property real maxBarHeight: 220
        property real maxVisualizerValue: 1000
        property real smoothingDuration: 150

        readonly property int barCount: Math.max(1, Math.floor(width / (barWidth + barSpacing)))

        readonly property var smoothedPoints: {
            let raw = points;
            if (!raw || raw.length === 0) return Array(barCount).fill(0);
            let count = barCount;
            let mapped = new Array(count);
            let rawLenM1 = raw.length - 1;

            for (let i = 0; i < count; i++) {
                let progress = i / (count - 1 || 1);
                let relPos = progress * rawLenM1;
                let low = Math.floor(relPos);
                let high = Math.ceil(relPos);
                let mix = relPos - low;
                mapped[i] = (raw[low] * (1 - mix)) + (raw[high] * (high < raw.length ? mix : 0));
            }

            let smoothed = new Array(count);
            let sW = 0.2;
            for (let j = 0; j < count; j++) {
                let p = mapped[Math.max(0, j - 1)];
                let n = mapped[Math.min(count - 1, j + 1)];
                smoothed[j] = (p * sW) + (mapped[j] * (1.0 - 2 * sW)) + (n * sW);
            }
            return smoothed;
        }

        property real activityOpacity: 0
        Behavior on activityOpacity {
            NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
        }

        Timer {
            id: silenceTimer
            interval: 1000
            onTriggered: bars.activityOpacity = 0
        }

        onPointsChanged: {
            if (points.some(p => p > 0)) {
                bars.activityOpacity = 1.0;
                silenceTimer.restart();
            }
        }

        Row {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: bars.barSpacing
            opacity: Math.min(1, bars.activityOpacity * (0.5 + root.opacityMultiplier * 2))

            Behavior on opacity {
                NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
            }

            Repeater {
                model: bars.barCount
                Rectangle {
                    required property int index
                    width: bars.barWidth
                    property real pointValue: {
                        const v = bars.smoothedPoints[index] ?? 0;
                        return Math.max(bars.barWidth, (v / bars.maxVisualizerValue) * Math.min(bars.maxBarHeight, bars.height));
                    }
                    height: pointValue
                    topLeftRadius: bars.barWidth / 2
                    topRightRadius: bars.barWidth / 2
                    anchors.bottom: parent.bottom

                    property real intensity: pointValue / Math.min(bars.maxBarHeight, bars.height)
                    color: Qt.rgba(
                        root.themePalette[0].r * intensity + root.themePalette[1].r * (1 - intensity),
                        root.themePalette[0].g * intensity + root.themePalette[1].g * (1 - intensity),
                        root.themePalette[0].b * intensity + root.themePalette[1].b * (1 - intensity),
                        1
                    )

                    Behavior on height {
                        NumberAnimation { duration: bars.smoothingDuration; easing.type: Easing.OutQuad }
                    }
                }
            }
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects
import "../"
import "../../core"
import "../../services"

/**
 * Pixel-style die-cut digits clock.
 *
 * Faithful port of end4-pC's PixelClock (Text + OpacityMask punch layers with
 * a 16-point circle fringe ring, fractional geometry). Deliberately kept
 * 1:1 with upstream's rendering path — no extra layer tweaks — so the output
 * matches the battle-tested ii/end4 look. Only the integration shell is
 * nandoroid's: config entry, M3 colors, 12H/24H digits, lockscreen palette.
 */
Item {
    id: root

    property bool isLockscreen: false

    readonly property var cfg: {
        if (Config.ready && isLockscreen && !Config.options.appearance.clock.useSameStyle)
            return Config.options.appearance.clock.pixelLocked;
        return Config.options.appearance.clock.pixel;
    }

    readonly property bool isVertical: (Config.ready && root.cfg) ? (root.cfg.isVertical ?? true) : true
    readonly property real contentScale: ((Config.ready && root.cfg) ? Math.max(50, root.cfg.size || 100) : 100) / 100 * Appearance.effectiveScale

    implicitWidth: (root.isVertical ? 276 : 420) * root.contentScale
    implicitHeight: (root.isVertical ? 252 : 150) * root.contentScale
    width: implicitWidth
    height: implicitHeight

    readonly property var m3: isLockscreen ? Appearance.lockM3colors : Appearance.m3colors
    readonly property color tintSoft: m3.m3primaryContainer
    readonly property color tintBold: m3.m3primary

    // Digits honor the global 12H/24H preference
    readonly property int displayHour: {
        const is24 = Config.ready && Config.options.time ? Config.options.time.timeStyle === "24H" : true;
        return is24 ? DateTime.hours : (DateTime.hours % 12 || 12);
    }
    readonly property string hh: displayHour.toString().padStart(2, "0")
    readonly property string mm: DateTime.minutes.toString().padStart(2, "0")
    readonly property string glyph0: hh.charAt(0)
    readonly property string glyph1: hh.charAt(1)
    readonly property string glyph2: mm.charAt(0)
    readonly property string glyph3: mm.charAt(1)

    // Geometry as fractions of the widget size — identical to upstream
    // Vertical: 2x2 grid, no colon. Horizontal: single row + colon.
    readonly property real fringeSize: root.isVertical ? root.width * 0.026 : root.height * 0.03
    readonly property real tileW: root.isVertical ? root.width * 0.66 : root.width * 0.30
    readonly property real tileH: root.isVertical ? root.height * 0.66 : root.height * 0.90
    readonly property real glyphSize: root.isVertical ? root.height * 0.66 : root.height * 0.85

    // Horizontal row spans 4 tiles + colon gap = 0.90W, so start at 0.05W
    // to center the content inside the item's bounding box (the lockscreen
    // centers the whole item via NandoClock).
    readonly property real pos0X: root.isVertical ? root.width * 0.00 : root.width * 0.05
    readonly property real pos1X: root.isVertical ? root.width * 0.30 : root.width * 0.20
    readonly property real pos2X: root.isVertical ? root.width * 0.00 : root.width * 0.51
    readonly property real pos3X: root.isVertical ? root.width * 0.30 : root.width * 0.65

    readonly property real pos0Y: root.isVertical ? root.height * -0.04 : root.height * 0.05
    readonly property real pos1Y: root.isVertical ? root.height * -0.04 : root.height * 0.05
    readonly property real pos2Y: root.isVertical ? root.height * 0.42 : root.height * 0.05
    readonly property real pos3Y: root.isVertical ? root.height * 0.42 : root.height * 0.05

    readonly property real colonX: root.pos1X + root.tileW + (root.pos2X - (root.pos1X + root.tileW)) / 2 - root.width * 0.03
    readonly property real colonDotSize: root.height * 0.2
    readonly property real colonGap: root.height * 0.04

    function ringSamples(count, radius) {
        let pts = [{ dx: 0, dy: 0 }]
        for (let i = 0; i < count; i++) {
            const a = (i / count) * Math.PI * 2
            pts.push({ dx: Math.cos(a) * radius, dy: Math.sin(a) * radius })
        }
        return pts
    }
    readonly property var fringeSamples: root.ringSamples(16, root.fringeSize)

    component GlyphTile: Text {
        width: root.tileW
        height: root.tileH
        font {
            family: "Google Sans Flex"
            weight: 1000
            bold: true
            pixelSize: root.glyphSize
            variableAxes: ({ "wght": 1000 })
        }
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    // Layer 0: glyph0 (soft) cut by glyph1, glyph2, glyph3
    Item {
        id: tileAFace
        anchors.fill: parent
        visible: false
        GlyphTile {
            x: root.pos0X
            y: root.pos0Y
            text: root.glyph0
            color: root.tintSoft
        }
    }
    Item {
        id: tileAPunch
        anchors.fill: parent
        visible: false
        Repeater {
            model: root.fringeSamples
            Item {
                id: punchA
                required property var modelData
                anchors.fill: parent
                GlyphTile { x: root.pos1X + punchA.modelData.dx; y: root.pos1Y + punchA.modelData.dy; text: root.glyph1; color: "black" }
                GlyphTile { x: root.pos2X + punchA.modelData.dx; y: root.pos2Y + punchA.modelData.dy; text: root.glyph2; color: "black" }
                GlyphTile { x: root.pos3X + punchA.modelData.dx; y: root.pos3Y + punchA.modelData.dy; text: root.glyph3; color: "black" }
            }
        }
    }
    OpacityMask {
        anchors.fill: parent
        source: tileAFace
        maskSource: tileAPunch
        invert: true
        z: 0
    }

    // Layer 1: glyph1 (bold) cut by glyph2, glyph3
    Item {
        id: tileBFace
        anchors.fill: parent
        visible: false
        GlyphTile {
            x: root.pos1X
            y: root.pos1Y
            text: root.glyph1
            color: root.tintBold
        }
    }
    Item {
        id: tileBPunch
        anchors.fill: parent
        visible: false
        Repeater {
            model: root.fringeSamples
            Item {
                id: punchB
                required property var modelData
                anchors.fill: parent
                GlyphTile { x: root.pos2X + punchB.modelData.dx; y: root.pos2Y + punchB.modelData.dy; text: root.glyph2; color: "black" }
                GlyphTile { x: root.pos3X + punchB.modelData.dx; y: root.pos3Y + punchB.modelData.dy; text: root.glyph3; color: "black" }
            }
        }
    }
    OpacityMask {
        anchors.fill: parent
        source: tileBFace
        maskSource: tileBPunch
        invert: true
        z: 1
    }

    // Layer 2: glyph2 (bold) cut by glyph3
    Item {
        id: tileCFace
        anchors.fill: parent
        visible: false
        GlyphTile {
            x: root.pos2X
            y: root.pos2Y
            text: root.glyph2
            color: root.tintBold
        }
    }
    Item {
        id: tileCPunch
        anchors.fill: parent
        visible: false
        Repeater {
            model: root.fringeSamples
            Item {
                id: punchC
                required property var modelData
                anchors.fill: parent
                GlyphTile { x: root.pos3X + punchC.modelData.dx; y: root.pos3Y + punchC.modelData.dy; text: root.glyph3; color: "black" }
            }
        }
    }
    OpacityMask {
        anchors.fill: parent
        source: tileCFace
        maskSource: tileCPunch
        invert: true
        z: 2
    }

    // Layer 3: glyph3 (soft) intact
    GlyphTile {
        x: root.pos3X
        y: root.pos3Y
        text: root.glyph3
        color: root.tintSoft
        z: 3
    }

    // Colon separator (horizontal mode only)
    Column {
        visible: !root.isVertical
        x: root.colonX
        y: root.pos0Y + root.tileH / 2 - height / 2
        spacing: root.colonGap
        z: 4

        Rectangle {
            width: root.colonDotSize
            height: root.colonDotSize
            radius: width / 2
            color: root.tintBold
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Rectangle {
            width: root.colonDotSize
            height: root.colonDotSize
            radius: width / 2
            color: root.tintBold
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}

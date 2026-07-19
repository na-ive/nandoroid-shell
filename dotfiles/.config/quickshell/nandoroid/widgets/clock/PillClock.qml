import QtQuick
import QtQuick.Layouts
import ".."
import "../../core"
import "../../services"

/**
 * PillClock.qml
 * Android 12 inspired pill clock. 
 * DEFINITIVE FIX: Background properly resizes with text. Dynamic Pill Color.
 */
Rectangle {
    id: root
    
    property bool isLockscreen: false
    property string alignment: "center"

    readonly property string timeFontFamily: root.isLockscreen ? Appearance.font.family.lockscreenTimeFont : Appearance.font.family.desktopTimeFont
    readonly property string dateFontFamily: root.isLockscreen ? Appearance.font.family.lockscreenDateFont : Appearance.font.family.desktopDateFont
    readonly property bool showDate: Config.ready ? (root.isLockscreen ? (Config.options.appearance.clock.useSameStyle ? Config.options.appearance.clock.showDesktopDate : Config.options.appearance.clock.showLockscreenDate) : Config.options.appearance.clock.showDesktopDate) : true
    
    readonly property var cfg: {
        if (!Config.ready) return { size: 120, isVertical: false, showBackground: true, timeColorStyle: "onLayer0", dateColorStyle: "primary", pillColorStyle: "surfaceContainerHigh" }
        return isLockscreen && !Config.options.appearance.clock.useSameStyle 
            ? (Config.options.appearance.clock.pillLocked || { size: 120, isVertical: false, showBackground: true })
            : (Config.options.appearance.clock.pill || { size: 120, isVertical: false, showBackground: true })
    }

    // Switch between lock and desktop color palettes
    readonly property var m3: isLockscreen ? Appearance.lockM3colors : Appearance.m3colors

    readonly property color timeColor: {
        if (!Config.ready || !cfg) return m3.m3onSurface
        const s = cfg.timeColorStyle
        if (s === "primary") return m3.m3primary
        if (s === "secondary") return m3.m3secondary
        if (s === "tertiary") return m3.m3tertiary
        if (s === "error") return m3.m3error
        if (s === "onSurface") return m3.m3onSurface
        if (s === "surface") return m3.m3surface
        if (s === "onLayer0") return m3.m3background
        return m3.m3onSurface
    }

    readonly property color dateColor: {
        if (!Config.ready || !cfg) return m3.m3primary
        const s = cfg.dateColorStyle
        if (s === "primary") return m3.m3primary
        if (s === "secondary") return m3.m3secondary
        if (s === "tertiary") return m3.m3tertiary
        if (s === "error") return m3.m3error
        if (s === "onSurface") return m3.m3onSurface
        if (s === "surface") return m3.m3surface
        if (s === "onLayer0") return m3.m3background
        return m3.m3primary
    }

    readonly property color pillColor: {
        if (!Config.ready || !cfg) return m3.m3surfaceContainerHigh
        const s = cfg.pillColorStyle
        if (s === "primaryContainer") return m3.m3primaryContainer
        if (s === "secondaryContainer") return m3.m3secondaryContainer
        if (s === "surfaceContainerHigh") return m3.m3surfaceContainerHigh
        if (s === "surfaceContainerLowest") return Qt.rgba(0,0,0, 0.25) // TRUE GLASS EFFECT
        return m3.m3surfaceContainerHigh
    }

    // Radius: 64px
    radius: root.cfg.isVertical ? 64 * Appearance.effectiveScale : (root.cfg.showBackground ? 64 * Appearance.effectiveScale : height / 2)
    
    color: root.cfg.showBackground ? root.pillColor : "transparent"
    border.width: root.cfg.showBackground ? 1 * Appearance.effectiveScale : 0
    border.color: Appearance.m3colors.m3outlineVariant

    implicitWidth: root.cfg.isVertical ? (colLayout.implicitWidth + 80 * Appearance.effectiveScale) : (rowMainLayout.implicitWidth + 100 * Appearance.effectiveScale)
    implicitHeight: root.cfg.isVertical ? (colLayout.implicitHeight + 80 * Appearance.effectiveScale) : (rowMainLayout.implicitHeight + 64 * Appearance.effectiveScale)

    // --- Sub-component: Adaptive Pill ---
    component AdaptivePill : Rectangle {
        property string labelText: ""
        property bool isBold: false
        property real fontSize: (root.cfg.size * 0.15 || 18) * Appearance.effectiveScale
        
        visible: labelText !== ""
        
        implicitWidth: labelItem.implicitWidth + (32 * Appearance.effectiveScale)
        implicitHeight: labelItem.implicitHeight + (12 * Appearance.effectiveScale)
        radius: height / 2
        
        color: !root.cfg.showBackground ? root.pillColor : "transparent"
        border.width: !root.cfg.showBackground ? 1 * Appearance.effectiveScale : 0
        border.color: Appearance.m3colors.m3outlineVariant
        
        StyledText {
            id: labelItem
            anchors.centerIn: parent
            text: parent.labelText
            font.pixelSize: Math.round(parent.fontSize)
            font.weight: parent.isBold ? Font.DemiBold : Font.Medium
            font.family: root.dateFontFamily
            color: root.dateColor
        }
    }

    // --- Horizontal Layout ---
    ColumnLayout {
        id: rowMainLayout
        visible: !root.cfg.isVertical
        anchors.centerIn: parent
        spacing: 12 * Appearance.effectiveScale

        RowLayout {
            spacing: 20 * Appearance.effectiveScale
            Layout.alignment: Qt.AlignHCenter

            StyledText {
                text: DateTime.hours.toString().padStart(2, '0')
                font.pixelSize: Math.round((root.cfg.size * 0.5 || 60) * Appearance.effectiveScale)
                font.weight: Font.DemiBold
                font.family: root.timeFontFamily
                color: root.timeColor
            }

            Rectangle {
                width: 16 * Appearance.effectiveScale
                height: 16 * Appearance.effectiveScale
                radius: 8 * Appearance.effectiveScale
                color: root.dateColor
                Layout.alignment: Qt.AlignVCenter
            }

            StyledText {
                text: DateTime.minutes.toString().padStart(2, '0')
                font.pixelSize: Math.round((root.cfg.size * 0.5 || 60) * Appearance.effectiveScale)
                font.weight: Font.DemiBold
                font.family: root.timeFontFamily
                color: root.timeColor
                opacity: 0.8
            }
        }

        // Horizontal Date
        ColumnLayout {
            spacing: 0
            Layout.alignment: Qt.AlignHCenter
            visible: root.showDate && root.cfg.showBackground

            StyledText {
                text: Qt.formatDate(new Date(), "dddd")
                font.pixelSize: Math.round((root.cfg.size * 0.18 || 22) * Appearance.effectiveScale)
                font.weight: Font.DemiBold
                font.family: root.dateFontFamily
                color: root.timeColor
                Layout.alignment: Qt.AlignHCenter
            }
            StyledText {
                text: Qt.formatDate(new Date(), "d MMMM, yyyy")
                font.pixelSize: Math.round((root.cfg.size * 0.12 || 14) * Appearance.effectiveScale)
                font.weight: Font.Light
                font.family: root.dateFontFamily
                color: root.dateColor
                opacity: 0.6
                Layout.alignment: Qt.AlignHCenter
            }
        }

        // Horizontal Pill Date (When background is OFF)
        AdaptivePill {
            Layout.alignment: Qt.AlignHCenter
            visible: root.showDate && !root.cfg.showBackground
            labelText: Qt.formatDate(new Date(), "dddd, d MMMM yyyy")
            isBold: true
            fontSize: (root.cfg.size * 0.14 || 16) * Appearance.effectiveScale
        }
    }

    // --- Vertical Layout ---
    ColumnLayout {
        id: colLayout
        visible: root.cfg.isVertical
        anchors.centerIn: parent
        spacing: 16 * Appearance.effectiveScale

        StyledText {
            text: DateTime.hours.toString().padStart(2, '0')
            font.pixelSize: Math.round((root.cfg.size * 0.5 || 60) * Appearance.effectiveScale)
            font.weight: Font.DemiBold
            font.family: root.timeFontFamily
            color: root.timeColor
            Layout.alignment: Qt.AlignHCenter
        }

        Rectangle {
            width: 16 * Appearance.effectiveScale
            height: 16 * Appearance.effectiveScale
            radius: 8 * Appearance.effectiveScale
            color: root.dateColor
            Layout.alignment: Qt.AlignHCenter
        }

        StyledText {
            text: DateTime.minutes.toString().padStart(2, '0')
            font.pixelSize: Math.round((root.cfg.size * 0.5 || 60) * Appearance.effectiveScale)
            font.weight: Font.DemiBold
            font.family: root.timeFontFamily
            color: root.timeColor
            opacity: 0.8
            Layout.alignment: Qt.AlignHCenter
        }

        AdaptivePill {
            Layout.alignment: Qt.AlignHCenter
            labelText: {
                if (!DateTime.time12h) return "PM";
                const parts = DateTime.time12h.split(" ");
                return parts.length > 1 ? parts[1].toUpperCase() : "PM";
            }
            isBold: true
            opacity: root.cfg.showBackground ? 0.6 : 1.0
            fontSize: (root.cfg.size * 0.15 || 18) * Appearance.effectiveScale
        }
    }
}

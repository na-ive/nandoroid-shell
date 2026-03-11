import QtQuick
import QtQuick.Layouts
import "../core"
import "../services"

/**
 * Network Speed Meter widget for the status bar.
 * Displays real-time download (RX) and upload (TX) speeds in an extremely compact 2-row layout.
 */
ColumnLayout {
    id: root
    spacing: -6
    visible: Config.ready && Config.options.bar ? Config.options.bar.show_network_speed : false

    property color color: Appearance.colors.colStatusBarText
    property color subtextColor: Appearance.colors.colStatusBarSubtext

    readonly property string currentUnit: Config.ready && Config.options.bar ? Config.options.bar.network_speed_unit : "KB"

    function formatSpeed(bytes) {
        const k = 1024;
        const mt = 1024 * 1024;
        const gt = 1024 * 1024 * 1024;
        
        if (root.currentUnit === "MB") {
            return (bytes / mt).toFixed(1) + " MB/s";
        } else if (root.currentUnit === "KB") {
            if (bytes >= mt) return (bytes / mt).toFixed(1) + " MB/s";
            return (bytes / k).toFixed(1) + " KB/s";
        } else {
            if (bytes >= mt) return (bytes / mt).toFixed(1) + " MB/s";
            if (bytes >= k) return (bytes / k).toFixed(1) + " KB/s";
            return Math.floor(bytes) + " B/s";
        }
    }

    function isHighSpeed(bytes) {
        const k = 1024;
        const mt = 1024 * 1024;
        if (root.currentUnit === "MB") return bytes >= 0.1 * mt;
        return bytes >= k;
    }

    // TX (Upload) - Top Row
    RowLayout {
        spacing: 4
        Layout.alignment: Qt.AlignRight
        Layout.preferredHeight: 10
        StyledText {
            text: root.formatSpeed(SystemData.networkTxRate)
            font.pixelSize: 10
            font.weight: Font.Medium
            color: root.color
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignBottom
        }
        MaterialSymbol {
            text: "arrow_drop_up"
            iconSize: 14
            color: root.isHighSpeed(SystemData.networkTxRate) ? root.color : root.subtextColor
        }
    }

    // RX (Download) - Bottom Row
    RowLayout {
        spacing: 4
        Layout.alignment: Qt.AlignRight
        Layout.preferredHeight: 10
        StyledText {
            text: root.formatSpeed(SystemData.networkRxRate)
            font.pixelSize: 10
            font.weight: Font.Medium
            color: root.color
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignTop
        }
        MaterialSymbol {
            text: "arrow_drop_down"
            iconSize: 14
            color: root.isHighSpeed(SystemData.networkRxRate) ? root.color : root.subtextColor
        }
    }
}

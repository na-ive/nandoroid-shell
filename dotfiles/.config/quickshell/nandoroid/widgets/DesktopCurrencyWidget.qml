import "../core"
import "../services"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "."

Item {
    id: root
    
    property var cfg: Config.ready ? Config.options.appearance.currencyWidget : null
    property string sizeMode: cfg ? cfg.sizeMode : "2x1"
    property bool interactive: true

    HoverHandler {
        id: widgetHoverHandler
    }

    readonly property real baseWidth: 132 * Appearance.effectiveScale
    readonly property real baseHeight: 108 * Appearance.effectiveScale
    readonly property real gap: 12 * Appearance.effectiveScale

    readonly property real width1x1: baseWidth
    readonly property real width2x1: (baseWidth * 2) + gap

    implicitHeight: baseHeight
    implicitWidth: {
        if (sizeMode === "1x1") return width1x1;
        return width2x1;
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 250
            easing.bezierCurve: [0.2, 0, 0, 1]
        }
    }

    function getModeForWidth(targetWidth) {
        let mid = (width1x1 + width2x1) / 2;
        if (targetWidth < mid) return "1x1";
        return "2x1";
    }

    property bool showingSettings: false
    
    // Flip Card scale and animation
    transform: Scale {
        id: flipScale
        origin.x: root.width / 2
        origin.y: root.height / 2
        xScale: 1
    }

    SequentialAnimation {
        id: flipAnim
        NumberAnimation {
            target: flipScale; property: "xScale"
            to: 0; duration: 150; easing.type: Easing.InQuad
        }
        ScriptAction {
            script: root.showingSettings = !root.showingSettings
        }
        NumberAnimation {
            target: flipScale; property: "xScale"
            to: 1; duration: 150; easing.type: Easing.OutQuad
        }
    }

    function toggleFlip() { flipAnim.start() }

    // Main Card Rectangle (Colored using colPrimaryContainer)
    Rectangle {
        id: card
        anchors.fill: parent
        radius: 30 * Appearance.effectiveScale
        color: Appearance.colors.colPrimaryContainer

        // Mask content inside parent corners
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: card.width
                height: card.height
                radius: card.radius
            }
        }

        // --- PAGE 1: View Mode ---
        Item {
            anchors.fill: parent
            visible: !root.showingSettings

            // Settings button (appears on hover, hidden when locked)
            Item {
                width: 24 * Appearance.effectiveScale
                height: 24 * Appearance.effectiveScale
                z: 100
                visible: cfg ? !cfg.locked : true
                opacity: widgetHoverHandler.hovered ? 0.9 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 8 * Appearance.effectiveScale
                    rightMargin: 8 * Appearance.effectiveScale
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 12 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                    
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "settings"
                        iconSize: 14 * Appearance.effectiveScale
                        color: Appearance.colors.colOnPrimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleFlip()
                    }
                }
            }

            // ── [RADICAL M3 DESAIN 1x1: Original end4-pC Layout (Top-Right Icon, Left Bottom-Aligned Texts)] ──
            Item {
                visible: sizeMode === "1x1"
                anchors.fill: parent

                // Sisi Atas Kiri: Info teks mata uang dasar (e.g. "to IDR")
                ColumnLayout {
                    spacing: 0
                    anchors {
                        top: parent.top
                        left: parent.left
                        topMargin: 14 * Appearance.effectiveScale
                        leftMargin: 14 * Appearance.effectiveScale
                    }
                    StyledText {
                        text: "Rates"
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnPrimaryContainer
                        opacity: 0.6
                    }
                    StyledText {
                        text: "to " + CurrencyService.baseCurrency
                        font.pixelSize: 10 * Appearance.effectiveScale
                        font.weight: Font.Bold
                        color: Appearance.colors.colPrimary
                    }
                }

                // Sisi Atas Kanan: Material Shape Wrapped Symbol (Top Right)
                MaterialShape {
                    id: currencyIconShape
                    width: 34 * Appearance.effectiveScale
                    height: 34 * Appearance.effectiveScale
                    shape: MaterialShape.Shape.Bun
                    color: Appearance.colors.colPrimary
                    anchors {
                        top: parent.top
                        right: parent.right
                        topMargin: 14 * Appearance.effectiveScale
                        rightMargin: 14 * Appearance.effectiveScale
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "payments"
                        iconSize: 18 * Appearance.effectiveScale
                        color: Appearance.colors.colOnPrimary
                    }
                }

                // Sisi Bawah Kiri: 2 Stacked Rates (Bottom-Aligned Left)
                ColumnLayout {
                    spacing: -2 * Appearance.effectiveScale
                    anchors {
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                        bottomMargin: 14 * Appearance.effectiveScale
                        leftMargin: 14 * Appearance.effectiveScale
                        rightMargin: 14 * Appearance.effectiveScale
                    }
                    
                    // Quote 1 Row (USD)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4 * Appearance.effectiveScale

                        StyledText {
                            text: CurrencyService.quote1
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnPrimaryContainer
                            opacity: 0.6
                        }
                        
                        Item { Layout.fillWidth: true } // Spacer

                        StyledText {
                            text: {
                                let v = CurrencyService.rates[CurrencyService.quote1] || 0.0;
                                if (v > 0.0) return Math.round(v).toLocaleString(Qt.locale(), 'f', 0);
                                return CurrencyService.errorMessage || "...";
                            }
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                    }

                    // Quote 2 Row (EUR)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4 * Appearance.effectiveScale

                        StyledText {
                            text: CurrencyService.quote2
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnPrimaryContainer
                            opacity: 0.6
                        }
                        
                        Item { Layout.fillWidth: true } // Spacer

                        StyledText {
                            text: {
                                let v = CurrencyService.rates[CurrencyService.quote2] || 0.0;
                                if (v > 0.0) return Math.round(v).toLocaleString(Qt.locale(), 'f', 0);
                                return CurrencyService.errorMessage || "...";
                            }
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                    }
                }
            }

            // ── [RADICAL M3 DESAIN 2x1: Wavy Sparkline / Trading Card] ──
            Item {
                visible: sizeMode === "2x1"
                anchors.fill: parent

                // Wavy line di background untuk kesan trading chart live yang sangat premium
                Canvas {
                    id: sparklineCanvas
                    anchors.fill: parent
                    opacity: 0.35
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.clearRect(0, 0, width, height);

                        // Draw a smooth sparkline trend
                        ctx.strokeStyle = Appearance.colors.colOnPrimaryContainer;
                        ctx.lineWidth = 2 * Appearance.effectiveScale;
                        ctx.lineCap = "round";
                        ctx.beginPath();
                        
                        let points = [0.8, 0.6, 0.75, 0.4, 0.55, 0.3, 0.45, 0.2];
                        let step = width / (points.length - 1);
                        
                        ctx.moveTo(0, height * points[0]);
                        for (let i = 1; i < points.length; i++) {
                            let x = i * step;
                            let y = height * points[i];
                            // Curving coordinates
                            let prevX = (i - 1) * step;
                            let prevY = height * points[i - 1];
                            ctx.bezierCurveTo(prevX + step/2, prevY, x - step/2, y, x, y);
                        }
                        ctx.stroke();
                    }
                }

                // Sisi Kiri: Base currency label besar
                ColumnLayout {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 20 * Appearance.effectiveScale
                    }
                    spacing: -4 * Appearance.effectiveScale

                    StyledText {
                        text: "Rates"
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnPrimaryContainer
                        opacity: 0.8
                    }

                    StyledText {
                        text: CurrencyService.baseCurrency
                        font.pixelSize: Math.round(42 * Appearance.effectiveScale)
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnPrimaryContainer
                    }
                }

                // Area Kanan: Split Solid Panel dengan sudut KIRI membulat (Rounded Left Edge)
                Rectangle {
                    id: rightSplitPanel
                    width: 140 * Appearance.effectiveScale
                    radius: 30 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                    
                    anchors {
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                    }

                    // Grid data mata uang di dalam panel kanan (tanpa pemotongan k)
                    GridLayout {
                        anchors.fill: parent
                        anchors.margins: 14 * Appearance.effectiveScale
                        columns: 2
                        rowSpacing: 4 * Appearance.effectiveScale
                        columnSpacing: 10 * Appearance.effectiveScale

                        Repeater {
                            model: 4
                            delegate: ColumnLayout {
                                spacing: -4 * Appearance.effectiveScale

                                property string quoteCurrency: {
                                    if (index === 0) return CurrencyService.quote1;
                                    if (index === 1) return CurrencyService.quote2;
                                    if (index === 2) return CurrencyService.quote3;
                                    return CurrencyService.quote4;
                                }

                                property real rateVal: {
                                    let r = CurrencyService.rates[quoteCurrency];
                                    return r !== undefined ? r : 0.0;
                                }

                                StyledText {
                                    text: quoteCurrency
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    font.weight: Font.Bold
                                    color: Appearance.colors.colOnPrimary
                                }

                                StyledText {
                                    text: {
                                        if (CurrencyService.loading) return "...";
                                        if (rateVal === 0.0) return CurrencyService.errorMessage || "...";
                                        return rateVal.toLocaleString(Qt.locale(), 'f', rateVal < 1000 ? 2 : 0);
                                    }
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.weight: Font.Bold
                                    color: Appearance.colors.colOnPrimary
                                }
                            }
                        }
                    }
                }
            }
        }

        // --- PAGE 2: Flip Settings Mode (Zero Overflow / Scrollable Flickable) ---
        Flickable {
            anchors.fill: parent
            visible: root.showingSettings
            contentHeight: settingsCol.implicitHeight + 20 * Appearance.effectiveScale
            clip: true
            interactive: true

            ColumnLayout {
                id: settingsCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: 12 * Appearance.effectiveScale
                    rightMargin: 12 * Appearance.effectiveScale
                    topMargin: 10 * Appearance.effectiveScale
                }
                spacing: 8 * Appearance.effectiveScale

                // Header Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8 * Appearance.effectiveScale

                    // Back button
                    Rectangle {
                        width: 24 * Appearance.effectiveScale
                        height: 24 * Appearance.effectiveScale
                        radius: 12 * Appearance.effectiveScale
                        color: Appearance.m3colors.darkmode ? "#1AFFFFFF" : "#0D000000"

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "arrow_back"
                            iconSize: 14 * Appearance.effectiveScale
                            color: Appearance.m3colors.m3onSurface
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleFlip()
                        }
                    }

                    StyledText {
                        text: root.sizeMode === "1x1" ? "Config" : "Config Currencies"
                        font.pixelSize: root.sizeMode === "1x1" ? Appearance.font.pixelSize.smaller : Appearance.font.pixelSize.small
                        font.weight: Font.Bold
                        color: Appearance.colors.colPrimary
                        Layout.fillWidth: true
                    }
                }

                // Base currency input
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8 * Appearance.effectiveScale

                    StyledText {
                        text: "Base:"
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.Bold
                        color: Appearance.m3colors.m3onSurface
                        Layout.preferredWidth: 32 * Appearance.effectiveScale
                    }
                    TextField {
                        id: baseInput
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24 * Appearance.effectiveScale
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        placeholderText: CurrencyService.baseCurrency
                        color: Appearance.m3colors.m3onSurface
                        background: Rectangle {
                            color: Appearance.m3colors.darkmode ? "#1E2A38" : "#E8EFF8"
                            radius: 6 * Appearance.effectiveScale
                        }
                        onAccepted: {
                            if (Config.ready && text.trim() !== "") {
                                Config.options.appearance.currencyWidget.baseCurrency = text.toUpperCase().trim();
                            }
                        }
                    }
                }

                // Row 1: Quote 1 & 2
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8 * Appearance.effectiveScale

                    TextField {
                        id: quote1Input
                        Layout.fillWidth: true
                        Layout.preferredWidth: 50 * Appearance.effectiveScale
                        Layout.preferredHeight: 24 * Appearance.effectiveScale
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        placeholderText: "Q1: " + CurrencyService.quote1
                        color: Appearance.m3colors.m3onSurface
                        background: Rectangle {
                            color: Appearance.m3colors.darkmode ? "#1E2A38" : "#E8EFF8"
                            radius: 6 * Appearance.effectiveScale
                        }
                        onAccepted: {
                            if (Config.ready && text.trim() !== "") {
                                Config.options.appearance.currencyWidget.quote1 = text.toUpperCase().trim();
                            }
                        }
                    }

                    TextField {
                        id: quote2Input
                        Layout.fillWidth: true
                        Layout.preferredWidth: 50 * Appearance.effectiveScale
                        Layout.preferredHeight: 24 * Appearance.effectiveScale
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        placeholderText: "Q2: " + CurrencyService.quote2
                        color: Appearance.m3colors.m3onSurface
                        background: Rectangle {
                            color: Appearance.m3colors.darkmode ? "#1E2A38" : "#E8EFF8"
                            radius: 6 * Appearance.effectiveScale
                        }
                        onAccepted: {
                            if (Config.ready && text.trim() !== "") {
                                Config.options.appearance.currencyWidget.quote2 = text.toUpperCase().trim();
                            }
                        }
                    }
                }

                // Row 2: Quote 3 & 4
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8 * Appearance.effectiveScale

                    TextField {
                        id: quote3Input
                        Layout.fillWidth: true
                        Layout.preferredWidth: 50 * Appearance.effectiveScale
                        Layout.preferredHeight: 24 * Appearance.effectiveScale
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        placeholderText: "Q3: " + CurrencyService.quote3
                        color: Appearance.m3colors.m3onSurface
                        background: Rectangle {
                            color: Appearance.m3colors.darkmode ? "#1E2A38" : "#E8EFF8"
                            radius: 6 * Appearance.effectiveScale
                        }
                        onAccepted: {
                            if (Config.ready && text.trim() !== "") {
                                Config.options.appearance.currencyWidget.quote3 = text.toUpperCase().trim();
                            }
                        }
                    }

                    TextField {
                        id: quote4Input
                        Layout.fillWidth: true
                        Layout.preferredWidth: 50 * Appearance.effectiveScale
                        Layout.preferredHeight: 24 * Appearance.effectiveScale
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        placeholderText: "Q4: " + CurrencyService.quote4
                        color: Appearance.m3colors.m3onSurface
                        background: Rectangle {
                            color: Appearance.m3colors.darkmode ? "#1E2A38" : "#E8EFF8"
                            radius: 6 * Appearance.effectiveScale
                        }
                        onAccepted: {
                            if (Config.ready && text.trim() !== "") {
                                Config.options.appearance.currencyWidget.quote4 = text.toUpperCase().trim();
                            }
                        }
                    }
                }
            }
        }
    }

    // Resize Handle (supports dragging between 1x1 and 2x1)
    Rectangle {
        id: resizeHandle
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: -8 * Appearance.effectiveScale
        width: 24 * Appearance.effectiveScale
        height: 24 * Appearance.effectiveScale
        radius: 8 * Appearance.effectiveScale
        color: Appearance.m3colors.darkmode ? Appearance.colors.colOnTertiaryContainer : Appearance.colors.colSecondaryContainer
        z: 100

        opacity: root.interactive && (cfg && !cfg.locked) && (widgetHoverHandler.hovered || resizeArea.containsMouse || resizeArea.pressed) ? 0.9 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: "swap_horiz"
            iconSize: 15 * Appearance.effectiveScale
            color: Appearance.m3colors.darkmode ? Appearance.colors.colTertiaryContainer : Appearance.colors.colOnSecondaryContainer
        }

        MouseArea {
            id: resizeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeHorCursor
            preventStealing: true

            property real startWidth: 0
            property real startGlobalX: 0

            onPressed: (mouse) => {
                startWidth = root.width;
                let p = mapToItem(null, mouse.x, mouse.y);
                startGlobalX = p.x;
            }

            onPositionChanged: (mouse) => {
                if (!pressed) return;
                let p = mapToItem(null, mouse.x, mouse.y);
                let deltaX = p.x - startGlobalX;
                let targetWidth = startWidth + deltaX;
                
                let targetMode = root.getModeForWidth(targetWidth);
                if (targetMode !== root.sizeMode) {
                    if (cfg) {
                        cfg.sizeMode = targetMode;
                    }
                }
            }
        }
    }
}

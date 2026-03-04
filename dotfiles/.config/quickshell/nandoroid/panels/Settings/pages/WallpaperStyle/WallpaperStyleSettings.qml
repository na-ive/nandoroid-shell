import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

/**
 * Wallpaper & Style settings page.
 * Phase 1: Wallpaper Management (Refactored)
 */
Flickable {
    id: root
    width: parent ? parent.width : 0
    height: parent ? parent.height : 0
    contentHeight: mainCol.implicitHeight
    clip: true

    readonly property var matugenSchemes: [
        { id: "scheme-content",      name: "Content",      colors: [] },
        { id: "scheme-expressive",   name: "Expressive",   colors: [] },
        { id: "scheme-fidelity",     name: "Fidelity",     colors: [] },
        { id: "scheme-fruit-salad",  name: "Fruit Salad",  colors: [] },
        { id: "scheme-monochrome",   name: "Monochrome",   colors: [] },
        { id: "scheme-neutral",      name: "Neutral",      colors: [] },
        { id: "scheme-rainbow",      name: "Rainbow",      colors: [] },
        { id: "scheme-tonal-spot",   name: "Tonal Spot",   colors: [] }
    ]

    readonly property var basicColors: [
        { name: "Angel", file: "angel.json", colors: ["#5682A3", "#3D5A80", "#E0FBFC"] },
        { name: "Angel Light", file: "angel_light.json", colors: ["#5682A3", "#3D5A80", "#E0FBFC"] },
        { name: "Ayu", file: "ayu.json", colors: ["#ffb454", "#39bae6", "#f07178"] },
        { name: "Cobalt2", file: "cobalt2.json", colors: ["#ffc600", "#193549", "#0088ff"] },
        { name: "Cursor", file: "cursor.json", colors: ["#2DD5B7", "#D2689C", "#549e6a"] },
        { name: "Dracula", file: "dracula.json", colors: ["#bd93f9", "#50fa7b", "#8be9fd"] },
        { name: "Flexoki", file: "flexoki.json", colors: ["#ceb3a2", "#879a87", "#313131"] },
        { name: "Frappe", file: "frappe.json", colors: ["#ca9ee6", "#f2d5cf", "#eebebe"] },
        { name: "Github", file: "github.json", colors: ["#d73a49", "#0366d6", "#28a745"] },
        { name: "Gruvbox", file: "gruvbox.json", colors: ["#fab387", "#f9e2af", "#f5e0dc"] },
        { name: "Kanagawa", file: "kanagawa.json", colors: ["#7e9cd8", "#7fb4ca", "#957fb8"] },
        { name: "Latte", file: "latte.json", colors: ["#8839ef", "#4c4f69", "#d20f39"] },
        { name: "Macchiato", file: "macchiato.json", colors: ["#c6a0f6", "#f4dbd6", "#f0c6c6"] },
        { name: "Material Ocean", file: "material_ocean.json", colors: ["#89ddff", "#c792ea", "#f07178"] },
        { name: "Matrix", file: "matrix.json", colors: ["#00FF41", "#008F11", "#003B00"] },
        { name: "Mercury", file: "mercury.json", colors: ["#E0E0E0", "#9E9E9E", "#424242"] },
        { name: "Mocha", file: "mocha.json", colors: ["#cba6f7", "#f5e0dc", "#f2cdcd"] },
        { name: "Nord", file: "nord.json", colors: ["#88c0d0", "#81a1c1", "#b48ead"] },
        { name: "Open Code", file: "open_code.json", colors: ["#2DD5B7", "#D2689C", "#549e6a"] },
        { name: "Orng", file: "orng.json", colors: ["#FF9500", "#FFCC00", "#FF3B30"] },
        { name: "Osaka Jade", file: "osaka_jade.json", colors: ["#00A676", "#04471C", "#A3E4D7"] },
        { name: "Rose Pine", file: "rose_pine.json", colors: ["#c4a7e7", "#eb6f92", "#31748f"] },
        { name: "Sakura", file: "sakura.json", colors: ["#d4869c", "#c9a0a0", "#8faa8f"] },
        { name: "Samurai", file: "samurai.json", colors: ["#c41e3a", "#8b8589", "#d4af37"] },
        { name: "Synthwave84", file: "synthwave84.json", colors: ["#36f9f6", "#ff7edb", "#b084eb"] },
        { name: "Vercel", file: "vercel.json", colors: ["#0070F3", "#52A8FF", "#8E4EC6"] },
        { name: "Vesper", file: "vesper.json", colors: ["#FFC799", "#99FFE4", "#A0A0A0"] },
        { name: "Zen Burn", file: "zen_burn.json", colors: ["#8cd0d3", "#dc8cc3", "#93e0e3"] },
        { name: "Zen Garden", file: "zen_garden.json", colors: ["#7a9a7a", "#9a9080", "#8a9aa0"] }
    ]

    property var matugenPreviews: ({})
    property var pendingPreviews: ({})

    Timer {
        id: batchUpdateTimer
        interval: 200
        repeat: false
        onTriggered: {
            let newPreviews = Object.assign({}, root.matugenPreviews);
            for (let key in root.pendingPreviews) {
                newPreviews[key] = root.pendingPreviews[key];
            }
            root.matugenPreviews = newPreviews;
            root.pendingPreviews = {};
        }
    }

    Process {
        id: previewMatugen
        command: ["bash", "-c", `matugen -t "${currentScheme}" -m ${Config.options.appearance.background.darkmode ? "dark" : "light"} image "${currentPath}" --dry-run -j hex --old-json-output --source-color-index 0`]
        property string currentScheme: ""
        property string currentPath: ""
        property string currentSource: ""
        
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    // Extract only the part between { and last } to avoid extra output junk
                    const rawText = this.text.trim();
                    const jsonStart = rawText.indexOf("{");
                    const jsonEnd = rawText.lastIndexOf("}");
                    if (jsonStart === -1 || jsonEnd === -1) throw "No JSON";
                    
                    const data = JSON.parse(rawText.substring(jsonStart, jsonEnd + 1));
                    
                    const mode = Config.options.appearance.background.darkmode ? "dark" : "light";
                    const colors = [
                        data.colors.primary[mode] || data.colors.primary.default, 
                        data.colors.secondary[mode] || data.colors.secondary.default, 
                        data.colors.tertiary[mode] || data.colors.tertiary.default
                    ];
                    
                    // Batch updates to avoid flickering
                    root.pendingPreviews[previewMatugen.currentSource + "_" + previewMatugen.currentScheme] = colors;
                    batchUpdateTimer.restart();
                } catch(e) {
                    console.log("Matugen Preview Error:", e);
                    // Don't stop the iterate timer on error
                }
                previewIterateTimer.start();
            }
        }
    }

    property int previewIndex: 0
    property string previewSource: "desktop"
    Timer {
        id: previewIterateTimer
        interval: 50
        repeat: false
        onTriggered: {
            if (!Config.ready || !Config.options.lock || !Config.options.appearance) {
                previewIterateTimer.start();
                return;
            }

            if (previewIndex >= matugenSchemes.length) {
                if (previewSource === "desktop" && Config.options.lock.useSeparateWallpaper) {
                    previewSource = "lockscreen";
                    previewIndex = 0;
                } else {
                    return;
                }
            }
            
            const scheme = matugenSchemes[previewIndex].id;
            const path = (previewSource === "lockscreen" && Config.options.lock) 
                ? Config.options.lock.wallpaperPath 
                : (Config.options.appearance && Config.options.appearance.background ? Config.options.appearance.background.wallpaperPath : "");
            
            if (!path) {
                previewIndex++;
                previewIterateTimer.start();
                return;
            }

            const cleanPath = path.toString().startsWith("file://") ? path.toString().substring(7) : path.toString();
            
            if (cleanPath === "") {
                previewIndex++;
                previewIterateTimer.start();
                return;
            }

            previewMatugen.currentScheme = scheme;
            previewMatugen.currentPath = cleanPath;
            previewMatugen.currentSource = previewSource;
            previewMatugen.running = true;
            previewIndex++;
        }
    }

    function refreshPreviews() {
        if (!Config.ready || previewIterateTimer.running || previewMatugen.running) return;
        previewIndex = 0;
        previewSource = "desktop";
        root.pendingPreviews = {};
        previewIterateTimer.restart();
    }

    Timer {
        id: initTimer
        interval: 500
        repeat: false
        running: true
        onTriggered: refreshPreviews()
    }

    Connections {
        target: Config.ready ? Config.options.appearance.background : null
        function onWallpaperPathChanged() { refreshPreviews() }
    }
    
    Connections {
        target: Config.ready ? Config.options.lock : null
        function onWallpaperPathChanged() { refreshPreviews() }
        function onUseSeparateWallpaperChanged() { refreshPreviews() }
    }

    /**
     * Helper component for color scheme cards.
     */
    component ColorCard: RippleButton {
        id: card
        property string label: ""
        property var cardColors: ["transparent", "transparent", "transparent"]
        property bool isSelected: false
        
        implicitWidth: 104
        implicitHeight: 120
        buttonRadius: 28
        colBackground: Appearance.colors.colLayer2
        colBackgroundToggled: Appearance.colors.colLayer2 // Handled by border
        colText: "white"
        colTextToggled: "white"
        colRipple: Appearance.colors.colLayer2Active

        contentItem: Item {
            anchors.fill: parent
            
            // Custom background with 3 bars
            Rectangle {
                id: cardContent
                anchors.fill: parent
                radius: card.buttonRadius
                clip: true
                color: Appearance.colors.colLayer2
                
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: cardContent.width
                        height: cardContent.height
                        radius: cardContent.radius
                    }
                }

                Row {
                    anchors.fill: parent
                    Rectangle { width: parent.width/3; height: parent.height; color: card.cardColors[0] }
                    Rectangle { width: parent.width/3; height: parent.height; color: card.cardColors[1] }
                    Rectangle { width: parent.width/3; height: parent.height; color: card.cardColors[2] }
                }
                
                // Bottom Gradient for text readability
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 48
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 1.0; color: Qt.rgba(0,0,0,0.6) }
                    }
                }
            }
            
            // Selection Border / Glow
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.width: 3
                border.color: Appearance.m3colors.m3primary
                radius: card.buttonRadius
                visible: card.isSelected
                opacity: 0.8
            }

            // Label
            StyledText {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
                text: card.label
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.Medium
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                lineHeight: 0.9
                maximumLineCount: 2
                width: parent.width - 12
            }
            
            // Centered Checkmark in Circle
            Rectangle {
                anchors.centerIn: parent
                width: 32
                height: 32
                radius: 16
                color: "#1A1C1E"
                visible: card.isSelected
                
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "check"
                    iconSize: 20
                    color: "white"
                }
            }
        }
    }
    // --- Inline Components ---

    component AndroidToggle: Rectangle {
        property bool checked: false
        signal toggled()
        implicitWidth: 52; implicitHeight: 28; radius: 14
        color: checked ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
        
        Rectangle {
            width: 20; height: 20; radius: 10; anchors.verticalCenter: parent.verticalCenter
            x: parent.checked ? parent.width - width - 4 : 4
            color: parent.checked ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }
        
        MouseArea { 
            anchors.fill: parent; 
            cursorShape: Qt.PointingHandCursor; 
            onClicked: parent.toggled() 
        }
    }

    component WallpaperPreview: ColumnLayout {
        id: previewComp
        property string title
        property string source
        property bool showCheckmark: false
        property bool clickable: true
        signal clicked()
        spacing: 12
        Item {
            id: previewWrapper
            Layout.fillWidth: true
            Layout.preferredHeight: width * 9/16

            Rectangle {
                id: imgContainer
                anchors.fill: parent
                radius: 24; 
                color: Appearance.colors.colLayer1
                
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: imgContainer.width
                        height: imgContainer.height
                        radius: imgContainer.radius
                    }
                }

                Image { 
                    anchors.fill: parent; 
                    source: previewComp.source
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }
                
                // 1. Selection indicator (Primary tint) - Only when Synced/Selected
                Rectangle {
                    anchors.fill: parent
                    color: Appearance.colors.colPrimary
                    opacity: previewComp.showCheckmark ? 0.3 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                // 2. Hover overlay (High contrast for text: 30% Dark Grey)
                Rectangle {
                    anchors.fill: parent
                    color: "#1A1C1E"
                    opacity: (previewComp.clickable && mouseArea.containsMouse) ? 0.3 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                // 3. Hover Content (Icon + Text)
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: previewComp.clickable && mouseArea.containsMouse
                    
                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        text: "edit"
                        iconSize: 32
                        color: "white"
                    }
                    StyledText {
                        text: "Change wallpaper"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.DemiBold
                        color: "white"
                    }
                }
                
                // Selection Checkmark
                Rectangle {
                    width: 42; height: 42; radius: 21; anchors.centerIn: parent
                    color: Appearance.colors.colPrimary
                    visible: previewComp.showCheckmark
                    MaterialSymbol { 
                        anchors.centerIn: parent; 
                        text: "check"; 
                        color: Appearance.colors.colOnPrimary; 
                        iconSize: 24 
                    }
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                enabled: previewComp.clickable
                preventStealing: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onPressed: console.log("MouseArea PRESSED in WallpaperPreview: " + previewComp.title)
                onClicked: {
                    console.log("MouseArea CLICKED in WallpaperPreview: " + previewComp.title);
                    previewComp.clicked();
                }
            }
        }
        
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: title
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
        }
    }

    IpcHandler {
        target: "settings_wallpaper"
        function test(): void {
            console.log("IPC: Settings Wallpaper page received test signal");
        }
    }

    ColumnLayout {
        id: mainCol
        width: parent.width
        spacing: 32
        anchors.margins: 4
        visible: Config.ready
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 250 } }

        // RESET LOGS ON LOAD
        Component.onCompleted: console.log("WallpaperStyleSettings loaded successfully");

        // ── Header ──
        ColumnLayout {
            spacing: 4
            StyledText {
                text: "Wallpaper & Style"
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.Bold
                color: Appearance.colors.colOnLayer1
            }
            StyledText {
                text: "Personalize your desktop and lock screen."
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
            }
        }

        // ── Same Wallpaper Toggle ──
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: sameToggleRow.implicitHeight + 36
            radius: 20
            color: Appearance.m3colors.m3surfaceContainerHigh

            RowLayout {
                id: sameToggleRow
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20

                MaterialSymbol {
                    text: "sync"
                    iconSize: 24
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    text: "Use same wallpaper for lock screen"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                AndroidToggle {
                    id: syncToggle
                    checked: Config.ready && (Config.options.lock ? !Config.options.lock.useSeparateWallpaper : false)
                    onToggled: {
                        if (Config.ready && Config.options.lock) {
                            const current = Config.options.lock.useSeparateWallpaper
                            Config.options.lock.useSeparateWallpaper = !current
                            if (current) { // Was true (separate), now false (synced)
                                Wallpapers.selectForLockscreen(Config.options.appearance.background.wallpaperPath)
                            }
                        }
                    }
                }
            }
        }

        // ── Wallpaper Previews ──
        RowLayout {
            id: previewRow
            Layout.fillWidth: true
            spacing: 24

            property string selection: "desktop"

                WallpaperPreview {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    title: "Desktop wallpaper"
                    source: (Config.ready && Config.options.appearance && Config.options.appearance.background) ? Config.options.appearance.background.wallpaperPath : ""
                    showCheckmark: false
                    clickable: true
                    onClicked: {
                        console.log("Settings: Opening Wallpaper Selector for Desktop");
                        GlobalStates.wallpaperSelectorTarget = "desktop";
                        GlobalStates.wallpaperSelectorOpen = true;
                    }
                }

                WallpaperPreview {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    title: "Lock screen wallpaper"
                    source: (Config.ready && Config.options.lock)
                        ? (Config.options.lock.useSeparateWallpaper
                            ? Config.options.lock.wallpaperPath
                            : (Config.options.appearance && Config.options.appearance.background ? Config.options.appearance.background.wallpaperPath : ""))
                        : ""
                    showCheckmark: syncToggle.checked
                    clickable: !syncToggle.checked
                    onClicked: {
                        console.log("Settings: Opening Wallpaper Selector for Lockscreen");
                        GlobalStates.wallpaperSelectorTarget = "lock";
                        GlobalStates.wallpaperSelectorOpen = true;
                    }
                }
        }

        // ── Theme Section ──
        WsThemeColor { Layout.fillWidth: true }

        // ── Launcher Icons Section ──
        WsLauncherIcons { Layout.fillWidth: true }

        // ── Overview Settings Section ──
        WsOverview { Layout.fillWidth: true }

        // ── Clock Style Section ──
        WsClock { Layout.fillWidth: true }

        // ── Lockscreen Section ──
        WsLockscreen { Layout.fillWidth: true }

        // ── Status Bar Section ──
        WsStatusBar { Layout.fillWidth: true }

        // ── Screen Decor Section ──
        WsScreenDecor { Layout.fillWidth: true }

        // ── Typography Section ──
        WsTypography { Layout.fillWidth: true }

        // ── Date & Time Section ──
        WsDateTime { Layout.fillWidth: true }

        Item { Layout.fillHeight: true; Layout.preferredHeight: 32 }
    }
}

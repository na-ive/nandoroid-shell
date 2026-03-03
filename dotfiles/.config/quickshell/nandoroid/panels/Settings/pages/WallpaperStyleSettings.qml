import "../../../core"
import "../../../services"
import "../../../widgets"
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
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: themeToggleRow.implicitHeight + 36
            radius: 20
            color: Appearance.m3colors.m3surfaceContainerHigh

            RowLayout {
                id: themeToggleRow
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20

                MaterialSymbol {
                    text: Config.options.appearance.background.darkmode ? "dark_mode" : "light_mode"
                    iconSize: 24
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    text: "Dark theme"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                AndroidToggle {
                    checked: Config.ready && (Config.options.appearance && Config.options.appearance.background ? Config.options.appearance.background.darkmode : false)
                    onToggled: Wallpapers.toggleDarkMode()
                }
            }
        }

        // ── Color Settings ──
        ColumnLayout {
            id: colorSettingsCol
            Layout.fillWidth: true
            Layout.topMargin: 12
            spacing: 24

            property bool showAllMatugen: false
            property bool showAllBasic: false

            // Custom Segmented Style Switcher
            Row {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                spacing: 4
                
                SegmentedButton {
                    width: (parent.width - 4) / 2
                    height: parent.height
                    
                    isHighlighted: Config.ready && (Config.options.appearance && Config.options.appearance.background) ? Config.options.appearance.background.matugen : true
                    buttonText: "Wallpaper color"
                    font.pixelSize: 14 // Increased font size
                    colActive: Appearance.m3colors.m3primary
                    colActiveText: Appearance.m3colors.m3onPrimary
                    colInactive: Appearance.m3colors.m3surfaceContainerHigh
                    colInactiveText: Appearance.m3colors.m3onSurfaceVariant
                    
                    onClicked: {
                        if (Config.ready && Config.options.appearance && Config.options.appearance.background) {
                            Config.options.appearance.background.matugen = true
                        }
                    }
                }

                SegmentedButton {
                    width: (parent.width - 4) / 2
                    height: parent.height
                    
                    isHighlighted: Config.ready && (Config.options.appearance && Config.options.appearance.background) ? !Config.options.appearance.background.matugen : false
                    buttonText: "Basic color"
                    font.pixelSize: 14 // Increased font size
                    colActive: Appearance.m3colors.m3primary
                    colActiveText: Appearance.m3colors.m3onPrimary
                    colInactive: Appearance.m3colors.m3surfaceContainerHigh
                    colInactiveText: Appearance.m3colors.m3onSurfaceVariant
                    
                    onClicked: {
                        if (Config.ready && Config.options.appearance && Config.options.appearance.background) {
                            Config.options.appearance.background.matugen = false
                        }
                    }
                }
            }

            // Scheme / Color Grid (grid-cols-5 style)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 16
                visible: Config.ready && (Config.options.appearance && Config.options.appearance.background) && Config.options.appearance.background.matugen
                
                GridLayout {
                    Layout.fillWidth: true
                    columns: 5
                    rowSpacing: 16
                    columnSpacing: 16

                    // Desktop Schemes
                    Repeater {
                        model: root.matugenSchemes
                        delegate: ColorCard {
                            Layout.fillWidth: true
                            label: (Config.ready && Config.options.lock && Config.options.lock.useSeparateWallpaper) ? "Desktop\n" + modelData.name : modelData.name
                            cardColors: {
                                const key = "desktop_" + modelData.id;
                                if (root.matugenPreviews[key]) return root.matugenPreviews[key];
                                const def = Appearance.m3colors.m3surfaceContainerHigh;
                                return [def, def, def];
                            }
                            isSelected: Config.ready && (Config.options.appearance && Config.options.appearance.background) && Config.options.appearance.background.matugen && Config.options.appearance.background.matugenScheme === modelData.id && Config.options.appearance.background.matugenSource === "desktop"
                            onClicked: {
                                Config.options.appearance.background.matugenCustomColor = ""
                                Config.options.appearance.background.matugenThemeFile = ""
                                Wallpapers.applyScheme(modelData.id, "desktop")
                            }
                        }
                    }

                    // Lockscreen Schemes (Only if separate wallpaper is on)
                    Repeater {
                        model: {
                            if (!(Config.ready && Config.options.lock && Config.options.lock.useSeparateWallpaper)) return 0;
                            if (colorSettingsCol.showAllMatugen) return root.matugenSchemes;
                            return root.matugenSchemes.slice(0, 2); // Show 2 more to reach total of 10
                        }
                        delegate: ColorCard {
                            Layout.fillWidth: true
                            label: "Lockscreen\n" + modelData.name
                            cardColors: {
                                const key = "lockscreen_" + modelData.id;
                                if (root.matugenPreviews[key]) return root.matugenPreviews[key];
                                const def = Appearance.m3colors.m3surfaceContainerHigh;
                                return [def, def, def];
                            }
                            isSelected: Config.ready && (Config.options.appearance && Config.options.appearance.background) && Config.options.appearance.background.matugen && Config.options.appearance.background.matugenScheme === modelData.id && Config.options.appearance.background.matugenSource === "lockscreen"
                            onClicked: {
                                Config.options.appearance.background.matugenCustomColor = ""
                                Config.options.appearance.background.matugenThemeFile = ""
                                Wallpapers.applyScheme(modelData.id, "lockscreen")
                            }
                        }
                    }
                }

                // Show More Toggle for Matugen (only if separate wallpaper is on)
                RippleButton {
                    visible: Config.ready && Config.options.lock && Config.options.lock.useSeparateWallpaper
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    buttonRadius: 16
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    onClicked: colorSettingsCol.showAllMatugen = !colorSettingsCol.showAllMatugen
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        MaterialSymbol {
                            text: colorSettingsCol.showAllMatugen ? "expand_less" : "expand_more"
                            iconSize: 20
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: colorSettingsCol.showAllMatugen ? "Show less" : "Show more colors"
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 16
                visible: Config.ready && (Config.options.appearance && Config.options.appearance.background) && !Config.options.appearance.background.matugen
                
                GridLayout {
                    Layout.fillWidth: true
                    columns: 5
                    rowSpacing: 16
                    columnSpacing: 16

                    Repeater {
                        model: colorSettingsCol.showAllBasic ? root.basicColors : root.basicColors.slice(0, 10)
                        delegate: ColorCard {
                            Layout.fillWidth: true
                            label: modelData.name
                            cardColors: modelData.colors
                            isSelected: Config.ready && (Config.options.appearance && Config.options.appearance.background) && !Config.options.appearance.background.matugen && Config.options.appearance.background.matugenThemeFile === modelData.file
                            onClicked: {
                                Config.options.appearance.background.matugenScheme = ""
                                Config.options.appearance.background.matugenSource = ""
                                Wallpapers.applyTheme(modelData.file)
                            }
                        }
                    }
                }

                // Show More Toggle for Basic Colors
                RippleButton {
                    visible: root.basicColors.length > 10
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    buttonRadius: 16
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    onClicked: colorSettingsCol.showAllBasic = !colorSettingsCol.showAllBasic
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        MaterialSymbol {
                            text: colorSettingsCol.showAllBasic ? "expand_less" : "expand_more"
                            iconSize: 20
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: colorSettingsCol.showAllBasic ? "Show less" : "Show more colors"
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                    }
                }
            }
        }

        // ── Launcher Icons Section ──
        ColumnLayout {
            id: launcherIconsSection
            Layout.fillWidth: true
            Layout.topMargin: 12
            spacing: 16
            
            property bool showAllShapes: false
            readonly property var allShapes: ["Square", "Circle", "Diamond", "Pill", "Clover4Leaf", "Burst", "Heart", "Flower", "Arch", "Fan", "Gem", "Sunny", "VerySunny", "Slanted", "Arrow", "SemiCircle", "Oval", "ClamShell", "Pentagon", "Ghostish", "Clover8Leaf", "SoftBurst", "Boom", "SoftBoom", "Puffy", "PuffyDiamond", "Bun", "Cookie4Sided", "Cookie6Sided", "Cookie7Sided", "Cookie9Sided", "Cookie12Sided", "PixelCircle", "PixelTriangle", "Triangle"]

            RowLayout {
                spacing: 12
                Layout.bottomMargin: 4
                MaterialSymbol {
                    text: "apps"
                    iconSize: 24
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: "Launcher Icons"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 4
                rowSpacing: 12
                columnSpacing: 12
                Layout.leftMargin: 4
                Layout.rightMargin: 4

                Repeater {
                    model: parent.parent.showAllShapes ? parent.parent.allShapes : parent.parent.allShapes.slice(0, 8)
                    delegate: RippleButton {
                        id: shapeBtn
                        Layout.fillWidth: true
                        Layout.preferredHeight: 84
                        
                        readonly property bool isSelected: Config.ready && Config.options.search.iconShape === modelData
                        
                        buttonRadius: isSelected ? 14 : 28
                        colBackground: isSelected ? Appearance.m3colors.m3primaryContainer : Appearance.m3colors.m3surfaceContainerHigh
                        colRipple: Appearance.m3colors.m3primary
                        
                        onClicked: if (Config.ready) Config.options.search.iconShape = modelData
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            MaterialShape {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                shapeString: modelData
                                color: shapeBtn.isSelected ? Appearance.colors.colNotchText : Appearance.m3colors.m3onSurfaceVariant
                            }
                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData
                                font.pixelSize: 10
                                font.weight: shapeBtn.isSelected ? Font.Bold : Font.Normal
                                color: shapeBtn.isSelected ? Appearance.colors.colNotchText : Appearance.m3colors.m3onSurface
                            }
                        }
                    }
                }
            }

            // More / Less Toggle Button (Bluetooth Style)
            RippleButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                buttonRadius: 16
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                onClicked: launcherIconsSection.showAllShapes = !launcherIconsSection.showAllShapes
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    MaterialSymbol {
                        text: launcherIconsSection.showAllShapes ? "expand_less" : "expand_more"
                        iconSize: 20
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: launcherIconsSection.showAllShapes ? "Show less" : "Show more shapes"
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }
            }
        }

        // ── Overview Settings Section ──
        ColumnLayout {
            id: overviewSettingsSection
            Layout.fillWidth: true
            Layout.topMargin: 12
            spacing: 4
            
            RowLayout {
                spacing: 12
                Layout.bottomMargin: 8
                MaterialSymbol {
                    text: "grid_view"
                    iconSize: 24
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: "Overview Settings"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }
            }

            // Rows
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: overviewRowsRow.implicitHeight + 40
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8
                fullRadius: 20
                
                RowLayout {
                    id: overviewRowsRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    StyledText { 
                        text: "Rows"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                        Layout.preferredWidth: 140
                    }
                    StyledSlider {
                        Layout.fillWidth: true
                        value: Config.ready && Config.options.overview ? Config.options.overview.rows : 2
                        from: 1; to: 5; stepSize: 1
                        onMoved: if (Config.ready && Config.options.overview) Config.options.overview.rows = Math.round(value)
                    }
                    StyledText { 
                        text: Math.round(Config.ready && Config.options.overview ? Config.options.overview.rows : 2).toString()
                        color: Appearance.colors.colOnLayer1 
                        Layout.preferredWidth: 40
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            // Columns
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: overviewColsRow.implicitHeight + 40
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8
                fullRadius: 20
                
                RowLayout {
                    id: overviewColsRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    StyledText { 
                        text: "Columns"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                        Layout.preferredWidth: 140
                    }
                    StyledSlider {
                        Layout.fillWidth: true
                        value: Config.ready && Config.options.overview ? Config.options.overview.columns : 5
                        from: 1; to: 10; stepSize: 1
                        onMoved: if (Config.ready && Config.options.overview) Config.options.overview.columns = Math.round(value)
                    }
                    StyledText { 
                        text: Math.round(Config.ready && Config.options.overview ? Config.options.overview.columns : 5).toString()
                        color: Appearance.colors.colOnLayer1 
                        Layout.preferredWidth: 40
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            // Scale
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: overviewScaleRow.implicitHeight + 40
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8
                fullRadius: 20
                
                RowLayout {
                    id: overviewScaleRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    StyledText { 
                        text: "Window Scale"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                        Layout.preferredWidth: 140
                    }
                    StyledSlider {
                        Layout.fillWidth: true
                        value: Config.ready && Config.options.overview ? Config.options.overview.scale * 100 : 15
                        from: 5; to: 50; stepSize: 1
                        onMoved: if (Config.ready && Config.options.overview) Config.options.overview.scale = value / 100.0
                    }
                    StyledText { 
                        text: Math.round(Config.ready && Config.options.overview ? Config.options.overview.scale * 100 : 15).toString() + "%"
                        color: Appearance.colors.colOnLayer1 
                        Layout.preferredWidth: 40
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            // Workspace Spacing
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: overviewSpacingRow.implicitHeight + 40
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8
                fullRadius: 20
                
                RowLayout {
                    id: overviewSpacingRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    StyledText { 
                        text: "Workspace Spacing"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                        Layout.preferredWidth: 140
                    }
                    StyledSlider {
                        Layout.fillWidth: true
                        value: Config.ready && Config.options.overview ? Config.options.overview.workspaceSpacing : 10
                        from: 0; to: 50; stepSize: 1
                        onMoved: if (Config.ready && Config.options.overview) Config.options.overview.workspaceSpacing = Math.round(value)
                    }
                    StyledText { 
                        text: Math.round(Config.ready && Config.options.overview ? Config.options.overview.workspaceSpacing : 10).toString() + "px"
                        color: Appearance.colors.colOnLayer1 
                        Layout.preferredWidth: 40
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }

        // ── Clock Style Section ──
        ColumnLayout {
            id: clockStyleSection
            Layout.fillWidth: true
            Layout.topMargin: 12
            spacing: 16
            
            property string activeContext: "desktop"
            property bool showAdvanced: false

            // Section Header
            RowLayout {
                spacing: 12
                Layout.bottomMargin: 4
                MaterialSymbol {
                    text: "watch"
                    iconSize: 24
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: "Clock Style"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }
                
                // Reset Position Button (Only for Desktop)
                RippleButton {
                    visible: !Config.options.appearance.clock.useSameStyle || clockStyleSection.activeContext === "desktop"
                    Layout.preferredHeight: 32
                    implicitWidth: 120
                    buttonText: "Reset Position"
                    onClicked: {
                        Config.options.appearance.clock.offsetX = 0
                        Config.options.appearance.clock.offsetY = -50
                    }
                    colBackground: Appearance.m3colors.m3surfaceContainerHighest
                }
            }

            // Context Switcher (Only if NOT same style)
            Row {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                spacing: 4
                visible: Config.ready && !Config.options.appearance.clock.useSameStyle
                
                SegmentedButton {
                    width: (parent.width - 4) / 2
                    height: parent.height
                    buttonText: "Desktop"
                    isHighlighted: clockStyleSection.activeContext === "desktop"
                    onClicked: clockStyleSection.activeContext = "desktop"
                    colActive: Appearance.m3colors.m3primary
                    colActiveText: Appearance.m3colors.m3onPrimary
                }
                SegmentedButton {
                    width: (parent.width - 4) / 2
                    height: parent.height
                    buttonText: "Lockscreen"
                    isHighlighted: clockStyleSection.activeContext === "lock"
                    onClicked: clockStyleSection.activeContext = "lock"
                    colActive: Appearance.m3colors.m3primary
                    colActiveText: Appearance.m3colors.m3onPrimary
                }
            }

            // Style Picker
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 120
                radius: 20
                color: Appearance.m3colors.m3surfaceContainerHigh
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    Repeater {
                        model: [
                            { id: "digital", name: "Digital", icon: "numbers" },
                            { id: "analog",  name: "Analog",  icon: "watch" },
                            { id: "stacked", name: "Stacked", icon: "view_day" },
                            { id: "code",    name: "Code",    icon: "code" }
                        ]
                        delegate: RippleButton {
                            id: clockStyleBtn
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            buttonRadius: 16
                            
                            readonly property bool isSelected: {
                                if (!Config.ready) return false
                                if (Config.options.appearance.clock.useSameStyle || clockStyleSection.activeContext === "desktop") {
                                    return Config.options.appearance.clock.style === modelData.id
                                } else {
                                    return Config.options.appearance.clock.styleLocked === modelData.id
                                }
                            }
                            
                            colBackground: isSelected ? Appearance.m3colors.m3primaryContainer : Appearance.m3colors.m3surfaceContainerLow
                            colRipple: Appearance.m3colors.m3primary
                            
                            onClicked: {
                                if (!Config.ready) return
                                if (Config.options.appearance.clock.useSameStyle) {
                                    Config.options.appearance.clock.style = modelData.id
                                    Config.options.appearance.clock.styleLocked = modelData.id
                                } else {
                                    if (clockStyleSection.activeContext === "desktop") {
                                        Config.options.appearance.clock.style = modelData.id
                                    } else {
                                        Config.options.appearance.clock.styleLocked = modelData.id
                                    }
                                }
                            }
                            
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                MaterialSymbol {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.icon
                                    iconSize: 24
                                    color: clockStyleBtn.isSelected ? Appearance.m3colors.m3onPrimaryContainer : Appearance.m3colors.m3onSurfaceVariant
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.name
                                    font.pixelSize: 12
                                    font.weight: clockStyleBtn.isSelected ? Font.Bold : Font.Normal
                                    color: clockStyleBtn.isSelected ? Appearance.m3colors.m3onPrimaryContainer : Appearance.m3colors.m3onSurface
                                }
                            }
                        }
                    }
                }
            }

            // Advanced Settings Toggle
            RippleButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                buttonRadius: 16
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                onClicked: clockStyleSection.showAdvanced = !clockStyleSection.showAdvanced
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    MaterialSymbol {
                        text: clockStyleSection.showAdvanced ? "expand_less" : "expand_more"
                        iconSize: 20
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: "Advanced Settings"
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }
            }

            // Advanced Panel
            ColumnLayout {
                id: advancedPanel
                Layout.fillWidth: true
                visible: clockStyleSection.showAdvanced
                spacing: 12

                readonly property string currentStyle: {
                    if (!Config.ready) return "digital"
                    if (Config.options.appearance.clock.useSameStyle || clockStyleSection.activeContext === "desktop") return Config.options.appearance.clock.style;
                    return Config.options.appearance.clock.styleLocked;
                }

                // Routes read/write to the correct config object based on context
                readonly property bool isLockCtx: clockStyleSection.activeContext === "lock" && !Config.options.appearance.clock.useSameStyle
                readonly property var digitalCfg: isLockCtx ? Config.options.appearance.clock.digitalLocked : Config.options.appearance.clock.digital
                readonly property var analogCfg:  isLockCtx ? Config.options.appearance.clock.analogLocked  : Config.options.appearance.clock.analog
                readonly property var codeCfg:    isLockCtx ? Config.options.appearance.clock.codeLocked    : Config.options.appearance.clock.code
                readonly property var stackedCfg: isLockCtx ? Config.options.appearance.clock.stackedLocked : Config.options.appearance.clock.stacked

                // ── Digital Advanced ──
                ColumnLayout {
                    visible: advancedPanel.currentStyle === "digital"
                    Layout.fillWidth: true
                    spacing: 8

                    // Color Style
                    GridLayout {
                        columns: 2
                        Layout.fillWidth: true
                        rowSpacing: 12
                        StyledText { text: "Color Style"; color: Appearance.colors.colOnLayer1 }
                        Row {
                            Layout.alignment: Qt.AlignRight
                            spacing: 2
                            Repeater {
                                model: ["primary", "secondary", "onSurface", "surface"]
                                delegate: SegmentedButton {
                                   required property string modelData
                                    buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                    isHighlighted: Config.ready && advancedPanel.digitalCfg.colorStyle === modelData
                                    onClicked: advancedPanel.digitalCfg.colorStyle = modelData
                                }
                            }
                        }

                        // Orientation
                        StyledText { text: "Orientation"; color: Appearance.colors.colOnLayer1 }
                        Row {
                            Layout.alignment: Qt.AlignRight
                            spacing: 2
                            SegmentedButton {
                                buttonText: "Horizontal"
                                isHighlighted: Config.ready && !advancedPanel.digitalCfg.isVertical
                                onClicked: advancedPanel.digitalCfg.isVertical = false
                            }
                            SegmentedButton {
                                buttonText: "Vertical"
                                isHighlighted: Config.ready && advancedPanel.digitalCfg.isVertical
                                onClicked: advancedPanel.digitalCfg.isVertical = true
                            }
                        }

                        // Font Size
                        StyledText { text: "Font Size"; color: Appearance.colors.colOnLayer1 }
                        RowLayout {
                            Layout.alignment: Qt.AlignRight
                            StyledSlider {
                                Layout.preferredWidth: 200
                                value: Config.ready ? advancedPanel.digitalCfg.fontSize : 84
                                from: 48; to: 200
                                onMoved: advancedPanel.digitalCfg.fontSize = Math.round(value)
                            }
                            StyledText { text: Math.round(advancedPanel.digitalCfg.fontSize).toString(); color: Appearance.colors.colOnLayer1 }
                        }


                        // Time-Date Gap
                        StyledText { text: "Date Gap"; color: Appearance.colors.colOnLayer1 }
                        RowLayout {
                            Layout.alignment: Qt.AlignRight
                            StyledSlider {
                                Layout.preferredWidth: 200
                                from: -40; to: 60; stepSize: 1
                                value: Config.ready ? (advancedPanel.digitalCfg.dateGap ?? 4) : 4
                                onMoved: advancedPanel.digitalCfg.dateGap = Math.round(value)
                            }
                            StyledText {
                                text: Math.round(advancedPanel.digitalCfg.dateGap ?? 4).toString() + "px"
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                    }
                }

                // ── Analog Advanced ──
                ColumnLayout {
                    visible: advancedPanel.currentStyle === "analog"
                    Layout.fillWidth: true
                    spacing: 16

                    GridLayout {
                        columns: 2
                        Layout.fillWidth: true
                        rowSpacing: 16
                        columnSpacing: 12

                        StyledText { text: "Clock Size"; Layout.alignment: Qt.AlignVCenter; color: Appearance.colors.colOnLayer1 }
                        RowLayout {
                            Layout.alignment: Qt.AlignRight
                            StyledSlider {
                                Layout.preferredWidth: 200
                                value: Config.ready ? advancedPanel.analogCfg.size : 240
                                from: 120; to: 480
                                onMoved: advancedPanel.analogCfg.size = Math.round(value)
                            }
                            StyledText { text: Math.round(advancedPanel.analogCfg.size).toString(); color: Appearance.colors.colOnLayer1 }
                        }

                        StyledText {
                            text: "Face Shape"
                            Layout.alignment: Qt.AlignTop
                            color: Appearance.colors.colOnLayer1
                            Layout.topMargin: 12
                            visible: Config.ready && advancedPanel.analogCfg.backgroundStyle === "shape"
                        }
                        Flow {
                            Layout.fillWidth: true
                            spacing: 8
                            visible: Config.ready && advancedPanel.analogCfg.backgroundStyle === "shape"
                            Repeater {
                                model: ["Circle", "Square", "Slanted", "Arch", "Fan", "Arrow", "SemiCircle", "Oval", "Pill", "Triangle", "Diamond", "ClamShell", "Pentagon", "Gem", "Sunny", "VerySunny", "Cookie4Sided", "Cookie6Sided", "Cookie9Sided", "Cookie12Sided", "Clover4Leaf", "Burst", "SoftBurst", "Flower", "Puffy", "Heart"]
                                delegate: RippleButton {
                                    required property string modelData
                                    width: 56; height: 56
                                    buttonRadius: 12
                                    property bool isSelected: Config.ready && advancedPanel.analogCfg.shape === modelData
                                    colBackground: isSelected ? Appearance.colors.colPrimary : Appearance.m3colors.m3surfaceContainerHigh
                                    onClicked: advancedPanel.analogCfg.shape = modelData
                                    MaterialShape {
                                        anchors.centerIn: parent
                                        implicitSize: 32
                                        shapeString: modelData
                                        color: parent.isSelected ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
                                    }
                                }
                            }
                        }
                        StyledText { text: "Background Style"; color: Appearance.colors.colOnLayer1 }
                        Row {
                            Layout.alignment: Qt.AlignRight
                            spacing: 2
                            Repeater {
                                model: ["none", "shape", "cookie", "sine"]
                                delegate: SegmentedButton {
                                    required property string modelData
                                    buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                    isHighlighted: Config.ready && advancedPanel.analogCfg.backgroundStyle === modelData
                                    onClicked: advancedPanel.analogCfg.backgroundStyle = modelData
                                }
                            }
                        }

                        StyledText {
                            text: "Sides"
                            color: Appearance.colors.colOnLayer1
                            visible: Config.ready && (advancedPanel.analogCfg.backgroundStyle === "cookie" || advancedPanel.analogCfg.backgroundStyle === "sine")
                        }
                        RowLayout {
                            visible: Config.ready && (advancedPanel.analogCfg.backgroundStyle === "cookie" || advancedPanel.analogCfg.backgroundStyle === "sine")
                            Layout.fillWidth: true
                            StyledSlider {
                                Layout.fillWidth: true
                                from: 3
                                to: 36
                                stepSize: 1
                                value: Config.ready ? advancedPanel.analogCfg.sides : 12
                                onMoved: advancedPanel.analogCfg.sides = Math.round(value)
                            }
                            StyledText {
                                text: Math.round(advancedPanel.analogCfg.sides).toString()
                                color: Appearance.colors.colOnLayer1
                            }
                        }

                        StyledText { text: "Constantly Rotate"; color: Appearance.colors.colOnLayer1 }
                        AndroidToggle {
                            Layout.alignment: Qt.AlignRight
                            checked: Config.ready && advancedPanel.analogCfg.constantlyRotate
                            onToggled: advancedPanel.analogCfg.constantlyRotate = !advancedPanel.analogCfg.constantlyRotate
                        }

                        StyledText { text: "Time Indicators"; color: Appearance.colors.colOnLayer1 }
                        AndroidToggle {
                            Layout.alignment: Qt.AlignRight
                            checked: Config.ready && advancedPanel.analogCfg.timeIndicators
                            onToggled: advancedPanel.analogCfg.timeIndicators = !advancedPanel.analogCfg.timeIndicators
                        }

                        StyledText { text: "Hour Marks"; color: Appearance.colors.colOnLayer1 }
                        AndroidToggle {
                            Layout.alignment: Qt.AlignRight
                            checked: Config.ready && advancedPanel.analogCfg.hourMarks
                            onToggled: advancedPanel.analogCfg.hourMarks = !advancedPanel.analogCfg.hourMarks
                        }

                        StyledText { text: "Show Marks"; color: Appearance.colors.colOnLayer1 }
                        AndroidToggle {
                            Layout.alignment: Qt.AlignRight
                            checked: Config.ready && advancedPanel.analogCfg.showMarks
                            onToggled: advancedPanel.analogCfg.showMarks = !advancedPanel.analogCfg.showMarks
                        }

                        StyledText {
                            text: "Dial Style"
                            color: Appearance.colors.colOnLayer1
                            visible: Config.ready && advancedPanel.analogCfg.showMarks
                        }
                        Row {
                            visible: Config.ready && advancedPanel.analogCfg.showMarks
                            Layout.alignment: Qt.AlignRight
                            spacing: 2
                            Repeater {
                                model: ["none", "dots", "full", "numbers"]
                                delegate: SegmentedButton {
                                    required property string modelData
                                    buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                    isHighlighted: Config.ready && advancedPanel.analogCfg.dialStyle === modelData
                                    onClicked: advancedPanel.analogCfg.dialStyle = modelData
                                }
                            }
                        }

                        StyledText { text: "Hour Hand"; color: Appearance.colors.colOnLayer1 }
                        Row {
                            Layout.alignment: Qt.AlignRight
                            spacing: 2
                            Repeater {
                                model: ["none", "classic", "hollow", "fill"]
                                delegate: SegmentedButton {
                                    required property string modelData
                                    buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                    isHighlighted: Config.ready && advancedPanel.analogCfg.hourHandStyle === modelData
                                    onClicked: advancedPanel.analogCfg.hourHandStyle = modelData
                                }
                            }
                        }

                        StyledText { text: "Minute Hand"; color: Appearance.colors.colOnLayer1 }
                        Row {
                            Layout.alignment: Qt.AlignRight
                            spacing: 2
                            Repeater {
                                model: ["none", "classic", "thin", "medium", "bold"]
                                delegate: SegmentedButton {
                                    required property string modelData
                                    buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                    isHighlighted: Config.ready && advancedPanel.analogCfg.minuteHandStyle === modelData
                                    onClicked: advancedPanel.analogCfg.minuteHandStyle = modelData
                                }
                            }
                        }

                        StyledText { text: "Second Hand"; color: Appearance.colors.colOnLayer1 }
                        Row {
                            Layout.alignment: Qt.AlignRight
                            spacing: 2
                            Repeater {
                                model: ["none", "classic", "line", "dot"]
                                delegate: SegmentedButton {
                                    required property string modelData
                                    buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                    isHighlighted: Config.ready && advancedPanel.analogCfg.secondHandStyle === modelData
                                    onClicked: advancedPanel.analogCfg.secondHandStyle = modelData
                                }
                            }
                        }

                        StyledText { text: "Date Style"; color: Appearance.colors.colOnLayer1 }
                        Row {
                            Layout.alignment: Qt.AlignRight
                            spacing: 2
                            Repeater {
                                model: ["none", "bubble", "border", "rect"]
                                delegate: SegmentedButton {
                                    required property string modelData
                                    buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                    isHighlighted: Config.ready && advancedPanel.analogCfg.dateStyle === modelData
                                    onClicked: advancedPanel.analogCfg.dateStyle = modelData
                                }
                            }
                        }




                    }
                }

                // ── Code Advanced ──
                ColumnLayout {
                    visible: advancedPanel.currentStyle === "code"
                    Layout.fillWidth: true
                    spacing: 12

                    GridLayout {
                        columns: 2
                        Layout.fillWidth: true
                        rowSpacing: 16
                        columnSpacing: 12

                        StyledText { text: "Value Color"; color: Appearance.colors.colOnLayer1 }
                        Row {
                            Layout.alignment: Qt.AlignRight
                            spacing: 2
                            Repeater {
                                model: ["primary", "secondary", "tertiary", "onSurface", "surface"]
                                delegate: SegmentedButton {
                                    required property string modelData
                                    buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                    isHighlighted: Config.ready && advancedPanel.codeCfg.valueColorStyle === modelData
                                    onClicked: advancedPanel.codeCfg.valueColorStyle = modelData
                                }
                            }
                        }

                        StyledText { text: "Keyword Color"; color: Appearance.colors.colOnLayer1 }
                        Row {
                            Layout.alignment: Qt.AlignRight
                            spacing: 2
                            Repeater {
                                model: ["primary", "secondary", "tertiary", "onSurface", "surface"]
                                delegate: SegmentedButton {
                                    required property string modelData
                                    buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                    isHighlighted: Config.ready && advancedPanel.codeCfg.keywordColorStyle === modelData
                                    onClicked: advancedPanel.codeCfg.keywordColorStyle = modelData
                                }
                            }
                        }

                        StyledText { text: "Block Color"; color: Appearance.colors.colOnLayer1 }
                        Row {
                            Layout.alignment: Qt.AlignRight
                            spacing: 2
                            Repeater {
                                model: ["primary", "secondary", "tertiary", "onSurface", "surface"]
                                delegate: SegmentedButton {
                                    required property string modelData
                                    buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                    isHighlighted: Config.ready && advancedPanel.codeCfg.blockColorStyle === modelData
                                    onClicked: advancedPanel.codeCfg.blockColorStyle = modelData
                                }
                            }
                        }

                        StyledText {
                            text: "Block Style"
                            color: Appearance.colors.colOnLayer1
                        }
                        Row {
                            Layout.alignment: Qt.AlignRight
                            spacing: 2
                            Repeater {
                                model: [
                                    { id: "js",     label: "JS / while" },
                                    { id: "python", label: "Python" },
                                    { id: "rust",   label: "Rust" },
                                    { id: "c",      label: "C/C++" },
                                    { id: "kotlin", label: "Kotlin" }
                                ]
                                delegate: SegmentedButton {
                                    required property var modelData
                                    buttonText: modelData.label
                                    isHighlighted: Config.ready && advancedPanel.codeCfg.blockType === modelData.id
                                    onClicked: advancedPanel.codeCfg.blockType = modelData.id
                                }
                            }
                        }

                        StyledText { text: "Font Size"; color: Appearance.colors.colOnLayer1 }
                        RowLayout {
                            Layout.alignment: Qt.AlignRight
                            StyledSlider {
                                Layout.preferredWidth: 200
                                value: Config.ready ? advancedPanel.codeCfg.fontSize : 18
                                from: 12; to: 48
                                onMoved: advancedPanel.codeCfg.fontSize = Math.round(value)
                            }
                            StyledText { text: Math.round(advancedPanel.codeCfg.fontSize).toString(); color: Appearance.colors.colOnLayer1 }
                        }

                    }
                }

                // ── Stacked Advanced ──
                ColumnLayout {
                    visible: advancedPanel.currentStyle === "stacked"
                    Layout.fillWidth: true
                    spacing: 12

                    GridLayout {
                        columns: 2
                        Layout.fillWidth: true
                        rowSpacing: 16
                        columnSpacing: 12

                        StyledText { text: "Main Color"; color: Appearance.colors.colOnLayer1 }
                        Row {
                            Layout.alignment: Qt.AlignRight
                            spacing: 2
                            Repeater {
                                model: ["primary", "secondary", "tertiary", "error", "onSurface"]
                                delegate: SegmentedButton {
                                    required property string modelData
                                    buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                    isHighlighted: Config.ready && advancedPanel.stackedCfg.colorStyle === modelData
                                    onClicked: advancedPanel.stackedCfg.colorStyle = modelData
                                }
                            }
                        }

                        StyledText { text: "Text Color"; color: Appearance.colors.colOnLayer1 }
                        Row {
                            Layout.alignment: Qt.AlignRight
                            spacing: 2
                            Repeater {
                                model: ["primary", "secondary", "tertiary", "onSurface", "surface"]
                                delegate: SegmentedButton {
                                    required property string modelData
                                    buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                    isHighlighted: Config.ready && advancedPanel.stackedCfg.textColorStyle === modelData
                                    onClicked: advancedPanel.stackedCfg.textColorStyle = modelData
                                }
                            }
                        }

                        StyledText { text: "Alignment"; color: Appearance.colors.colOnLayer1 }
                        Row {
                            Layout.alignment: Qt.AlignRight
                            spacing: 2
                            Repeater {
                                model: ["left", "center", "right"]
                                delegate: SegmentedButton {
                                    required property string modelData
                                    buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                    isHighlighted: Config.ready && advancedPanel.stackedCfg.alignment === modelData
                                    onClicked: advancedPanel.stackedCfg.alignment = modelData
                                }
                            }
                        }

                        StyledText { text: "Clock Size"; color: Appearance.colors.colOnLayer1 }
                        RowLayout {
                            Layout.alignment: Qt.AlignRight
                            StyledSlider {
                                Layout.preferredWidth: 200
                                value: Config.ready ? advancedPanel.stackedCfg.fontSize : 84
                                from: 32; to: 160
                                onMoved: advancedPanel.stackedCfg.fontSize = Math.round(value)
                            }
                            StyledText { text: Math.round(advancedPanel.stackedCfg.fontSize).toString(); color: Appearance.colors.colOnLayer1 }
                        }

                        StyledText { text: "Label Size"; color: Appearance.colors.colOnLayer1 }
                        RowLayout {
                            Layout.alignment: Qt.AlignRight
                            StyledSlider {
                                Layout.preferredWidth: 200
                                value: Config.ready ? advancedPanel.stackedCfg.labelFontSize : 42
                                from: 16; to: 84
                                onMoved: advancedPanel.stackedCfg.labelFontSize = Math.round(value)
                            }
                            StyledText { text: Math.round(advancedPanel.stackedCfg.labelFontSize).toString(); color: Appearance.colors.colOnLayer1 }
                        }

                    }
                }
            }

            // Global Toggles Column
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                // Use Same Style Toggle (Grouped with main style usually, but here is fine)
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: sameStyleRow.implicitHeight + 32
                    orientation: Qt.Vertical
                    maxRadius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    RowLayout {
                        id: sameStyleRow
                        anchors.fill: parent; anchors.margins: 16
                        spacing: 16
                        MaterialSymbol { text: "sync"; iconSize: 24; color: Appearance.colors.colPrimary }
                        StyledText { text: "Use same style for lockscreen"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                        AndroidToggle {
                            checked: Config.ready && Config.options.appearance.clock.useSameStyle
                            onToggled: {
                                if (Config.ready) {
                                    Config.options.appearance.clock.useSameStyle = !Config.options.appearance.clock.useSameStyle
                                    if (Config.options.appearance.clock.useSameStyle) Config.options.appearance.clock.styleLocked = Config.options.appearance.clock.style
                                }
                            }
                        }
                    }
                }

                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: showOnDesktopRow.implicitHeight + 32
                    orientation: Qt.Vertical
                    maxRadius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    RowLayout {
                        id: showOnDesktopRow
                        anchors.fill: parent; anchors.margins: 16
                        spacing: 16
                        MaterialSymbol { text: "desktop_windows"; iconSize: 24; color: Appearance.colors.colPrimary }
                        StyledText { text: "Show clock on desktop"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                        AndroidToggle {
                            checked: Config.ready && Config.options.appearance.clock.showOnDesktop
                            onToggled: if(Config.ready) Config.options.appearance.clock.showOnDesktop = !Config.options.appearance.clock.showOnDesktop
                        }
                    }
                }
                
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: showDateRow.implicitHeight + 32
                    orientation: Qt.Vertical
                    maxRadius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    RowLayout {
                        id: showDateRow
                        anchors.fill: parent; anchors.margins: 16
                        spacing: 16
                        MaterialSymbol { text: "calendar_today"; iconSize: 24; color: Appearance.colors.colPrimary }
                        StyledText { text: "Show date"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                        AndroidToggle {
                            checked: {
                                if (!Config.ready) return true;
                                const s = advancedPanel.currentStyle;
                                if (s === "digital") return Config.options.appearance.clock.digital.showDate;
                                if (s === "analog") return Config.options.appearance.clock.analog.showDate;
                                return Config.options.appearance.clock.code.showDate;
                            }
                            onToggled: {
                                if (!Config.ready) return;
                                const s = advancedPanel.currentStyle;
                                if (s === "digital") Config.options.appearance.clock.digital.showDate = !Config.options.appearance.clock.digital.showDate;
                                else if (s === "analog") Config.options.appearance.clock.analog.showDate = !Config.options.appearance.clock.analog.showDate;
                                else Config.options.appearance.clock.code.showDate = !Config.options.appearance.clock.code.showDate;
                            }
                        }
                    }
                }
            }
        }
        
        // ── Lockscreen Section ──
        ColumnLayout {
            id: lockscreenStyleSection
            Layout.fillWidth: true
            Layout.topMargin: 12
            spacing: 16

            // Section Header
            RowLayout {
                spacing: 12
                Layout.bottomMargin: 4

                MaterialSymbol {
                    text: "lock"
                    iconSize: 24
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: "Lockscreen"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: showCavaRow.implicitHeight + 32
                    orientation: Qt.Vertical
                    maxRadius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    RowLayout {
                        id: showCavaRow
                        anchors.fill: parent; anchors.margins: 16
                        spacing: 16
                        MaterialSymbol { text: "equalizer"; iconSize: 24; color: Appearance.colors.colPrimary }
                        StyledText { text: "Show Cava Visualizer"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                        AndroidToggle {
                            checked: Config.ready && Config.options.lock.showCava
                            onToggled: if(Config.ready) Config.options.lock.showCava = !Config.options.lock.showCava
                        }
                    }
                }

                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: showMediaRow.implicitHeight + 32
                    orientation: Qt.Vertical
                    maxRadius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    RowLayout {
                        id: showMediaRow
                        anchors.fill: parent; anchors.margins: 16
                        spacing: 16
                        MaterialSymbol { text: "movie"; iconSize: 24; color: Appearance.colors.colPrimary }
                        StyledText { text: "Show Media Controls"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                        AndroidToggle {
                            checked: Config.ready && Config.options.lock.showMediaCard
                            onToggled: if(Config.ready) Config.options.lock.showMediaCard = !Config.options.lock.showMediaCard
                        }
                    }
                }
            }
        }

        // ── Status Bar Section ──
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 12
            spacing: 16

            // Computed: background is active (style > 0)
            readonly property bool sbBgActive: Config.ready && Config.options.statusBar
                ? (Config.options.statusBar.backgroundStyle ?? 0) > 0
                : false
            // Gradient is active: only when bg is None + useGradient = true
            readonly property bool sbGradientActive: !sbBgActive
                && (Config.ready && Config.options.statusBar ? Config.options.statusBar.useGradient : true)

            // Section Header
            RowLayout {
                spacing: 12
                Layout.bottomMargin: 4
                MaterialSymbol {
                    text: "view_compact"
                    iconSize: 24
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: "Status Bar"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }
            }

            ColumnLayout {
                id: sbSettingsCol
                Layout.fillWidth: true
                spacing: 4

                // ── Text color mode (disabled when bg is active) ────────────
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: statusBarTextRow.implicitHeight + 36
                    orientation: Qt.Vertical
                    maxRadius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    opacity: parent.parent.sbBgActive ? 0.4 : 1.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    RowLayout {
                        id: statusBarTextRow
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 16
                        MaterialSymbol { text: "palette"; iconSize: 24; color: Appearance.colors.colPrimary }
                        StyledText { text: "Text color"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                        RowLayout {
                            spacing: 2
                            Repeater {
                                model: [
                                    { id: "adaptive", label: "Adaptive" },
                                    { id: "light",    label: "Light" },
                                    { id: "dark",     label: "Dark" }
                                ]
                                delegate: SegmentedButton {
                                    required property var modelData
                                    buttonText: modelData.label
                                    enabled: !sbSettingsCol.parent.sbBgActive
                                    isHighlighted: Config.ready && Config.options.statusBar
                                        ? Config.options.statusBar.textColorMode === modelData.id
                                        : modelData.id === "adaptive"
                                    colActive: Appearance.m3colors.m3primary
                                    colActiveText: Appearance.m3colors.m3onPrimary
                                    colInactive: Appearance.m3colors.m3surfaceContainerLow
                                    onClicked: if (Config.ready && Config.options.statusBar && !sbSettingsCol.parent.sbBgActive)
                                        Config.options.statusBar.textColorMode = modelData.id
                                }
                            }
                        }
                    }
                }

                // ── Use Gradient (disabled when bg is active) ──────────────
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: statusBarGradientRow.implicitHeight + 32
                    orientation: Qt.Vertical
                    maxRadius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    opacity: sbSettingsCol.parent.sbBgActive ? 0.4 : 1.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    RowLayout {
                        id: statusBarGradientRow
                        anchors.fill: parent; anchors.margins: 16
                        spacing: 16
                        MaterialSymbol { text: "gradient"; iconSize: 24; color: Appearance.colors.colPrimary }
                        StyledText { text: "Use gradient"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                        AndroidToggle {
                            checked: Config.ready && Config.options.statusBar ? Config.options.statusBar.useGradient : true
                            onToggled: if (Config.ready && Config.options.statusBar && !sbSettingsCol.parent.sbBgActive)
                                Config.options.statusBar.useGradient = !Config.options.statusBar.useGradient
                        }
                    }
                }

                // ── Background Style (None / Always / Adaptive) ────────────
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: statusBarBgRow.implicitHeight + 36
                    orientation: Qt.Vertical
                    maxRadius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    RowLayout {
                        id: statusBarBgRow
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 16
                        MaterialSymbol { text: "rectangle"; iconSize: 24; color: Appearance.colors.colPrimary }
                        StyledText { text: "Background"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                        RowLayout {
                            spacing: 2
                            Repeater {
                                model: [
                                    { val: 0, label: "None" },
                                    { val: 1, label: "Always" },
                                    { val: 2, label: "Adaptive" }
                                ]
                                delegate: SegmentedButton {
                                    required property var modelData
                                    buttonText: modelData.label
                                    isHighlighted: Config.ready && Config.options.statusBar
                                        ? Config.options.statusBar.backgroundStyle === modelData.val
                                        : modelData.val === 0
                                    colActive: Appearance.m3colors.m3primary
                                    colActiveText: Appearance.m3colors.m3onPrimary
                                    colInactive: Appearance.m3colors.m3surfaceContainerLow
                                    onClicked: if (Config.ready && Config.options.statusBar)
                                        Config.options.statusBar.backgroundStyle = modelData.val
                                }
                            }
                        }
                    }
                }

                // ── Corner Radius (only visible when background is active) ──
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: sbCornerRow.implicitHeight + 32
                    orientation: Qt.Vertical
                    maxRadius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    visible: sbSettingsCol.parent.sbBgActive
                    RowLayout {
                        id: sbCornerRow
                        anchors.fill: parent; anchors.margins: 16
                        spacing: 16
                        MaterialSymbol { text: "rounded_corner"; iconSize: 24; color: Appearance.colors.colPrimary }
                        StyledText { text: "Corner radius"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 0; to: 40; stepSize: 1
                            value: Config.ready && Config.options.statusBar ? (Config.options.statusBar.backgroundCornerRadius ?? 20) : 20
                            onMoved: if (Config.ready && Config.options.statusBar)
                                Config.options.statusBar.backgroundCornerRadius = Math.round(value)
                        }
                        StyledText {
                            text: Math.round(Config.ready && Config.options.statusBar
                                ? (Config.options.statusBar.backgroundCornerRadius ?? 20) : 20).toString() + "px"
                            color: Appearance.colors.colOnLayer1
                        }
                    }
                }

                // ── Workspace count ──────────────────────────────────────────
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: sbWorkspaceRow.implicitHeight + 32
                    orientation: Qt.Vertical
                    maxRadius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    RowLayout {
                        id: sbWorkspaceRow
                        anchors.fill: parent; anchors.margins: 16
                        spacing: 16
                        MaterialSymbol { text: "grid_view"; iconSize: 24; color: Appearance.colors.colPrimary }
                        StyledText { text: "Workspace count"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                        RowLayout {
                            spacing: 8
                            M3IconButton {
                                iconName: "remove"
                                iconSize: 18
                                implicitWidth: 32; implicitHeight: 32
                                buttonRadius: 16
                                colBackground: Appearance.m3colors.m3surfaceContainerLow
                                color: Appearance.m3colors.m3primary
                                onClicked: {
                                    if (Config.ready && Config.options.workspaces) {
                                        let val = Config.options.workspaces.max_shown ?? 5
                                        if (val > 1) Config.options.workspaces.max_shown = val - 1
                                    }
                                }
                            }
                            StyledText {
                                text: (Config.ready && Config.options.workspaces ? (Config.options.workspaces.max_shown ?? 5) : 5).toString()
                                color: Appearance.colors.colOnLayer1
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                Layout.preferredWidth: 30
                                horizontalAlignment: Text.AlignHCenter
                            }
                            M3IconButton {
                                iconName: "add"
                                iconSize: 18
                                implicitWidth: 32; implicitHeight: 32
                                buttonRadius: 16
                                colBackground: Appearance.m3colors.m3surfaceContainerLow
                                color: Appearance.m3colors.m3primary
                                onClicked: {
                                    if (Config.ready && Config.options.workspaces) {
                                        let val = Config.options.workspaces.max_shown ?? 5
                                        if (val < 20) Config.options.workspaces.max_shown = val + 1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Screen Decor Section ──
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 12
            spacing: 16

            RowLayout {
                spacing: 12
                Layout.bottomMargin: 4
                MaterialSymbol {
                    text: "desktop_windows"
                    iconSize: 24
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: "Screen Decor"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: screenCornerToggleRow.implicitHeight + 36
                    orientation: Qt.Vertical
                    maxRadius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    RowLayout {
                        id: screenCornerToggleRow
                        anchors.fill: parent; anchors.margins: 16
                        spacing: 16
                        MaterialSymbol { text: "rounded_corner"; iconSize: 24; color: Appearance.colors.colPrimary }
                        StyledText { text: "Rounded screen corners"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                        RowLayout {
                            spacing: 2
                            Repeater {
                                model: [
                                    { val: 0, label: "Off" },
                                    { val: 1, label: "Adaptive" },
                                    { val: 2, label: "Always" }
                                ]
                                delegate: SegmentedButton {
                                    required property var modelData
                                    buttonText: modelData.label
                                    isHighlighted: Config.ready && (Config.options.appearance.screenCorners?.mode ?? 1) === modelData.val
                                    colActive: Appearance.m3colors.m3primary
                                    colActiveText: Appearance.m3colors.m3onPrimary
                                    colInactive: Appearance.m3colors.m3surfaceContainerLow
                                    onClicked: if (Config.ready && Config.options.appearance.screenCorners)
                                        Config.options.appearance.screenCorners.mode = modelData.val
                                }
                            }
                        }
                    }
                }

                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: screenCornerRadRow.implicitHeight + 32
                    orientation: Qt.Vertical
                    maxRadius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    visible: Config.ready && (Config.options.appearance.screenCorners?.mode ?? 1) > 0
                    RowLayout {
                        id: screenCornerRadRow
                        anchors.fill: parent; anchors.margins: 16
                        spacing: 16
                        MaterialSymbol { text: "straighten"; iconSize: 24; color: Appearance.colors.colPrimary }
                        StyledText { text: "Corner radius"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                        StyledSlider {
                            Layout.preferredWidth: 160
                            from: 0; to: 100; stepSize: 1
                            value: Config.ready && Config.options.appearance.screenCorners ? Config.options.appearance.screenCorners.radius : 20
                            onMoved: if (Config.ready && Config.options.appearance.screenCorners)
                                Config.options.appearance.screenCorners.radius = Math.round(value)
                        }
                        StyledText {
                            text: Math.round(Config.ready && Config.options.appearance.screenCorners ? Config.options.appearance.screenCorners.radius : 20).toString() + "px"
                            color: Appearance.colors.colOnLayer1
                        }
                    }
                }
            }
        }

        // ── Typography Section ──

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 12
            spacing: 16
            
            RowLayout {
                spacing: 12
                Layout.bottomMargin: 4
                MaterialSymbol {
                    text: "font_download"
                    iconSize: 24
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: "Typography"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
            }
            
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 24
                columnSpacing: 24
                
                property var fontOptions: ["Google Sans Flex", "Google Sans Mono", "Cantarell", "JetBrainsMono Nerd Font", "FantasqueSansM Nerd Font", "Inter", "Roboto", "Outfit", "Lexend", "Cascadia Code", "Iosevka", "Public Sans"]

                ColumnLayout {
                    id: mainComboContainer
                    Layout.fillWidth: true
                    spacing: 8
                    z: mainCombo.isOpened ? 10 : 1
                    StyledText { text: "Main Font"; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                    StyledComboBox {
                        id: mainCombo
                        Layout.fillWidth: true
                        text: Config.options.appearance.fonts.main
                        model: parent.parent.fontOptions
                        onAccepted: (val) => Config.options.appearance.fonts.main = val
                    }
                }
                
                ColumnLayout {
                    id: titleComboContainer
                    Layout.fillWidth: true
                    spacing: 8
                    z: titleCombo.isOpened ? 10 : 1
                    StyledText { text: "Title Font"; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                    StyledComboBox {
                        id: titleCombo
                        Layout.fillWidth: true
                        text: Config.options.appearance.fonts.title
                        model: parent.parent.fontOptions
                        onAccepted: (val) => Config.options.appearance.fonts.title = val
                    }
                }
                
                ColumnLayout {
                    id: numbersComboContainer
                    Layout.fillWidth: true
                    spacing: 8
                    z: numbersCombo.isOpened ? 10 : 1
                    StyledText { text: "Numbers Font"; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                    StyledComboBox {
                        id: numbersCombo
                        Layout.fillWidth: true
                        text: Config.options.appearance.fonts.numbers
                        model: parent.parent.fontOptions
                        onAccepted: (val) => Config.options.appearance.fonts.numbers = val
                    }
                }
                
                ColumnLayout {
                    id: monoComboContainer
                    Layout.fillWidth: true
                    spacing: 8
                    z: monoCombo.isOpened ? 10 : 1
                    StyledText { text: "Monospace Font"; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                    StyledComboBox {
                        id: monoCombo
                        Layout.fillWidth: true
                        text: Config.options.appearance.fonts.monospace
                        model: parent.parent.fontOptions
                        onAccepted: (val) => Config.options.appearance.fonts.monospace = val
                    }
                }
            }
        }

        // ── Date & Time Section ──
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 12
            spacing: 16
            
            RowLayout {
                spacing: 12
                Layout.bottomMargin: 4
                MaterialSymbol {
                    text: "schedule"
                    iconSize: 24
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: "Date & Time"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                // Time Format Card
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: timeRow.implicitHeight + 36
                    orientation: Qt.Vertical
                    maxRadius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    
                    RowLayout {
                        id: timeRow
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20
                        
                        StyledText {
                            text: "Time Format"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            spacing: 4
                            Layout.preferredHeight: 52
                            
                            Repeater {
                                model: [
                                    { label: "12H pm", value: "12H_pm" },
                                    { label: "12H PM", value: "12H_PM" },
                                    { label: "24H",    value: "24H" }
                                ]
                                delegate: SegmentedButton {
                                    required property var modelData
                                    isHighlighted: Config.ready && Config.options.time ? Config.options.time.timeStyle === modelData.value : false
                                    Layout.fillHeight: true
                                    
                                    buttonText: modelData.label
                                    leftPadding: 20
                                    rightPadding: 20
                                    
                                    colInactive: Appearance.m3colors.m3surfaceContainerLow
                                    colActive: Appearance.m3colors.m3primary
                                    colActiveText: Appearance.m3colors.m3onPrimary
                                    
                                    onClicked: if(Config.ready) Config.options.time.timeStyle = modelData.value
                                }
                            }
                        }
                    }
                }

                // Date Format Card
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: dateRow.implicitHeight + 36
                    orientation: Qt.Vertical
                    maxRadius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    
                    RowLayout {
                        id: dateRow
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20
                        
                        StyledText {
                            text: "Date Format"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            spacing: 4
                            Layout.preferredHeight: 52
                            
                            Repeater {
                                model: [
                                    { label: "DD/MM/YYYY", value: "DMY" },
                                    { label: "MM/DD/YYYY", value: "MDY" },
                                    { label: "YYYY/MM/DD", value: "YMD" }
                                ]
                                delegate: SegmentedButton {
                                    required property var modelData
                                    isHighlighted: Config.ready && Config.options.time ? Config.options.time.dateStyle === modelData.value : false
                                    Layout.fillHeight: true
                                    
                                    buttonText: modelData.label
                                    leftPadding: 20
                                    rightPadding: 20
                                    
                                    colInactive: Appearance.m3colors.m3surfaceContainerLow
                                    colActive: Appearance.m3colors.m3primary
                                    colActiveText: Appearance.m3colors.m3onPrimary
                                    
                                    onClicked: if(Config.ready) Config.options.time.dateStyle = modelData.value
                                }
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true; Layout.preferredHeight: 32 }
    }
}

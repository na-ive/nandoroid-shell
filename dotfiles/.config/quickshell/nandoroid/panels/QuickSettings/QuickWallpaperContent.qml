import "../../core"
import "../../services"
import "../../widgets"
import "../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

/**
 * High-fidelity Wallpaper & Setting panel.
 * Perfectly mirrors WallpaperStyleSettings with advanced clipping.
 */
Item {
    id: root
    implicitWidth: 1000
    implicitHeight: 750

    focus: true
    Keys.onEscapePressed: close()

    signal closed()

    function close() { root.closed(); }

    Connections {
        target: GlobalStates
        function onQuickWallpaperOpenChanged() {
            if (GlobalStates.quickWallpaperOpen) {
                root.forceActiveFocus();
            }
        }
    }

    // Auto-refresh previews when wallpaper changes
    Connections {
        target: (Config.ready && Config.options.appearance) ? Config.options.appearance.background : null
        function onWallpaperPathChanged() { refreshPreviews(); }
    }

    Connections {
        target: (Config.ready && Config.options.lock) ? Config.options.lock : null
        function onWallpaperPathChanged() { if (Config.options.lock.useSeparateWallpaper) refreshPreviews(); }
    }

    Component.onCompleted: {
        if (GlobalStates.quickWallpaperOpen) {
            root.forceActiveFocus();
        }
        refreshPreviews();
    }

    readonly property var matugenSchemes: [
        { id: "scheme-content",      name: "Content" },
        { id: "scheme-expressive",   name: "Expressive" },
        { id: "scheme-fidelity",     name: "Fidelity" },
        { id: "scheme-fruit-salad",  name: "Fruit Salad" },
        { id: "scheme-monochrome",   name: "Monochrome" },
        { id: "scheme-neutral",      name: "Neutral" },
        { id: "scheme-rainbow",      name: "Rainbow" },
        { id: "scheme-tonal-spot",   name: "Tonal Spot" }
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

    function sendNotification(title, body) {
        const iconPath = Directories.home.replace("file://", "") + "/.config/quickshell/nandoroid/assets/icons/NAnDoroid.svg";
        const cmd = [
            "notify-send",
            "-a", "NAnDoroid",
            "-i", iconPath,
            title,
            body
        ];
        Quickshell.execDetached(cmd);
    }

    Process {
        id: previewMatugen
        command: ["bash", "-c", `matugen -c ~/.config/matugen/config.toml -t "$1" -m "$2" image "$3" --dry-run -j hex --old-json-output --source-color-index 0`, "matugen", currentScheme, (Config.options.appearance.background.darkmode ? "dark" : "light"), currentPath]
        property string currentScheme: ""
        property string currentPath: ""
        property string currentSource: ""
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.includes("Error:") || this.text.includes("Invalid")) {

                    root.sendNotification("Preview Error", "Failed to generate preview for this wallpaper.");
                }
            }
        }
        
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const rawText = this.text.trim();
                    const jsonStart = rawText.indexOf("{");
                    const jsonEnd = rawText.lastIndexOf("}");
                    if (jsonStart !== -1 && jsonEnd !== -1) {
                        const data = JSON.parse(rawText.substring(jsonStart, jsonEnd + 1));
                        const mode = Config.options.appearance.background.darkmode ? "dark" : "light";
                        const colors = [
                            data.colors.primary[mode] || data.colors.primary.default, 
                            data.colors.secondary[mode] || data.colors.secondary.default, 
                            data.colors.tertiary[mode] || data.colors.tertiary.default
                        ];
                        root.pendingPreviews[previewMatugen.currentSource + "_" + previewMatugen.currentScheme] = colors;
                        batchUpdateTimer.restart();
                    }
                } catch(e) {

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
            if (!Config.ready) { previewIterateTimer.start(); return; }
            if (previewIndex >= matugenSchemes.length) {
                if (previewSource === "desktop" && Config.options.lock.useSeparateWallpaper) {
                    previewSource = "lockscreen";
                    previewIndex = 0;
                } else return;
            }
            const scheme = matugenSchemes[previewIndex].id;
            const path = (previewSource === "lockscreen") ? Config.options.lock.wallpaperPath : Config.options.appearance.background.wallpaperPath;
            if (!path) { previewIndex++; previewIterateTimer.start(); return; }
            const cleanPath = path.toString().startsWith("file://") ? path.toString().substring(7) : path.toString();
            if (cleanPath === "") { previewIndex++; previewIterateTimer.start(); return; }
            previewMatugen.currentScheme = scheme;
            previewMatugen.currentPath = cleanPath;
            previewMatugen.currentSource = previewSource;
            previewMatugen.running = true;
            previewIndex++;
        }
    }

    function refreshPreviews() { if (Config.ready) { previewIndex = 0; previewSource = "desktop"; previewIterateTimer.restart(); } }

    // ── Components ──

    component ColorCard: RippleButton {
        id: card
        property string label: ""
        property var cardColors: ["transparent", "transparent", "transparent"]
        property bool isSelected: false
        
        implicitWidth: 104
        implicitHeight: 120
        buttonRadius: 28
        colBackground: Appearance.colors.colLayer2
        colRipple: Appearance.colors.colLayer2Active

        contentItem: Item {
            anchors.fill: parent
            
            // Masking like in WallpaperStyleSettings
            Rectangle {
                id: cardContent
                anchors.fill: parent
                radius: card.buttonRadius
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
                
                Rectangle {
                    anchors.bottom: parent.bottom; width: parent.width; height: 48
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 1.0; color: Qt.rgba(0,0,0,0.6) }
                    }
                }
            }
            
            Rectangle {
                anchors.fill: parent; color: "transparent"; border.width: 3; border.color: Appearance.m3colors.m3primary
                radius: card.buttonRadius; visible: card.isSelected; opacity: 0.8
            }
            
            StyledText {
                anchors.bottom: parent.bottom; anchors.bottomMargin: 8; anchors.horizontalCenter: parent.horizontalCenter
                text: card.label; font.pixelSize: Appearance.font.pixelSize.smaller; font.weight: Font.Medium; color: "white"
                horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; width: parent.width - 12
                lineHeight: 0.9; maximumLineCount: 2
            }
            
            Rectangle {
                anchors.centerIn: parent; width: 32; height: 32; radius: 16; color: "#1A1C1E"; visible: card.isSelected
                MaterialSymbol { anchors.centerIn: parent; text: "check"; iconSize: 20; color: "white" }
            }
        }
    }

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
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.toggled() }
    }

    component WallpaperPreview: ColumnLayout {
        id: previewComp
        property string title; property string source; property bool showCheckmark: false; property bool clickable: true
        signal clicked()
        spacing: 12
        Item {
            Layout.fillWidth: true; 
            Layout.preferredHeight: width * 9/16
            Rectangle {
                id: imgContainer
                anchors.fill: parent; radius: 24; color: Appearance.colors.colLayer1
                
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: imgContainer.width
                        height: imgContainer.height
                        radius: imgContainer.radius
                    }
                }

                Image { 
                    anchors.fill: parent; source: previewComp.source; fillMode: Image.PreserveAspectCrop; asynchronous: true
                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }
                
                Rectangle { anchors.fill: parent; color: Appearance.colors.colPrimary; opacity: previewComp.showCheckmark ? 0.3 : 0 }
                
                Rectangle {
                    width: 42; height: 42; radius: 21; anchors.centerIn: parent; color: Appearance.colors.colPrimary
                    visible: showCheckmark; MaterialSymbol { anchors.centerIn: parent; text: "check"; color: Appearance.colors.colOnPrimary; iconSize: 24 }
                }
                
                MouseArea { anchors.fill: parent; cursorShape: previewComp.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: if(previewComp.clickable) previewComp.clicked() }
            }
        }
        StyledText { Layout.alignment: Qt.AlignHCenter; text: title; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext }
    }

    // ── Layout ──
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Fixed Header (never scrolls) ──
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 16
            Layout.bottomMargin: 12
            Layout.leftMargin: 32
            Layout.rightMargin: 24
            spacing: 16

            ColumnLayout {
                spacing: 4
                StyledText {
                    text: "Wallpaper & Color"
                    font.pixelSize: Appearance.font.pixelSize.huge
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer0
                }
                StyledText {
                    text: "Personalize your device look and feel."
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
                }
            }

            Item { Layout.fillWidth: true }

            RippleButton {
                implicitWidth: 36; implicitHeight: 36; buttonRadius: 18
                colBackground: Appearance.colors.colLayer1
                onClicked: root.closed()
                MaterialSymbol { anchors.centerIn: parent; text: "close"; iconSize: 20 }
            }
        }

        // ── Scrollable Content Area ──
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.bottomMargin: 12
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            color: Appearance.colors.colLayer1
            radius: 20
            clip: true

            StyledFlickable {
                anchors.fill: parent
                contentWidth: width
                contentHeight: mainCol.implicitHeight + 64
                clip: true

                ColumnLayout {
                    id: mainCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 32
                    spacing: 24

                    property bool showAllMatugen: false
                    property bool showAllBasic: false

                    // Sync Card
                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 64; radius: 20; color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 16; spacing: 16
                            MaterialSymbol { text: "sync"; iconSize: 22; color: Appearance.colors.colPrimary }
                            StyledText { text: "Use same wallpaper for lock screen"; font.pixelSize: Appearance.font.pixelSize.normal; Layout.fillWidth: true }
                            AndroidToggle {
                                checked: Config.ready && !Config.options.lock.useSeparateWallpaper
                                onToggled: {
                                    Config.options.lock.useSeparateWallpaper = !Config.options.lock.useSeparateWallpaper;
                                    if (!Config.options.lock.useSeparateWallpaper) Wallpapers.selectForLockscreen(Config.options.appearance.background.wallpaperPath)
                                    refreshPreviews();
                                }
                            }
                        }
                    }

                    // Previews
                    RowLayout {
                        Layout.fillWidth: true; spacing: 20
                        WallpaperPreview {
                            Layout.fillWidth: true; Layout.preferredWidth: 1
                            title: "Desktop wallpaper"
                            source: Config.ready ? Config.options.appearance.background.wallpaperPath : ""
                            onClicked: { GlobalStates.wallpaperSelectorTarget = "desktop"; GlobalStates.wallpaperSelectorOpen = true; }
                        }
                        WallpaperPreview {
                            Layout.fillWidth: true; Layout.preferredWidth: 1
                            title: "Lock screen wallpaper"
                            source: Config.ready ? (Config.options.lock.useSeparateWallpaper ? Config.options.lock.wallpaperPath : Config.options.appearance.background.wallpaperPath) : ""
                            showCheckmark: !Config.options.lock.useSeparateWallpaper
                            clickable: Config.options.lock.useSeparateWallpaper
                            onClicked: { GlobalStates.wallpaperSelectorTarget = "lock"; GlobalStates.wallpaperSelectorOpen = true; }
                        }
                    }

                    // Dark Mode Card
                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 64; radius: 20; color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 16; spacing: 16
                            MaterialSymbol { text: Config.options.appearance.background.darkmode ? "dark_mode" : "light_mode"; iconSize: 22; color: Appearance.colors.colPrimary }
                            StyledText { text: "Dark theme"; font.pixelSize: Appearance.font.pixelSize.normal; Layout.fillWidth: true }
                            AndroidToggle {
                                checked: Config.ready ? Config.options.appearance.background.darkmode : false
                                onToggled: Wallpapers.toggleDarkMode()
                            }
                        }
                    }

                    // Color Settings
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 20

                        RowLayout {
                            id: colorSwitcherRow
                            Layout.fillWidth: true; Layout.preferredHeight: 52; spacing: 4
                            property string currentTab: Config.ready && Config.options.appearance.background && Config.options.appearance.background.matugen ? "wallpaper" : "basic"

                            SegmentedButton {
                                Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.fillHeight: true;
                                isHighlighted: parent.currentTab === "wallpaper"
                                buttonText: "Wallpaper color"
                                font.pixelSize: 14
                                colActive: Appearance.m3colors.m3primary
                                colActiveText: Appearance.m3colors.m3onPrimary
                                colInactive: Appearance.m3colors.m3surfaceContainerHigh
                                colInactiveText: Appearance.m3colors.m3onSurfaceVariant
                                onClicked: parent.currentTab = "wallpaper"
                            }

                            SegmentedButton {
                                Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.fillHeight: true;
                                isHighlighted: parent.currentTab === "basic"
                                buttonText: "Basic color"
                                font.pixelSize: 14
                                colActive: Appearance.m3colors.m3primary
                                colActiveText: Appearance.m3colors.m3onPrimary
                                colInactive: Appearance.m3colors.m3surfaceContainerHigh
                                colInactiveText: Appearance.m3colors.m3onSurfaceVariant
                                onClicked: parent.currentTab = "basic"
                            }
                        }

                        // Matugen Grid
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 16
                            visible: colorSwitcherRow.currentTab === "wallpaper"

                            GridLayout {
                                Layout.fillWidth: true; columns: 5; rowSpacing: 16; columnSpacing: 16

                                Repeater {
                                    model: root.matugenSchemes
                                    delegate: ColorCard {
                                        Layout.fillWidth: true
                                        label: (Config.ready && Config.options.lock.useSeparateWallpaper) ? "Desktop\n" + modelData.name : modelData.name
                                        cardColors: root.matugenPreviews["desktop_" + modelData.id] || [Appearance.m3colors.m3surfaceContainerHigh, Appearance.m3colors.m3surfaceContainerHigh, Appearance.m3colors.m3surfaceContainerHigh]
                                        isSelected: Config.options.appearance.background.matugenScheme === modelData.id && Config.options.appearance.background.matugenSource === "desktop"
                                        onClicked: Wallpapers.applyScheme(modelData.id, "desktop")
                                    }
                                }

                                Repeater {
                                    model: {
                                        if (!(Config.ready && Config.options.lock.useSeparateWallpaper)) return 0;
                                        if (mainCol.showAllMatugen) return root.matugenSchemes;
                                        return root.matugenSchemes.slice(0, 2); // Show 2 more to reach total of 10
                                    }
                                    delegate: ColorCard {
                                        Layout.fillWidth: true
                                        label: "Lockscreen\n" + modelData.name
                                        cardColors: root.matugenPreviews["lockscreen_" + modelData.id] || [Appearance.m3colors.m3surfaceContainerHigh, Appearance.m3colors.m3surfaceContainerHigh, Appearance.m3colors.m3surfaceContainerHigh]
                                        isSelected: Config.options.appearance.background.matugenScheme === modelData.id && Config.options.appearance.background.matugenSource === "lockscreen"
                                        onClicked: Wallpapers.applyScheme(modelData.id, "lockscreen")
                                    }
                                }
                            }

                            // Show More Toggle for Matugen
                            RippleButton {
                                visible: Config.ready && Config.options.lock.useSeparateWallpaper
                                Layout.fillWidth: true
                                Layout.preferredHeight: 48
                                buttonRadius: 16
                                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                                onClicked: mainCol.showAllMatugen = !mainCol.showAllMatugen
                                
                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    MaterialSymbol {
                                        text: mainCol.showAllMatugen ? "expand_less" : "expand_more"
                                        iconSize: 20
                                        color: Appearance.colors.colPrimary
                                    }
                                    StyledText {
                                        text: mainCol.showAllMatugen ? "Show less" : "Show more colors"
                                        font.weight: Font.Medium
                                        color: Appearance.colors.colOnLayer1
                                    }
                                }
                            }
                        }

                        // Basic Colors Grid
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 16
                            visible: colorSwitcherRow.currentTab === "basic"

                            GridLayout {
                                Layout.fillWidth: true; columns: 5; rowSpacing: 16; columnSpacing: 16
                                Repeater {
                                    model: mainCol.showAllBasic ? root.basicColors : root.basicColors.slice(0, 10)
                                    delegate: ColorCard {
                                        Layout.fillWidth: true; label: modelData.name; cardColors: modelData.colors
                                        isSelected: Config.options.appearance.background.matugenThemeFile === modelData.file
                                        onClicked: Wallpapers.applyTheme(modelData.file)
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
                                onClicked: mainCol.showAllBasic = !mainCol.showAllBasic
                                
                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    MaterialSymbol {
                                        text: mainCol.showAllBasic ? "expand_less" : "expand_more"
                                        iconSize: 20
                                        color: Appearance.colors.colPrimary
                                    }
                                    StyledText {
                                        text: mainCol.showAllBasic ? "Show less" : "Show more colors"
                                        font.weight: Font.Medium
                                        color: Appearance.colors.colOnLayer1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

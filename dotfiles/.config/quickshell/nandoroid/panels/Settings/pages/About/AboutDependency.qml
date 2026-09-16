import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Io

/**
 * Dependency Check with pedro style hero and grouped M3 cards.
 * Mirrors AboutUpdate hero so both pages sit as siblings.
 */
ColumnLayout {
    id: dependencyRoot
    // 10px between accordions, like AboutUpdate's release-history section.
    // The hero keeps its 24px gap via its own bottomMargin below.
    spacing: 10 * Appearance.effectiveScale

    readonly property bool isScanning: SysCheckService.isChecking
    readonly property int totalCount: SysCheckService.dependencyData.length
    readonly property int installedCount: SysCheckService.dependencyData.filter(d => d.installed).length
    readonly property int fullMissing: totalCount - installedCount

    // Accordion state: core open by default, others collapsed. Mirrors AboutUpdate version accordions.
    property var expandedCats: ({ "core": true })
    function isExpanded(id) { return !!expandedCats[id]; }
    function toggleCat(id) {
        var m = {};
        for (var k in expandedCats) m[k] = expandedCats[k];
        m[id] = !m[id];
        expandedCats = m;
    }

    // Category defs live on root so the section header can count them,
    // mirroring AboutUpdate's groupDefs/tagList pattern.
    property var categoryDefs: [
        { id: "core", name: I18nService.tr("Core Components (Required)"), icon: "widgets" },
        { id: "services", name: I18nService.tr("System Services"), icon: "dns" },
        { id: "utilities", name: I18nService.tr("Utility Tools"), icon: "build" },
        { id: "theming", name: I18nService.tr("Theming & Appearance"), icon: "palette" },
        { id: "fonts", name: I18nService.tr("Required Fonts"), icon: "font_download" },
        { id: "livewallpaper", name: I18nService.tr("Live Wallpaper Support"), icon: "movie" },
        { id: "optional", name: I18nService.tr("Optional Addons"), icon: "extension" }
    ]

    function scanDependencies() {
        SysCheckService.check();
    }

    // ── Hero (pedro style, like AboutUpdate) ──
    Rectangle {
        id: hero
        Layout.fillWidth: true
        Layout.bottomMargin: 14 * Appearance.effectiveScale
        implicitHeight: heroCol.implicitHeight + (48 * Appearance.effectiveScale)
        radius: 20 * Appearance.effectiveScale
        color: Appearance.m3colors.m3surfaceContainerHigh

        readonly property real s: Appearance.effectiveScale
        readonly property color statusBg: {
            if (dependencyRoot.isScanning)
                return Appearance.colors.colSecondaryContainer;
            if (SysCheckService.missingCount > 0)
                return Appearance.colors.colErrorContainer;
            if (dependencyRoot.fullMissing > 0)
                return Appearance.colors.colTertiaryContainer;
            return Appearance.colors.colPrimaryContainer;
        }
        readonly property color statusFg: {
            if (dependencyRoot.isScanning)
                return Appearance.colors.colOnSecondaryContainer;
            if (SysCheckService.missingCount > 0)
                return Appearance.colors.colOnErrorContainer;
            if (dependencyRoot.fullMissing > 0)
                return Appearance.colors.colOnTertiaryContainer;
            return Appearance.colors.colOnPrimaryContainer;
        }
        readonly property string statusIcon: {
            if (dependencyRoot.isScanning)
                return "sync";
            if (SysCheckService.missingCount > 0)
                return "error";
            if (dependencyRoot.fullMissing > 0)
                return "warning";
            return "check_circle";
        }
        readonly property string statusShort: {
            if (dependencyRoot.isScanning)
                return I18nService.tr("Checking…");
            if (SysCheckService.missingCount > 0)
                return I18nService.tr("%1 missing").arg(SysCheckService.missingCount);
            if (dependencyRoot.fullMissing > 0)
                return I18nService.tr("%1 missing").arg(dependencyRoot.fullMissing);
            return I18nService.tr("Ready");
        }

        ColumnLayout {
            id: heroCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 24 * hero.s
            }
            spacing: 20 * hero.s

            RowLayout {
                Layout.fillWidth: true
                spacing: 20 * hero.s

                MaterialShape {
                    Layout.preferredWidth: 84 * hero.s
                    Layout.preferredHeight: 84 * hero.s
                    Layout.alignment: Qt.AlignVCenter
                    implicitSize: 84 * hero.s
                    shape: MaterialShape.Shape.Flower
                    color: Appearance.colors.colPrimaryContainer
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "account_tree"
                        iconSize: 42 * hero.s
                        color: Appearance.colors.colOnPrimaryContainer
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 8 * hero.s

                    StyledText {
                        text: I18nService.tr("Dependencies")
                        font.pixelSize: 30 * hero.s
                        font.family: Appearance.font.family.title
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnLayer1
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: {
                            if (dependencyRoot.isScanning)
                                return I18nService.tr("Scanning installed components…");
                            if (SysCheckService.missingCount > 0)
                                return I18nService.tr("%1 critical components missing · %2/%3 installed").arg(SysCheckService.missingCount).arg(dependencyRoot.installedCount).arg(dependencyRoot.totalCount);
                            if (dependencyRoot.fullMissing > 0)
                                return I18nService.tr("%1 optional components missing · %2/%3 installed").arg(dependencyRoot.fullMissing).arg(dependencyRoot.installedCount).arg(dependencyRoot.totalCount);
                            if (dependencyRoot.totalCount === 0)
                                return I18nService.tr("Run a scan to check system components.");
                            return I18nService.tr("All critical components installed · %1/%2 total").arg(dependencyRoot.installedCount).arg(dependencyRoot.totalCount);
                        }
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: SysCheckService.missingCount > 0 ? Appearance.colors.colError : Appearance.colors.colSubtext
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignTop
                    implicitWidth: statusPillRow.implicitWidth + 24 * hero.s
                    implicitHeight: 36 * hero.s
                    radius: 18 * hero.s
                    color: hero.statusBg
                    Behavior on color { ColorAnimation { duration: 200 } }

                    RowLayout {
                        id: statusPillRow
                        anchors.centerIn: parent
                        spacing: 6 * hero.s

                        MaterialLoadingIndicator {
                            visible: dependencyRoot.isScanning
                            implicitSize: 16 * hero.s
                        }
                        MaterialSymbol {
                            visible: !dependencyRoot.isScanning
                            text: hero.statusIcon
                            iconSize: 18 * hero.s
                            color: hero.statusFg
                        }
                        StyledText {
                            text: hero.statusShort
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.DemiBold
                            color: hero.statusFg
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1 * hero.s
                color: Appearance.m3colors.m3outlineVariant
                opacity: 0.5
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * hero.s

                RippleButton {
                    Layout.preferredHeight: 44 * hero.s
                    implicitWidth: scanBtnRow.implicitWidth + 32 * hero.s
                    implicitHeight: 44 * hero.s
                    buttonRadius: 22 * hero.s
                    colBackground: SysCheckService.missingCount > 0 ? Appearance.colors.colErrorContainer : Appearance.colors.colPrimary
                    enabled: true
                    onClicked: {
                        if (SysCheckService.isChecking) SysCheckService.cancel();
                        else dependencyRoot.scanDependencies();
                    }

                    RowLayout {
                        id: scanBtnRow
                        anchors.centerIn: parent
                        spacing: 8 * hero.s
                        MaterialSymbol {
                            text: dependencyRoot.isScanning ? "close" : "sync"
                            iconSize: 18 * hero.s
                            color: SysCheckService.missingCount > 0 ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnPrimary
                        }
                        StyledText {
                            text: dependencyRoot.isScanning ? I18nService.tr("Cancel") : I18nService.tr("Scan now")
                            font.weight: Font.Medium
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: SysCheckService.missingCount > 0 ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnPrimary
                        }
                    }
                }

                RippleButton {
                    visible: dependencyRoot.fullMissing > 0 && !dependencyRoot.isScanning
                    Layout.preferredHeight: 44 * hero.s
                    implicitWidth: installAllRow.implicitWidth + 32 * hero.s
                    implicitHeight: 44 * hero.s
                    buttonRadius: 22 * hero.s
                    colBackground: Appearance.colors.colSecondaryContainer
                    onClicked: {
                        var missing = SysCheckService.dependencyData.filter(d => !d.installed).map(d => d.name);
                        if (missing.length > 0)
                            Quickshell.execDetached(["kitty", "--hold", "-e", "paru", "-S", "--needed"].concat(missing));
                    }

                    RowLayout {
                        id: installAllRow
                        anchors.centerIn: parent
                        spacing: 8 * hero.s
                        MaterialSymbol {
                            text: "download"
                            iconSize: 18 * hero.s
                            color: Appearance.colors.colOnSecondaryContainer
                        }
                        StyledText {
                            text: I18nService.tr("Install missing (%1)").arg(dependencyRoot.fullMissing)
                            font.weight: Font.Medium
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnSecondaryContainer
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                StyledText {
                    visible: !dependencyRoot.isScanning && dependencyRoot.totalCount > 0
                    text: I18nService.tr("%1/%2").arg(dependencyRoot.installedCount).arg(dependencyRoot.totalCount)
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }

    // ── 2. Categories (accordions mirror AboutUpdate release history) ──
    RowLayout {
        Layout.fillWidth: true
        visible: dependencyRoot.isScanning
        spacing: 8 * Appearance.effectiveScale

        MaterialLoadingIndicator {
            implicitSize: 20 * Appearance.effectiveScale
        }
        StyledText {
            text: I18nService.tr("Scanning dependencies…")
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
        }
    }

    StyledText {
        visible: !dependencyRoot.isScanning && dependencyRoot.totalCount === 0
        Layout.fillWidth: true
        text: I18nService.tr("No dependency data yet. Press Scan now.")
        font.pixelSize: Appearance.font.pixelSize.small
        color: Appearance.colors.colSubtext
        wrapMode: Text.Wrap
    }

    Repeater {
        model: dependencyRoot.categoryDefs

        delegate: Item {
            id: catItem
            required property var modelData
            readonly property var catItems: SysCheckService.dependencyData.filter(d => d.category === modelData.id)
            readonly property int inst: catItems.filter(d => d.installed).length
            readonly property int miss: catItems.length - inst
            readonly property bool expanded: dependencyRoot.isExpanded(modelData.id)

            visible: catItems.length > 0
            Layout.fillWidth: true
            implicitHeight: catCol.implicitHeight

            ColumnLayout {
                id: catCol
                width: parent.width
                spacing: 0

                RippleButton {
                    id: catHeader
                    Layout.fillWidth: true
                    implicitHeight: 64 * Appearance.effectiveScale
                    buttonRadius: 16 * Appearance.effectiveScale
                    colBackground: catItem.expanded ? Appearance.colors.colLayer1Hover : Appearance.m3colors.m3surfaceContainerHigh
                    onClicked: dependencyRoot.toggleCat(modelData.id)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16 * Appearance.effectiveScale
                        anchors.rightMargin: 12 * Appearance.effectiveScale
                        spacing: 12 * Appearance.effectiveScale

                        MaterialShape {
                            implicitSize: 40 * Appearance.effectiveScale
                            shape: MaterialShape.Shape.Cookie12Sided
                            color: catItem.miss > 0 ? Appearance.colors.colErrorContainer : Appearance.colors.colPrimaryContainer
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: modelData.icon
                                iconSize: 20 * Appearance.effectiveScale
                                color: catItem.miss > 0 ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnPrimaryContainer
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2 * Appearance.effectiveScale
                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.name
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                                elide: Text.ElideRight
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: catItem.miss > 0
                                    ? I18nService.tr("%1/%2 installed, %3 missing").arg(catItem.inst).arg(catItems.length).arg(catItem.miss)
                                    : I18nService.tr("%1/%2 installed").arg(catItem.inst).arg(catItems.length)
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: catItem.miss > 0 ? Appearance.colors.colError : Appearance.colors.colSubtext
                                elide: Text.ElideRight
                            }
                        }

                        MaterialSymbol {
                            text: catItem.expanded ? "expand_less" : "expand_more"
                            iconSize: 20 * Appearance.effectiveScale
                            color: Appearance.colors.colSubtext
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: catItem.expanded
                        color: catHeader.colBackground
                        z: -1
                        radius: 16 * Appearance.effectiveScale
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 16 * Appearance.effectiveScale
                            color: parent.color
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: catItem.expanded ? (depBody.implicitHeight + (32 * Appearance.effectiveScale)) : 0
                    clip: true
                    color: Appearance.colors.colLayer2
                    radius: 16 * Appearance.effectiveScale
                    opacity: catItem.expanded ? 1 : 0
                    visible: Layout.preferredHeight > 0
                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    Rectangle {
                        width: parent.width
                        height: 16 * Appearance.effectiveScale
                        anchors.top: parent.top
                        color: parent.color
                    }

                    ColumnLayout {
                        id: depBody
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 16 * Appearance.effectiveScale
                        }
                        spacing: 10 * Appearance.effectiveScale

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            rowSpacing: 10 * Appearance.effectiveScale
                            columnSpacing: 10 * Appearance.effectiveScale

                            Repeater {
                                model: catItems

                                // Fixed-height cards so every cell stays aligned
                                // in the 2-column grid (no per-row height jumps).
                                delegate: Rectangle {
                                    id: depCard
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    implicitHeight: 64 * Appearance.effectiveScale
                                    radius: 12 * Appearance.effectiveScale
                                    color: cardHover.hovered ? Appearance.colors.colLayer2Hover : Appearance.m3colors.m3surfaceContainerHigh

                                    HoverHandler { id: cardHover }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12 * Appearance.effectiveScale
                                        anchors.rightMargin: 12 * Appearance.effectiveScale
                                        spacing: 10 * Appearance.effectiveScale

                                        MaterialSymbol {
                                            Layout.alignment: Qt.AlignVCenter
                                            text: modelData.installed ? "check_circle" : "cancel"
                                            iconSize: 20 * Appearance.effectiveScale
                                            color: modelData.installed ? Appearance.colors.colPrimary : Appearance.colors.colError
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                            spacing: 2 * Appearance.effectiveScale

                                            StyledText {
                                                Layout.fillWidth: true
                                                text: modelData.name
                                                font.pixelSize: Appearance.font.pixelSize.small
                                                font.weight: Font.DemiBold
                                                color: Appearance.colors.colOnLayer1
                                                elide: Text.ElideRight
                                            }
                                            StyledText {
                                                Layout.fillWidth: true
                                                text: modelData.deprecated ? (modelData.replacement !== "" ? I18nService.tr("Deprecated, use %1 instead").arg(modelData.replacement) : I18nService.tr("Deprecated")) : (modelData.description || I18nService.tr("System dependency"))
                                                font.pixelSize: Appearance.font.pixelSize.smallest
                                                color: modelData.deprecated ? Appearance.colors.colError : Appearance.colors.colSubtext
                                                elide: Text.ElideRight
                                            }
                                        }

                                        StyledText {
                                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                            visible: modelData.installed
                                            text: I18nService.tr("Installed")
                                            color: Appearance.colors.colPrimary
                                            font.weight: Font.Medium
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                        }

                                        RippleButton {
                                            Layout.alignment: Qt.AlignVCenter
                                            visible: !modelData.installed
                                            implicitWidth: installBtnRow.implicitWidth + 24 * Appearance.effectiveScale
                                            implicitHeight: 32 * Appearance.effectiveScale
                                            buttonRadius: 16 * Appearance.effectiveScale
                                            colBackground: Appearance.colors.colPrimary
                                            onClicked: Quickshell.execDetached(["kitty", "--hold", "-e", "paru", "-S", "--needed", modelData.name]);

                                            RowLayout {
                                                id: installBtnRow
                                                anchors.centerIn: parent
                                                spacing: 6 * Appearance.effectiveScale
                                                MaterialSymbol {
                                                    text: "download"
                                                    iconSize: 16 * Appearance.effectiveScale
                                                    color: Appearance.colors.colOnPrimary
                                                }
                                                StyledText {
                                                    text: I18nService.tr("Install")
                                                    font.pixelSize: Appearance.font.pixelSize.small
                                                    font.weight: Font.Medium
                                                    color: Appearance.colors.colOnPrimary
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
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 16 * Appearance.effectiveScale
        visible: !dependencyRoot.isScanning
    }
}

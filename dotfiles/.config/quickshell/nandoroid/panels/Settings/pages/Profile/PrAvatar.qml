import Qt.labs.folderlistmodel
import "../../../../core"
import "../../../../core/functions" as Functions
import "../../../../services"
import "../../../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 0

    FolderListModel {
        id: iconsFolderModel
        folder: Qt.resolvedUrl("../../../../assets/icons")
        showDirs: false
        nameFilters: ["*.svg", "*.png", "*.jpg", "*.webp"]
        onCountChanged: {
            if (iconsFolderModel.status === FolderListModel.Ready) {
                iconSettleTimer.restart();
            }
        }
    }



    Process {
        id: avatarPickerProc
        command: ["bash", "-c", "quickshell -c nandoroid ipc call spotlight browse_avatar"]
    }

    Process {
        id: bannerPickerProc
        command: ["zenity", "--file-selection", "--title=Select Banner Image", "--file-filter=Images | *.png *.jpg *.jpeg *.webp", "--modal"]
        stdout: StdioCollector {
            id: bannerPickerOutput
        }
        onExited: (code) => {
            if (code === 0) {
                const path = bannerPickerOutput.text.trim()
                if (path !== "") {
                    Config.options.profile.bannerImage = path
                }
            }
        }
    }

    Process {
        id: iconPickerProc
        command: ["zenity", "--file-selection", "--title=Select Custom Distro Icon", "--file-filter=Images & SVGs | *.png *.svg *.jpg *.jpeg *.webp", "--modal"]
        stdout: StdioCollector {
            id: iconPickerOutput
        }
        onExited: (code) => {
            if (code === 0) {
                const path = iconPickerOutput.text.trim()
                if (path !== "" && Config.ready && Config.options.bar) {
                    Config.options.bar.distroIcon = path
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2 * Appearance.effectiveScale

        SearchHandler {
            searchString: "Avatar"
            aliases: ["Profile Picture", "User Image", "Avatar Path", "Profile Photo"]
        }

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 8 * Appearance.effectiveScale
            MaterialSymbol {
                text: "person"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: I18nService.tr("Avatar")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }

        SegmentedWrapper {
            id: avatarCard
            Layout.fillWidth: true
            implicitHeight: avatarRow.implicitHeight + (24 * Appearance.effectiveScale)
            orientation: Qt.Vertical
            maxRadius: 20 * Appearance.effectiveScale
            color: Appearance.m3colors.m3surfaceContainerHigh

            RowLayout {
                id: avatarRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                    topMargin: 12 * Appearance.effectiveScale
                    bottomMargin: 12 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                Item {
                    Layout.preferredWidth: 64 * Appearance.effectiveScale
                    Layout.preferredHeight: 64 * Appearance.effectiveScale

                    Image {
                        id: avatarPreview
                        anchors.fill: parent
                        source: {
                            const path = Config.options.profile.avatarPicture
                            if (path && path !== "") return "file://" + path
                            const barPath = Config.options.bar?.avatar_path
                            if (barPath && barPath !== "") return "file://" + barPath
                            if (SystemInfo.userAvatarValid) return "file://" + SystemInfo.userAvatarPath
                            return ""
                        }
                        sourceSize: Qt.size(64 * Appearance.effectiveScale, 64 * Appearance.effectiveScale)
                        fillMode: Image.PreserveAspectCrop
                        visible: false
                    }

                    Rectangle {
                        id: avatarMask
                        anchors.fill: parent
                        radius: width / 2
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: avatarPreview
                        maskSource: avatarMask
                        visible: avatarPreview.status === Image.Ready
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        visible: avatarPreview.status !== Image.Ready
                        text: "person"
                        iconSize: 32 * Appearance.effectiveScale
                        color: Appearance.colors.colSubtext
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2 * Appearance.effectiveScale

                    StyledText {
                        text: I18nService.tr("Avatar Picture")
                        color: Appearance.colors.colOnLayer1
                    }

                    StyledText {
                        text: Config.options.profile.avatarPicture !== ""
                            ? Functions.FileUtils.shortenHomePath(Config.options.profile.avatarPicture)
                            : I18nService.tr("No custom avatar set")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                ColumnLayout {
                    spacing: 8 * Appearance.effectiveScale
                    Layout.alignment: Qt.AlignVCenter

                    RippleButton {
                        implicitWidth: 120 * Appearance.effectiveScale
                        implicitHeight: 36 * Appearance.effectiveScale
                        buttonRadius: 18 * Appearance.effectiveScale
                        colBackground: Appearance.m3colors.m3primaryContainer

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6 * Appearance.effectiveScale
                            MaterialSymbol {
                                text: "folder_open"
                                iconSize: 16 * Appearance.effectiveScale
                                color: Appearance.m3colors.m3onPrimaryContainer
                            }
                            StyledText {
                                text: I18nService.tr("Browse")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.m3colors.m3onPrimaryContainer
                            }
                        }

                        onClicked: {
                            avatarPickerProc.running = true
                        }
                    }

                    Item {
                        implicitWidth: 120 * Appearance.effectiveScale
                        implicitHeight: 36 * Appearance.effectiveScale
                        visible: Config.options.profile.avatarPicture !== ""

                        Rectangle {
                            anchors.fill: parent
                            radius: 18 * Appearance.effectiveScale
                            color: "transparent"
                            border.width: 1 * Appearance.effectiveScale
                            border.color: Appearance.colors.colError
                            opacity: mouseArea.containsMouse ? 0.8 : 1
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6 * Appearance.effectiveScale
                            MaterialSymbol {
                                text: "close"
                                iconSize: 16 * Appearance.effectiveScale
                                color: Appearance.colors.colError
                            }
                            StyledText {
                                text: I18nService.tr("Clear")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colError
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                Config.options.profile.avatarPicture = ""
                                Config.options.bar.avatar_path = ""
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Banner Image ──
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 24 * Appearance.effectiveScale
        spacing: 2 * Appearance.effectiveScale

        SearchHandler {
            searchString: "Banner"
            aliases: ["Banner Image", "Quick Settings Banner", "Cover"]
        }

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 8 * Appearance.effectiveScale
            MaterialSymbol {
                text: "panorama"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: I18nService.tr("Banner Image")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }

        SegmentedWrapper {
            id: bannerCard
            Layout.fillWidth: true
            implicitHeight: bannerRow.implicitHeight + (24 * Appearance.effectiveScale)
            orientation: Qt.Vertical
            maxRadius: 20 * Appearance.effectiveScale
            color: Appearance.m3colors.m3surfaceContainerHigh

            RowLayout {
                id: bannerRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                    topMargin: 12 * Appearance.effectiveScale
                    bottomMargin: 12 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                Item {
                    Layout.preferredWidth: 80 * Appearance.effectiveScale
                    Layout.preferredHeight: 50 * Appearance.effectiveScale

                    Rectangle {
                        anchors.fill: parent
                        radius: 8 * Appearance.effectiveScale
                        color: Appearance.colors.colLayer1
                        clip: true

                        Image {
                            id: bannerPreview
                            anchors.fill: parent
                            source: Config.options.profile.bannerImage !== ""
                                ? "file://" + Config.options.profile.bannerImage
                                : ""
                            sourceSize: Qt.size(160 * Appearance.effectiveScale, 100 * Appearance.effectiveScale)
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                        }

                        OpacityMask {
                            anchors.fill: parent
                            source: bannerPreview
                            maskSource: Rectangle {
                                width: 80 * Appearance.effectiveScale
                                height: 50 * Appearance.effectiveScale
                                radius: 8 * Appearance.effectiveScale
                            }
                            visible: bannerPreview.status === Image.Ready
                        }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            visible: bannerPreview.status !== Image.Ready
                            text: "image"
                            iconSize: 24 * Appearance.effectiveScale
                            color: Appearance.colors.colSubtext
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2 * Appearance.effectiveScale

                    StyledText {
                        text: I18nService.tr("Quick Settings Banner")
                        color: Appearance.colors.colOnLayer1
                    }

                    StyledText {
                        text: Config.options.profile.bannerImage !== ""
                            ? Functions.FileUtils.shortenHomePath(Config.options.profile.bannerImage)
                            : I18nService.tr("Uses current wallpaper")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                ColumnLayout {
                    spacing: 8 * Appearance.effectiveScale
                    Layout.alignment: Qt.AlignVCenter

                    RippleButton {
                        implicitWidth: 120 * Appearance.effectiveScale
                        implicitHeight: 36 * Appearance.effectiveScale
                        buttonRadius: 18 * Appearance.effectiveScale
                        colBackground: Appearance.m3colors.m3primaryContainer

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6 * Appearance.effectiveScale
                            MaterialSymbol {
                                text: "folder_open"
                                iconSize: 16 * Appearance.effectiveScale
                                color: Appearance.m3colors.m3onPrimaryContainer
                            }
                                    StyledText {
                                        text: I18nService.tr("Browse")
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.m3colors.m3onPrimaryContainer
                                    }
                                }

                                onClicked: {
                                    bannerPickerProc.running = true
                                }
                    }

                    Item {
                        implicitWidth: 120 * Appearance.effectiveScale
                        implicitHeight: 36 * Appearance.effectiveScale
                        visible: Config.options.profile.bannerImage !== ""

                        Rectangle {
                            anchors.fill: parent
                            radius: 18 * Appearance.effectiveScale
                            color: "transparent"
                            border.width: 1 * Appearance.effectiveScale
                            border.color: Appearance.colors.colError
                            opacity: bannerClearMouse.containsMouse ? 0.8 : 1
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6 * Appearance.effectiveScale
                            MaterialSymbol {
                                text: "close"
                                iconSize: 16 * Appearance.effectiveScale
                                color: Appearance.colors.colError
                            }
                                StyledText {
                                    text: I18nService.tr("Clear")
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colError
                                }
                            }

                            MouseArea {
                                id: bannerClearMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                Config.options.profile.bannerImage = ""
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Distro Icons Model Batch Loader ──
    property var cachedDistroIcons: []
    property bool distroIconsReady: false

    function updateDistroIconModel() {
        const count = iconsFolderModel.count;
        if (count === 0) return;

        const list = [
            { label: I18nService.tr("Auto"), iconName: "auto_awesome", iconSource: "", value: "" }
        ];

        for (let i = 0; i < count; i++) {
            const fileName = iconsFolderModel.get(i, "fileName");
            if (!fileName || !fileName.includes("-symbolic")) continue;

            const nameWithoutExt = fileName.replace(/\.[^/.]+$/, "");
            let niceLabel = nameWithoutExt.replace(/-symbolic$/i, "");
            niceLabel = niceLabel.charAt(0).toUpperCase() + niceLabel.slice(1);
            if (niceLabel.length > 8) niceLabel = niceLabel.substring(0, 7) + "…";

            list.push({
                label: niceLabel,
                iconName: "",
                iconSource: nameWithoutExt,
                value: nameWithoutExt
            });
        }

        list.push({ label: I18nService.tr("Custom Icon"), iconName: "folder_open", iconSource: "", value: "custom" });
        root.cachedDistroIcons = list;
        root.distroIconsReady = true;
    }

    function isRowFirstItem(idx, totalCount, itemsPerRow) {
        const perRow = itemsPerRow || 16;
        return (idx % perRow) === 0;
    }

    function isRowLastItem(idx, totalCount, itemsPerRow) {
        const perRow = itemsPerRow || 16;
        const posInRow = idx % perRow;
        const remainingInList = totalCount - idx;
        return (posInRow === perRow - 1) || (remainingInList === 1);
    }

    Timer {
        id: iconSettleTimer
        interval: 150
        running: true
        repeat: false
        onTriggered: root.updateDistroIconModel()
    }

    Component.onCompleted: {
        iconSettleTimer.start();
    }

    // ── Custom Distro Icon ──
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 24 * Appearance.effectiveScale
        spacing: 2 * Appearance.effectiveScale

        SearchHandler {
            searchString: "Distro Icon"
            aliases: ["Icon", "Linux", "OS Icon", "Logo"]
        }

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 8 * Appearance.effectiveScale
            MaterialSymbol {
                text: "computer"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: I18nService.tr("Distro Icon")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }

        SegmentedWrapper {
            id: distroCard
            Layout.fillWidth: true
            implicitHeight: distroMainCol.implicitHeight + (24 * Appearance.effectiveScale)
            Behavior on implicitHeight {
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }
            orientation: Qt.Vertical
            maxRadius: 20 * Appearance.effectiveScale
            color: Appearance.m3colors.m3surfaceContainerHigh

            ColumnLayout {
                id: distroMainCol
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                    topMargin: 12 * Appearance.effectiveScale
                    bottomMargin: 12 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16 * Appearance.effectiveScale

                    Item {
                        Layout.preferredWidth: 48 * Appearance.effectiveScale
                        Layout.preferredHeight: 48 * Appearance.effectiveScale

                        Rectangle {
                            anchors.fill: parent
                            radius: 12 * Appearance.effectiveScale
                            color: Appearance.colors.colLayer1

                            CustomIcon {
                                anchors.centerIn: parent
                                width: 28 * Appearance.effectiveScale
                                height: 28 * Appearance.effectiveScale
                                source: {
                                    if (!Config.ready || !Config.options.bar) return SystemInfo.distroIcon || "linux-symbolic";
                                    let custom = Config.options.bar.distroIcon;
                                    return (custom && custom !== "") ? custom : (SystemInfo.distroIcon || "linux-symbolic");
                                }
                                colorize: true
                                color: Appearance.colors.colPrimary
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2 * Appearance.effectiveScale

                        StyledText {
                            text: I18nService.tr("Status Bar Distro Icon")
                            color: Appearance.colors.colOnLayer1
                        }

                        StyledText {
                            text: {
                                if (!Config.ready || !Config.options.bar) return I18nService.tr("Auto-detect")
                                const current = Config.options.bar.distroIcon || ""
                                if (current === "") return I18nService.tr("Auto-detect (") + (SystemInfo.distroIcon || "linux-symbolic") + ")"
                                return Functions.FileUtils.shortenHomePath(current)
                            }
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    RowLayout {
                        spacing: 8 * Appearance.effectiveScale
                        Layout.alignment: Qt.AlignVCenter
                        visible: {
                            if (!root.distroIconsReady || !Config.ready || !Config.options.bar) return false
                            const cur = Config.options.bar.distroIcon || ""
                            if (cur === "") return false
                            for (let i = 0; i < root.cachedDistroIcons.length; i++) {
                                if (root.cachedDistroIcons[i].value === cur) return false
                            }
                            return true
                        }

                        RippleButton {
                            implicitWidth: 110 * Appearance.effectiveScale
                            implicitHeight: 36 * Appearance.effectiveScale
                            buttonRadius: 18 * Appearance.effectiveScale
                            colBackground: Appearance.m3colors.m3primaryContainer

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6 * Appearance.effectiveScale
                                MaterialSymbol {
                                    text: "folder_open"
                                    iconSize: 16 * Appearance.effectiveScale
                                    color: Appearance.m3colors.m3onPrimaryContainer
                                }
                            StyledText {
                                text: I18nService.tr("Browse")
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.m3colors.m3onPrimaryContainer
                                }
                            }

                            onClicked: {
                                iconPickerProc.running = true
                            }
                        }
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 2 * Appearance.effectiveScale
                    opacity: root.distroIconsReady ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                    }

                    Repeater {
                        model: root.cachedDistroIcons

                        delegate: SegmentedButton {
                            id: segBtn
                            required property var modelData
                            required property int index

                            forceFirst: root.isRowFirstItem(index, root.cachedDistroIcons.length, 16)
                            forceLast: root.isRowLastItem(index, root.cachedDistroIcons.length, 16)

                            maxRadius: Math.round(21.5 * Appearance.effectiveScale)
                            implicitWidth: Math.round(43 * Appearance.effectiveScale)
                            implicitHeight: Math.round(43 * Appearance.effectiveScale)

                            readonly property bool isCustom: modelData.value === "custom"
                            readonly property bool isCurrentCustom: {
                                if (!Config.ready || !Config.options.bar) return false
                                const cur = Config.options.bar.distroIcon || ""
                                for (let i = 0; i < root.cachedDistroIcons.length; i++) {
                                    if (root.cachedDistroIcons[i].value === cur) return false
                                }
                                return cur !== ""
                            }

                            isHighlighted: {
                                if (!Config.ready || !Config.options.bar) return false
                                if (isCustom) return isCurrentCustom
                                return Config.options.bar.distroIcon === modelData.value
                            }

                            iconName: modelData.iconName || ""
                            iconSource: modelData.iconSource || ""
                            iconSize: Math.round(22 * Appearance.effectiveScale)
                            buttonText: ""

                            leftPadding: 0
                            rightPadding: 0

                            colInactive: Appearance.m3colors.m3surfaceContainerLow
                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary

                            StyledToolTip {
                                text: modelData.label
                                extraVisibleCondition: segBtn.hovered
                            }

                            onClicked: {
                                if (!Config.ready || !Config.options.bar) return
                                if (isCustom) {
                                    iconPickerProc.running = true
                                } else {
                                    Config.options.bar.distroIcon = modelData.value
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 4 * Appearance.effectiveScale

    SearchHandler {
        searchString: "Wallpaper Transition"
        aliases: ["Transition", "Wallpaper Animation", "Animation", "Shader"]
    }

    property var transitionOptions: [
        { name: "Random", value: "random", icon: "shuffle" },
        { name: "None", value: "", icon: "block" },
        { name: "Material Shape", value: "materialshape", icon: "category" },
        { name: "Circle", value: "circleSelect", icon: "circle" },
        { name: "Circle Pit", value: "circlePit", icon: "blur_circular" },
        { name: "Magic", value: "magic", icon: "auto_awesome" },
        { name: "Doom", value: "Doom", icon: "whatshot" },
        { name: "Peel", value: "Peel", icon: "layers" },
        { name: "Fade", value: "transition", icon: "gradient" },
        { name: "Pixelate", value: "pixelate", icon: "grain" },
        { name: "Stripes", value: "stripes", icon: "texture_minus" },
        { name: "CRT", value: "crt", icon: "tv" },
        { name: "Dissolve", value: "dissolve", icon: "blur_on" },
        { name: "Glitch", value: "glitch", icon: "bug_report" },
        { name: "Ripple", value: "ripple", icon: "water" },
        { name: "Shatter", value: "shatter", icon: "broken_image" }
    ]

    function displayForValue(v) {
        if (v === undefined) v = "random";
        for (let i = 0; i < root.transitionOptions.length; i++) {
            if (root.transitionOptions[i].value === v) return root.transitionOptions[i].name;
        }
        return "Random";
    }

    SegmentedWrapper {
        id: transitionCard
        Layout.fillWidth: true
        implicitHeight: Math.max(64 * Appearance.effectiveScale, transitionRow.implicitHeight)
        orientation: Qt.Vertical
        color: Appearance.m3colors.m3surfaceContainerHigh

        RippleButton {
            id: transitionClickArea
            anchors.fill: parent
            colBackground: Appearance.m3colors.m3surfaceContainerHigh
            colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
            buttonRadius: 0
            topLeftRadius: transitionCard.rTopLeft
            topRightRadius: transitionCard.rTopRight
            bottomLeftRadius: transitionCard.rBottomLeft
            bottomRightRadius: transitionCard.rBottomRight

            property real comboClosedAt: 0

            onClicked: {
                if (Date.now() - comboClosedAt < 250) return;
                transitionCombo.isOpened = !transitionCombo.isOpened;
            }

            Connections {
                target: transitionCombo
                function onIsOpenedChanged() {
                    if (!transitionCombo.isOpened) transitionClickArea.comboClosedAt = Date.now();
                }
            }
        }

        RowLayout {
            id: transitionRow
            anchors.fill: parent
            anchors {
                leftMargin: 16 * Appearance.effectiveScale
                rightMargin: 16 * Appearance.effectiveScale
            }
            spacing: 16 * Appearance.effectiveScale

            MaterialSymbol {
                text: "animation"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: I18nService.tr("Wallpaper transition")
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }

            StyledComboBox {
                id: transitionCombo
                Layout.preferredWidth: 220 * Appearance.effectiveScale
                bgRadius: height / 2
                model: root.transitionOptions.map(o => o.name)
                text: Config.ready ? root.displayForValue(Config.options.appearance.background.wallpaperTransition) : "Random"
                onAccepted: (val) => {
                    if (!Config.ready) return;
                    for (let i = 0; i < root.transitionOptions.length; i++) {
                        if (root.transitionOptions[i].name === val) {
                            Config.options.appearance.background.wallpaperTransition = root.transitionOptions[i].value;
                            break;
                        }
                    }
                }
            }
        }
    }
}

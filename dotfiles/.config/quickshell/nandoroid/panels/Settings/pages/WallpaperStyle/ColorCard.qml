import "../../../../core"
import "../../../../widgets"
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

RippleButton {
    id: card
    property string label: ""
    property var cardColors: ["transparent", "transparent", "transparent"]
    property string iconName: ""
    property bool isSelected: false
    
    implicitWidth: 104 * Appearance.effectiveScale
    implicitHeight: 124 * Appearance.effectiveScale
    buttonRadius: 20 * Appearance.effectiveScale
    colBackground: Appearance.m3colors.m3surfaceContainerHigh
    colBackgroundToggled: Appearance.m3colors.m3surfaceContainerHigh
    colRipple: Appearance.colors.colLayer2Active

    readonly property real s: Appearance.effectiveScale

    contentItem: Item {
        anchors.fill: parent

        Item {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -12 * s
            width: 76 * s
            height: 76 * s

            // 3-color swatch (Canvas for proper circle masking)
            Canvas {
                anchors.fill: parent
                visible: card.iconName === "" || card.isSelected

                property var cols: card.cardColors
                onColsChanged: requestPaint()

                onPaint: {
                    var ctx = getContext("2d");
                    var cx = width / 2, cy = height / 2, r = width / 2;

                    ctx.clearRect(0, 0, width, height);

                    var c0 = card.cardColors[0] || "transparent";
                    var c1 = card.cardColors[1] || "transparent";
                    var c2 = card.cardColors[2] || "transparent";

                    // Top half: primary
                    ctx.beginPath();
                    ctx.moveTo(cx, cy);
                    ctx.arc(cx, cy, r, Math.PI, 2 * Math.PI);
                    ctx.closePath();
                    ctx.fillStyle = c0;
                    ctx.fill();

                    // Bottom-left: secondary
                    ctx.beginPath();
                    ctx.moveTo(cx, cy);
                    ctx.arc(cx, cy, r, Math.PI, Math.PI * 0.5, true);
                    ctx.closePath();
                    ctx.fillStyle = c1;
                    ctx.fill();

                    // Bottom-right: tertiary
                    ctx.beginPath();
                    ctx.moveTo(cx, cy);
                    ctx.arc(cx, cy, r, Math.PI * 0.5, 2 * Math.PI, true);
                    ctx.closePath();
                    ctx.fillStyle = c2;
                    ctx.fill();
                }
            }

            // Icon circle (for Accent Picker)
            Rectangle {
                anchors.fill: parent
                visible: card.iconName !== "" && !card.isSelected
                radius: width / 2
                color: Appearance.m3colors.m3surfaceContainerLow

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: card.iconName
                    iconSize: 38 * s
                    color: Appearance.m3colors.m3onSurface
                }
            }

            // Checkmark (selection indicator)
            Rectangle {
                anchors.centerIn: parent
                width: 34 * s
                height: 34 * s
                radius: width / 2
                color: Appearance.m3colors.m3surfaceContainerLowest
                visible: card.isSelected

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "check"
                    iconSize: 20 * s
                    color: Appearance.m3colors.m3onSurface
                }
            }
        }

        // Label
        StyledText {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8 * s
            anchors.horizontalCenter: parent.horizontalCenter
            text: card.label
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.Medium
            color: card.isSelected ? Appearance.m3colors.m3primary : Appearance.colors.colOnLayer1
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            lineHeight: 0.9
            maximumLineCount: 2
            width: parent.width - (12 * s)

            Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }
    }
}

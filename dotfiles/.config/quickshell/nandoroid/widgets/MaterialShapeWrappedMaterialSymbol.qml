import QtQuick
import "../core"
import "."

MaterialShape {
    id: root
    property alias text: symbol.text
    property alias iconSize: symbol.iconSize
    property alias font: symbol.font
    property alias colSymbol: symbol.color
    property alias fill: symbol.fill
    property alias animateChange: symbol.animateChange
    property real padding: 6
    

    color: Appearance.colors.colSecondaryContainer
    colSymbol: Appearance.colors.colOnSecondaryContainer
    shape: MaterialShape.Shape.Clover4Leaf
    implicitSize: Math.max(symbol.implicitWidth, symbol.implicitHeight) + padding * 2

    Behavior on rotation {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    Behavior on scale {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    MaterialSymbol {
        id: symbol
        anchors.centerIn: parent
        color: root.colSymbol
        rotation: 360 - root.rotation
    }
}

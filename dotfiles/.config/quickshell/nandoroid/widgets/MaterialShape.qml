
import "./shapes/material-shapes.js" as MaterialShapes
import QtQuick
import "./shapes"
import Qt5Compat.GraphicalEffects

Item {
    id: root
    
    // Enum definition for Shape types
    enum Shape {
        Circle,
        Square,
        Slanted,
        Arch,
        Fan,
        Arrow,
        SemiCircle,
        Oval,
        Pill,
        Triangle,
        Diamond,
        ClamShell,
        Pentagon,
        Gem,
        Sunny,
        VerySunny,
        Cookie4Sided,
        Cookie6Sided,
        Cookie7Sided,
        Cookie9Sided,
        Cookie12Sided,
        Ghostish,
        Clover4Leaf,
        Clover8Leaf,
        Burst,
        SoftBurst,
        Boom,
        SoftBoom,
        Flower,
        Puffy,
        PuffyDiamond,
        PixelCircle,
        PixelTriangle,
        Bun,
        Heart
    }

    // Map strings to enum values
    readonly property var shapeMap: ({
        "Circle": MaterialShape.Shape.Circle,
        "Square": MaterialShape.Shape.Square,
        "Slanted": MaterialShape.Shape.Slanted,
        "Arch": MaterialShape.Shape.Arch,
        "Fan": MaterialShape.Shape.Fan,
        "Arrow": MaterialShape.Shape.Arrow,
        "SemiCircle": MaterialShape.Shape.SemiCircle,
        "Oval": MaterialShape.Shape.Oval,
        "Pill": MaterialShape.Shape.Pill,
        "Triangle": MaterialShape.Shape.Triangle,
        "Diamond": MaterialShape.Shape.Diamond,
        "ClamShell": MaterialShape.Shape.ClamShell,
        "Pentagon": MaterialShape.Shape.Pentagon,
        "Gem": MaterialShape.Shape.Gem,
        "Sunny": MaterialShape.Shape.Sunny,
        "VerySunny": MaterialShape.Shape.VerySunny,
        "Cookie4Sided": MaterialShape.Shape.Cookie4Sided,
        "Cookie6Sided": MaterialShape.Shape.Cookie6Sided,
        "Cookie7Sided": MaterialShape.Shape.Cookie7Sided,
        "Cookie9Sided": MaterialShape.Shape.Cookie9Sided,
        "Cookie12Sided": MaterialShape.Shape.Cookie12Sided,
        "Ghostish": MaterialShape.Shape.Ghostish,
        "Clover4Leaf": MaterialShape.Shape.Clover4Leaf,
        "Clover8Leaf": MaterialShape.Shape.Clover8Leaf,
        "Burst": MaterialShape.Shape.Burst,
        "SoftBurst": MaterialShape.Shape.SoftBurst,
        "Boom": MaterialShape.Shape.Boom,
        "SoftBoom": MaterialShape.Shape.SoftBoom,
        "Flower": MaterialShape.Shape.Flower,
        "Puffy": MaterialShape.Shape.Puffy,
        "PuffyDiamond": MaterialShape.Shape.PuffyDiamond,
        "PixelCircle": MaterialShape.Shape.PixelCircle,
        "PixelTriangle": MaterialShape.Shape.PixelTriangle,
        "Bun": MaterialShape.Shape.Bun,
        "Heart": MaterialShape.Shape.Heart
    })

    function getShape(str) {
        return shapeMap[str] !== undefined
            ? shapeMap[str]
            : MaterialShape.Shape.Circle // fallback
    }

    // Properties
    property string shapeString
    property var shape: MaterialShape.Shape.Circle
    property var image: null
    property double implicitSize
    property color color: "transparent"
    
    property color borderColor: "transparent"
    property real borderWidth: 0
    
    // Explicitly expose properties expected by ShapeCanvas users if needed
    property bool polygonIsNormalized: true 

    implicitHeight: implicitSize
    implicitWidth: implicitSize

    onShapeStringChanged: {
        if (!shapeString) return
        shape = getShape(shapeString)
    }

    // Calculate roundedPolygon based on shape enum
    property var roundedPolygon: {
        switch (root.shape) {
            case MaterialShape.Shape.Circle: return MaterialShapes.getCircle();
            case MaterialShape.Shape.Square: return MaterialShapes.getSquare();
            case MaterialShape.Shape.Slanted: return MaterialShapes.getSlanted();
            case MaterialShape.Shape.Arch: return MaterialShapes.getArch();
            case MaterialShape.Shape.Fan: return MaterialShapes.getFan();
            case MaterialShape.Shape.Arrow: return MaterialShapes.getArrow();
            case MaterialShape.Shape.SemiCircle: return MaterialShapes.getSemiCircle();
            case MaterialShape.Shape.Oval: return MaterialShapes.getOval();
            case MaterialShape.Shape.Pill: return MaterialShapes.getPill();
            case MaterialShape.Shape.Triangle: return MaterialShapes.getTriangle();
            case MaterialShape.Shape.Diamond: return MaterialShapes.getDiamond();
            case MaterialShape.Shape.ClamShell: return MaterialShapes.getClamShell();
            case MaterialShape.Shape.Pentagon: return MaterialShapes.getPentagon();
            case MaterialShape.Shape.Gem: return MaterialShapes.getGem();
            case MaterialShape.Shape.Sunny: return MaterialShapes.getSunny();
            case MaterialShape.Shape.VerySunny: return MaterialShapes.getVerySunny();
            case MaterialShape.Shape.Cookie4Sided: return MaterialShapes.getCookie4Sided();
            case MaterialShape.Shape.Cookie6Sided: return MaterialShapes.getCookie6Sided();
            case MaterialShape.Shape.Cookie7Sided: return MaterialShapes.getCookie7Sided();
            case MaterialShape.Shape.Cookie9Sided: return MaterialShapes.getCookie9Sided();
            case MaterialShape.Shape.Cookie12Sided: return MaterialShapes.getCookie12Sided();
            case MaterialShape.Shape.Ghostish: return MaterialShapes.getGhostish();
            case MaterialShape.Shape.Clover4Leaf: return MaterialShapes.getClover4Leaf();
            case MaterialShape.Shape.Clover8Leaf: return MaterialShapes.getClover8Leaf();
            case MaterialShape.Shape.Burst: return MaterialShapes.getBurst();
            case MaterialShape.Shape.SoftBurst: return MaterialShapes.getSoftBurst();
            case MaterialShape.Shape.Boom: return MaterialShapes.getBoom();
            case MaterialShape.Shape.SoftBoom: return MaterialShapes.getSoftBoom();
            case MaterialShape.Shape.Flower: return MaterialShapes.getFlower();
            case MaterialShape.Shape.Puffy: return MaterialShapes.getPuffy();
            case MaterialShape.Shape.PuffyDiamond: return MaterialShapes.getPuffyDiamond();
            case MaterialShape.Shape.PixelCircle: return MaterialShapes.getPixelCircle();
            case MaterialShape.Shape.PixelTriangle: return MaterialShapes.getPixelTriangle();
            case MaterialShape.Shape.Bun: return MaterialShapes.getBun();
            case MaterialShape.Shape.Heart: return MaterialShapes.getHeart();
            default: return MaterialShapes.getCircle();
        }
    }

    // The underlying shape canvas
    ShapeCanvas {
        id: canvas
        anchors.fill: parent
        color: root.color
        borderWidth: root.borderWidth
        borderColor: root.borderColor
        roundedPolygon: root.roundedPolygon
        polygonIsNormalized: root.polygonIsNormalized
    }

    // Image overlay with masking
    Loader {
        id: shapeImageLoader
        active: root.image !== null && root.image.toString() !== ""
        anchors.fill: parent
        sourceComponent: Item {
            Image {
                id: imageItem
                anchors.fill: parent
                source: root.image
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                antialiasing: true
                cache: false
                visible: false // Hidden, used as source for OpacityMask
            }

            OpacityMask {
                anchors.fill: parent
                source: imageItem
                maskSource: canvas
            }
        }
    }
}

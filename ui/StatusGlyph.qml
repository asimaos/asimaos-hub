import QtQuick
import QtQuick.Shapes

// Vector status symbol in a filled circle: ok ✓ · warn ! · error ✕ · info i
Item {
    id: glyph
    property string tone: "info"
    property int size: 20
    property color color: Theme.statusColor(tone)
    property color glyphColor: Theme.dark ? "#0E1015" : "#FFFFFF"
    readonly property real stroke: Math.max(1.6, size * 0.115)

    width: size
    height: size

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: glyph.color
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {  // ok: check mark
            strokeColor: glyph.tone === "ok" ? glyph.glyphColor : "transparent"
            strokeWidth: glyph.stroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: glyph.size * 0.29; startY: glyph.size * 0.52
            PathLine { x: glyph.size * 0.44; y: glyph.size * 0.67 }
            PathLine { x: glyph.size * 0.72; y: glyph.size * 0.37 }
        }
        ShapePath {  // error: cross
            strokeColor: glyph.tone === "error" ? glyph.glyphColor : "transparent"
            strokeWidth: glyph.stroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: glyph.size * 0.35; startY: glyph.size * 0.35
            PathLine { x: glyph.size * 0.65; y: glyph.size * 0.65 }
            PathMove { x: glyph.size * 0.65; y: glyph.size * 0.35 }
            PathLine { x: glyph.size * 0.35; y: glyph.size * 0.65 }
        }
        ShapePath {  // warn: exclamation stem
            strokeColor: glyph.tone === "warn" ? glyph.glyphColor : "transparent"
            strokeWidth: glyph.stroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: glyph.size * 0.5; startY: glyph.size * 0.28
            PathLine { x: glyph.size * 0.5; y: glyph.size * 0.56 }
        }
        ShapePath {  // info: i stem
            strokeColor: glyph.tone !== "ok" && glyph.tone !== "error" && glyph.tone !== "warn"
                         ? glyph.glyphColor : "transparent"
            strokeWidth: glyph.stroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: glyph.size * 0.5; startY: glyph.size * 0.47
            PathLine { x: glyph.size * 0.5; y: glyph.size * 0.72 }
        }
    }

    Rectangle {  // warn dot (bottom) / info dot (top)
        visible: glyph.tone !== "ok" && glyph.tone !== "error"
        width: glyph.stroke * 1.15
        height: width
        radius: width / 2
        color: glyph.glyphColor
        x: (glyph.size - width) / 2
        y: glyph.tone === "warn" ? glyph.size * 0.66 : glyph.size * 0.25
    }
    Accessible.ignored: true
}

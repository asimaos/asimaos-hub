import QtQuick
import QtQuick.Shapes

// Circular progress / status ring with a centre slot.
Item {
    id: ring
    property real value: 1.0
    property color color: Theme.ok
    property color trackColor: Theme.track
    property int size: 112
    property int thickness: 10
    default property alias content: centre.data

    implicitWidth: size
    implicitHeight: size
    width: size
    height: size

    Behavior on value { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: ring.trackColor
            strokeWidth: ring.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: ring.size / 2
                centerY: ring.size / 2
                radiusX: (ring.size - ring.thickness) / 2
                radiusY: (ring.size - ring.thickness) / 2
                startAngle: -90
                sweepAngle: 360
            }
        }
        ShapePath {
            strokeColor: ring.color
            strokeWidth: ring.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: ring.size / 2
                centerY: ring.size / 2
                radiusX: (ring.size - ring.thickness) / 2
                radiusY: (ring.size - ring.thickness) / 2
                startAngle: -90
                sweepAngle: 359.9 * Math.min(1, Math.max(0, ring.value))
            }
        }
    }

    Item {
        id: centre
        anchors.fill: parent
    }
}

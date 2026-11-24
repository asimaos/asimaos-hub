import QtQuick
import QtQuick.Shapes

// Small rotating arc used for "working" states.
Item {
    id: spinner
    property int size: 18
    property color color: Theme.accent
    property int thickness: Math.max(2, Math.round(size / 8))

    width: size
    height: size

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: spinner.color
            strokeWidth: spinner.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: spinner.size / 2
                centerY: spinner.size / 2
                radiusX: (spinner.size - spinner.thickness) / 2
                radiusY: (spinner.size - spinner.thickness) / 2
                startAngle: 0
                sweepAngle: 270
            }
        }
    }

    RotationAnimator on rotation {
        running: spinner.visible
        from: 0
        to: 360
        duration: 900
        loops: Animation.Infinite
    }
    Accessible.role: Accessible.Animation
    Accessible.name: qsTr("Working")
}

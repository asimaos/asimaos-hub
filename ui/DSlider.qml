import QtQuick
import QtQuick.Controls.Basic as B

// Slider with a sky-to-blue fill.
B.Slider {
    id: control
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    implicitHeight: 32

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2
        width: control.availableWidth
        height: 6
        radius: 3
        color: Theme.track
        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            radius: 3
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Theme.brandFrom }
                GradientStop { position: 1.0; color: Theme.brandMid }
            }
        }
    }

    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2
        width: 22
        height: 22
        radius: 11
        color: "#FFFFFF"
        border.width: 2
        border.color: Theme.accent
        scale: control.pressed ? 1.12 : 1.0
        Behavior on scale { NumberAnimation { duration: Theme.fast } }
        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: width / 2
            color: "transparent"
            border.width: 2
            border.color: Theme.accent
            opacity: control.visualFocus ? 0.5 : 0
        }
    }
}

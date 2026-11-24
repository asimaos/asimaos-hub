import QtQuick

// Rounded progress bar. tone "accent" uses the sky-to-blue gradient; others use a status colour.
Item {
    id: bar
    property real value: 0
    property string tone: "accent"
    property bool indeterminate: false

    implicitWidth: 200
    implicitHeight: 8
    clip: true

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.track
    }

    Item {
        id: fill
        height: parent.height
        width: bar.indeterminate ? parent.width * 0.3
                                 : Math.max(height, parent.width * Math.min(1, Math.max(0, bar.value)))
        Behavior on width { enabled: !bar.indeterminate; NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            visible: bar.tone === "accent"
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Theme.brandFrom }
                GradientStop { position: 1.0; color: Theme.brandMid }
            }
        }
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            visible: bar.tone !== "accent"
            color: Theme.statusColor(bar.tone)
        }

        SequentialAnimation on x {
            running: bar.indeterminate && bar.visible
            loops: Animation.Infinite
            NumberAnimation { from: -fill.width; to: bar.width; duration: 1300; easing.type: Easing.InOutQuad }
        }
    }
    Accessible.role: Accessible.ProgressBar
}

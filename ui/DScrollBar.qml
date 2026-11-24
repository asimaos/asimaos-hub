import QtQuick
import QtQuick.Controls.Basic as B

// Thin, unobtrusive scrollbar that widens on hover.
B.ScrollBar {
    id: bar
    hoverEnabled: true
    minimumSize: 0.08
    policy: B.ScrollBar.AsNeeded
    implicitWidth: 12
    padding: 3

    contentItem: Rectangle {
        implicitWidth: bar.hovered || bar.pressed ? 6 : 4
        radius: width / 2
        color: bar.pressed ? Theme.textSubtle : Theme.borderStrong
        opacity: bar.policy === B.ScrollBar.AlwaysOn || bar.active ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: Theme.normal } }
        Behavior on implicitWidth { NumberAnimation { duration: Theme.fast } }
    }
    background: Item {}
}

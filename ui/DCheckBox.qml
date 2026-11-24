import QtQuick
import QtQuick.Controls.Basic as B

B.CheckBox {
    id: control
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    spacing: 12
    font.family: Theme.fontFamily
    font.pixelSize: Theme.textMd

    indicator: Rectangle {
        implicitWidth: 22
        implicitHeight: 22
        x: control.leftPadding
        y: (control.height - height) / 2
        radius: 6
        color: control.checked ? Theme.accent : Theme.surface
        border.width: control.checked ? 0 : 2
        border.color: control.visualFocus || control.hovered ? Theme.accent : Theme.borderStrong
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        Icon {
            anchors.centerIn: parent
            visible: control.checked
            name: "checkmark"
            size: 14
            color: "#FFFFFF"
        }
    }

    contentItem: UiText {
        leftPadding: control.indicator.width + control.spacing
        text: control.text
        font.weight: Font.Medium
        wrapMode: Text.WordWrap
        verticalAlignment: Text.AlignVCenter
    }
}

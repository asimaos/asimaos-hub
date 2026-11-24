import QtQuick
import QtQuick.Controls.Basic as B

B.Switch {
    id: control
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    spacing: 10
    font.family: Theme.fontFamily
    font.pixelSize: Theme.textMd

    indicator: Rectangle {
        implicitWidth: 44
        implicitHeight: 24
        x: control.leftPadding
        anchors.verticalCenter: parent.verticalCenter
        radius: height / 2
        color: control.checked ? Theme.accent : Theme.track
        border.width: control.visualFocus ? 2 : 0
        border.color: Theme.accentText
        Behavior on color { ColorAnimation { duration: Theme.normal } }

        Rectangle {
            width: 18
            height: 18
            radius: 9
            y: 3
            x: control.checked ? parent.width - width - 3 : 3
            color: "#FFFFFF"
            Behavior on x { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
        }
    }

    contentItem: UiText {
        leftPadding: control.indicator.width + control.spacing
        text: control.text
        visible: text.length > 0
    }
}

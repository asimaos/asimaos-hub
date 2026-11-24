import QtQuick
import QtQuick.Controls.Basic as B

B.TextField {
    id: field
    property string tone: ""   // "error" shows a red border

    implicitHeight: 42
    leftPadding: 14
    rightPadding: 14
    font.family: Theme.fontFamily
    font.pixelSize: Theme.textMd
    color: Theme.text
    placeholderTextColor: Theme.textSubtle
    selectionColor: Qt.alpha(Theme.accent, 0.35)
    selectedTextColor: Theme.text

    background: Rectangle {
        radius: Theme.radiusM
        color: Theme.surface
        border.width: field.activeFocus ? 2 : 1
        border.color: field.tone === "error" ? Theme.error : field.activeFocus ? Theme.accent : Theme.borderStrong
        Behavior on border.color { ColorAnimation { duration: Theme.fast } }
    }
}

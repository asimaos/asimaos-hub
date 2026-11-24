import QtQuick
import QtQuick.Layouts

// Quick-settings tile: an icon, a name and its current state. "on" tiles fill with the accent colour.
Rectangle {
    id: tile
    property string iconName
    property string title
    property string value
    property bool on: false
    signal clicked()

    implicitWidth: 180
    implicitHeight: 116
    radius: Theme.radiusL
    color: on ? Theme.accent : (mouse.containsMouse ? Theme.surfaceHover : Theme.surface)
    border.width: on ? 0 : 1
    border.color: activeFocus ? Theme.accent : Theme.border
    activeFocusOnTab: true
    Behavior on color { ColorAnimation { duration: Theme.normal } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 2
        Rectangle {
            implicitWidth: 36
            implicitHeight: 36
            radius: 11
            color: tile.on ? Qt.rgba(1, 1, 1, 0.2) : Theme.accentSoft
            Icon {
                anchors.centerIn: parent
                name: tile.iconName
                size: 18
                color: tile.on ? "#FFFFFF" : Theme.accentText
            }
        }
        Item { Layout.fillHeight: true }
        UiText {
            text: tile.title
            font.weight: Font.DemiBold
            color: tile.on ? "#FFFFFF" : Theme.text
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
        UiText {
            text: tile.value
            variant: "small"
            color: tile.on ? Qt.rgba(1, 1, 1, 0.86) : Theme.textMuted
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.clicked()
    }
    Keys.onSpacePressed: tile.clicked()
    Keys.onReturnPressed: tile.clicked()
    Accessible.role: Accessible.Button
    Accessible.name: title + ", " + value
    Accessible.checkable: true
    Accessible.checked: on
}

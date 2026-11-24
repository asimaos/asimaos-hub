import QtQuick

// One entry of the sidebar navigation.
Item {
    id: item
    property string label
    property string iconName
    property bool active: false
    property string badge
    property string badgeTone: "accent"
    signal clicked()

    implicitWidth: 200
    implicitHeight: 40
    activeFocusOnTab: true

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusM
        color: item.active ? Theme.accentSoft : (mouse.containsMouse ? Theme.surfaceHover : "transparent")
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        border.width: item.activeFocus ? 2 : 0
        border.color: Theme.accent
    }

    Rectangle {
        width: 3
        height: item.active ? 18 : 0
        radius: 2
        color: Theme.accent
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        Behavior on height { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12
        Icon {
            name: item.iconName
            size: 18
            color: item.active ? Theme.accentText : Theme.textMuted
            anchors.verticalCenter: parent.verticalCenter
        }
        UiText {
            text: item.label
            color: item.active ? Theme.text : Theme.textMuted
            font.weight: item.active ? Font.DemiBold : Font.Medium
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    StatusPill {
        visible: item.badge.length > 0
        text: item.badge
        tone: item.badgeTone
        dot: false
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: item.clicked()
    }
    Keys.onReturnPressed: item.clicked()
    Keys.onSpacePressed: item.clicked()
    Accessible.role: Accessible.PageTab
    Accessible.name: label
    Accessible.selected: active
}

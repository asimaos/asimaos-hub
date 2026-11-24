import QtQuick
import QtQuick.Layouts

// A row inside a card: icon, title, subtitle, and a value (plain or as a status pill) or trailing items.
Item {
    id: listRow
    property string iconName
    property string iconTone: ""
    property string title
    property string subtitle
    property string value
    property string tone: ""            // set → value is shown as a StatusPill
    property bool separator: true
    default property alias trailing: trailingRow.data

    implicitWidth: 320
    implicitHeight: Math.max(54, layout.implicitHeight + 22)

    RowLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        IconTile {
            visible: listRow.iconName.length > 0 && listRow.iconTone.length > 0
            name: listRow.iconName
            tone: listRow.iconTone
            size: 32
        }
        Icon {
            visible: listRow.iconName.length > 0 && listRow.iconTone.length === 0
            name: listRow.iconName
            size: 18
            color: Theme.textMuted
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            UiText {
                text: listRow.title
                font.weight: Font.Medium
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            UiText {
                visible: text.length > 0
                text: listRow.subtitle
                variant: "small"
                tone: "muted"
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
        UiText {
            visible: listRow.value.length > 0 && listRow.tone.length === 0
            text: listRow.value
            tone: "muted"
        }
        StatusPill {
            visible: listRow.value.length > 0 && listRow.tone.length > 0
            text: listRow.value
            tone: listRow.tone
        }
        RowLayout {
            id: trailingRow
            visible: children.length > 0   // no phantom spacing when empty
            spacing: 8
        }
    }

    Rectangle {
        visible: listRow.separator
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Theme.border
    }
}

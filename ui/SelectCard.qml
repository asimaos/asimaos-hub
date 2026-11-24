import QtQuick
import QtQuick.Layouts

// Large selectable card: radio style (single choice) or check style (multi). A card that can't
// be chosen stays visible, dimmed, with a short label and the reason.
Item {
    id: card
    property string iconName
    property string iconTone: "accent"
    property string title
    property string subtitle
    property string detail
    property bool selected: false
    property bool multi: false
    property bool locked: false                 // always included; shows a pill instead of a check
    property string lockedText: qsTr("Included")
    property string disabledLabel               // short pill, e.g. "Live USB"
    property string disabledReason              // sentence explaining why
    property int padding: 18
    default property alias extra: extraColumn.data
    signal toggled()

    readonly property bool usable: disabledReason.length === 0 && disabledLabel.length === 0

    implicitWidth: 360
    implicitHeight: row.implicitHeight + padding * 2
    activeFocusOnTab: usable && !locked
    opacity: usable ? 1.0 : 0.62

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusL
        color: card.selected ? Theme.accentSoft
             : (mouse.containsMouse && card.usable && !card.locked ? Theme.surfaceHover : Theme.surface)
        border.width: card.selected ? 2 : 1
        border.color: card.selected ? Theme.accent : card.activeFocus ? Theme.accentText : Theme.border
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        Behavior on border.color { ColorAnimation { duration: Theme.fast } }
    }

    RowLayout {
        id: row
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: card.padding
        spacing: 14

        IconTile {
            visible: card.iconName.length > 0
            name: card.iconName
            tone: card.iconTone
            size: 44
            // on a selected (tinted) card the tile needs its own surface to stay visible
            color: card.selected ? Theme.surface : Theme.statusSoft(card.iconTone)
            Layout.alignment: Qt.AlignTop
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            UiText { text: card.title; variant: "heading"; Layout.fillWidth: true; elide: Text.ElideRight }
            UiText {
                visible: text.length > 0
                text: card.subtitle
                variant: "small"
                tone: "muted"
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            UiText {
                visible: text.length > 0
                text: card.disabledReason.length > 0 ? card.disabledReason : card.detail
                variant: "small"
                tone: card.disabledReason.length > 0 ? "warn" : "subtle"
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            ColumnLayout {
                id: extraColumn
                visible: children.length > 0
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 6
            }
        }
        StatusPill {
            visible: card.locked
            text: card.lockedText
            tone: "ok"
            Layout.alignment: Qt.AlignTop
        }
        StatusPill {
            visible: card.disabledLabel.length > 0
            text: card.disabledLabel
            tone: "neutral"
            Layout.alignment: Qt.AlignTop
        }
        Rectangle {
            visible: card.usable && !card.locked
            Layout.alignment: Qt.AlignTop
            implicitWidth: 24
            implicitHeight: 24
            radius: card.multi ? 7 : 12
            color: card.selected ? Theme.accent : "transparent"
            border.width: card.selected ? 0 : 2
            border.color: Theme.borderStrong
            Behavior on color { ColorAnimation { duration: Theme.fast } }
            Icon {
                anchors.centerIn: parent
                visible: card.selected
                name: "checkmark"
                size: 14
                color: "#FFFFFF"
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: card.usable && !card.locked
        cursorShape: Qt.PointingHandCursor
        onClicked: card.toggled()
    }
    Keys.onSpacePressed: card.toggled()
    Keys.onReturnPressed: card.toggled()
    Accessible.role: multi ? Accessible.CheckBox : Accessible.RadioButton
    Accessible.name: title
    Accessible.checked: selected
}

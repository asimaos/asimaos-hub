import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

// Surface for grouped content: optional icon tile, title, subtitle and header actions.
Item {
    id: card
    property string title
    property string subtitle
    property string icon
    property string tone: "accent"
    property int padding: 20
    property bool elevated: true
    property color background: Theme.surface
    property bool clickable: false
    signal clicked()
    default property alias contentData: body.data
    property alias actions: actionRow.data
    property alias spacing: body.spacing

    implicitWidth: 320
    implicitHeight: column.implicitHeight + padding * 2

    // The shadow is its own shape behind the surface: where effects can't run (Qt's software
    // renderer, without a GPU), only the shadow is lost, never the card.
    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusL
        color: card.background
        visible: card.elevated && !Theme.dark
        layer.enabled: visible
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#101828"
            shadowOpacity: 0.07
            shadowBlur: 0.55
            shadowVerticalOffset: 2
            autoPaddingEnabled: true
        }
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: Theme.radiusL
        color: card.background
        border.color: card.clickable && hover.containsMouse ? Theme.borderStrong : Theme.border
        border.width: 1
        Behavior on border.color { ColorAnimation { duration: Theme.fast } }
    }

    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: card.padding
        spacing: 16

        RowLayout {
            visible: card.title.length > 0 || card.icon.length > 0
            Layout.fillWidth: true
            spacing: 12

            IconTile {
                visible: card.icon.length > 0
                name: card.icon
                tone: card.tone
                size: 38
                Layout.alignment: Qt.AlignTop
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                UiText {
                    Layout.fillWidth: true
                    text: card.title
                    variant: "heading"
                    elide: Text.ElideRight
                }
                UiText {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: card.subtitle
                    variant: "small"
                    tone: "muted"
                    wrapMode: Text.WordWrap
                }
            }
            RowLayout {
                id: actionRow
                spacing: 8
                Layout.alignment: Qt.AlignTop
            }
        }

        ColumnLayout {
            id: body
            visible: children.length > 0   // a card with only its header has no empty gap below it
            Layout.fillWidth: true
            spacing: 12
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        enabled: card.clickable
        hoverEnabled: card.clickable
        cursorShape: card.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: card.clicked()
    }
}

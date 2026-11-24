pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic as B

// Drop-down choice. model: [{ id, title, subtitle? }]; use currentValue / indexOfValue(id).
B.ComboBox {
    id: control
    textRole: "title"
    valueRole: "id"
    implicitHeight: 42
    hoverEnabled: true
    leftPadding: 14
    rightPadding: 40
    font.family: Theme.fontFamily
    font.pixelSize: Theme.textMd

    contentItem: UiText {
        text: control.displayText
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }
    indicator: Icon {
        x: control.width - width - 14
        y: (control.height - height) / 2
        name: "arrow-down"
        size: 14
        color: Theme.textMuted
    }
    background: Rectangle {
        radius: Theme.radiusM
        color: control.hovered ? Theme.surfaceHover : Theme.surface
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus ? Theme.accent : Theme.borderStrong
    }
    delegate: B.ItemDelegate {
        id: entry
        required property var modelData
        required property int index
        width: ListView.view ? ListView.view.width : control.width
        height: modelData.subtitle ? 48 : 38
        highlighted: control.highlightedIndex === index
        contentItem: Column {
            spacing: 0
            UiText {
                text: entry.modelData.title
                font.weight: entry.index === control.currentIndex ? Font.DemiBold : Font.Normal
                width: parent.width
                elide: Text.ElideRight
            }
            UiText {
                visible: !!entry.modelData.subtitle
                text: entry.modelData.subtitle || ""
                variant: "caption"
                tone: "muted"
            }
        }
        background: Rectangle {
            radius: Theme.radiusS
            color: entry.highlighted ? Theme.accentSoft : "transparent"
        }
    }
    popup: B.Popup {
        y: control.height + 4
        width: control.width
        height: Math.min(contentItem.implicitHeight + 12, 340)
        padding: 6
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            B.ScrollBar.vertical: DScrollBar {}
        }
        background: Rectangle {
            radius: Theme.radiusM
            color: Theme.surface
            border.width: 1
            border.color: Theme.border
        }
    }
}

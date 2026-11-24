import QtQuick
import QtQuick.Layouts

// Compact metric card: icon + label on top, a large value on its own line, optional bar and caption.
Card {
    id: tile
    property string iconName
    property string iconTone: "accent"
    property string label
    property string value
    property string caption
    property string captionTone: "muted"
    property real progress: -1
    property string progressTone: "accent"

    padding: 18
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        IconTile { name: tile.iconName; tone: tile.iconTone; size: 32 }
        UiText {
            text: tile.label
            variant: "small"
            tone: "muted"
            font.weight: Font.Medium
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
    }
    UiText {
        text: tile.value
        variant: "subtitle"
        Layout.fillWidth: true
        Layout.topMargin: 4
        elide: Text.ElideRight
    }
    DProgressBar {
        visible: tile.progress >= 0
        Layout.fillWidth: true
        value: tile.progress
        tone: tile.progressTone
    }
    UiText {
        visible: text.length > 0
        Layout.fillWidth: true
        text: tile.caption
        variant: "small"
        tone: tile.captionTone
        wrapMode: Text.WordWrap
    }
}

pragma ComponentBehavior: Bound
import QtQuick

// Pill-shaped segmented control with a sliding thumb.
Rectangle {
    id: tabs
    property var options: []
    property int currentIndex: 0
    property int segmentWidth: 150
    signal activated(int index)

    implicitWidth: options.length * segmentWidth + 8
    implicitHeight: 40
    radius: Theme.radiusM + 2
    color: Theme.surfaceAlt
    border.width: 1
    border.color: Theme.border

    Rectangle {
        id: thumb
        x: 4 + tabs.currentIndex * tabs.segmentWidth
        y: 4
        width: tabs.segmentWidth
        height: tabs.height - 8
        radius: Theme.radiusM
        color: Theme.surface
        border.width: Theme.dark ? 1 : 0
        border.color: Theme.borderStrong
        Behavior on x { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
    }

    Row {
        x: 4
        y: 4
        Repeater {
            model: tabs.options
            delegate: Item {
                id: segment
                required property var modelData
                required property int index
                width: tabs.segmentWidth
                height: tabs.height - 8
                UiText {
                    anchors.centerIn: parent
                    text: segment.modelData
                    font.weight: Font.DemiBold
                    color: segment.index === tabs.currentIndex ? Theme.text : Theme.textMuted
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        tabs.currentIndex = segment.index
                        tabs.activated(segment.index)
                    }
                }
                Accessible.role: Accessible.PageTab
                Accessible.name: modelData
            }
        }
    }
}

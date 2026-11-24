pragma ComponentBehavior: Bound
import QtQuick

// Single choice from a few short options. options: ["60 Hz", …] or [{ id, title }].
Flow {
    id: chips
    property var options: []
    property var current
    signal picked(var id)

    spacing: 8

    Repeater {
        model: chips.options
        delegate: Rectangle {
            id: chip
            required property var modelData
            readonly property var oid: typeof modelData === "object" ? modelData.id : modelData
            readonly property string label: typeof modelData === "object" ? modelData.title : String(modelData)
            readonly property bool chosen: oid === chips.current
            height: 34
            width: text.implicitWidth + 28
            radius: 17
            color: chosen ? Theme.accent : (hover.containsMouse ? Theme.surfaceHover : Theme.surface)
            border.width: chosen ? 0 : 1
            border.color: Theme.borderStrong
            Behavior on color { ColorAnimation { duration: Theme.fast } }
            UiText {
                id: text
                anchors.centerIn: parent
                text: chip.label
                font.weight: Font.DemiBold
                color: chip.chosen ? "#FFFFFF" : Theme.text
            }
            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    chips.current = chip.oid
                    chips.picked(chip.oid)
                }
            }
            Accessible.role: Accessible.RadioButton
            Accessible.name: label
            Accessible.checked: chosen
        }
    }
}

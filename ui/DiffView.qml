pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic as B

// Unified diff with added / removed lines tinted.
Rectangle {
    id: view
    property string diff
    property int maxHeight: 340
    readonly property var lines: diff.length ? diff.split("\n") : []

    implicitHeight: Math.min(list.contentHeight + 20, maxHeight)
    radius: Theme.radiusM
    color: Theme.dark ? "#0F1217" : "#FBFBFC"
    border.width: 1
    border.color: Theme.border
    clip: true

    ListView {
        id: list
        anchors.fill: parent
        anchors.margins: 10
        model: view.lines
        boundsBehavior: Flickable.StopAtBounds
        B.ScrollBar.vertical: DScrollBar {}
        delegate: Rectangle {
            id: line
            required property string modelData
            readonly property string kind: modelData.startsWith("+++") || modelData.startsWith("---") ? "file"
                                         : modelData.startsWith("+") ? "add"
                                         : modelData.startsWith("-") ? "del"
                                         : modelData.startsWith("@@") ? "hunk" : "ctx"
            width: list.width
            height: 22
            radius: 4
            color: kind === "add" ? Theme.okSoft : kind === "del" ? Theme.errorSoft : kind === "hunk" ? Theme.infoSoft : "transparent"
            Text {
                anchors.verticalCenter: parent.verticalCenter
                x: 8
                width: parent.width - 16
                text: line.modelData
                elide: Text.ElideRight
                font.family: "Noto Sans Mono"
                font.pixelSize: Theme.textSm
                color: line.kind === "add" ? Theme.ok : line.kind === "del" ? Theme.error
                     : line.kind === "hunk" ? Theme.info : line.kind === "file" ? Theme.textMuted : Theme.text
            }
        }
    }
}

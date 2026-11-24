pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

// Vertical progress steps. steps: [{ title, detail?, state: "done" | "active" | "pending" | "failed" }]
ColumnLayout {
    id: list
    property var steps: []
    spacing: 0

    Repeater {
        model: list.steps
        delegate: Item {
            id: step
            required property var modelData
            required property int index
            readonly property string state_: modelData.state || "pending"
            readonly property bool last: index === list.steps.length - 1

            Layout.fillWidth: true
            implicitHeight: Math.max(48, textColumn.implicitHeight + (last ? 4 : 18))

            // connector to the next step
            Rectangle {
                visible: !step.last
                x: 13
                y: 30
                width: 2
                height: step.height - 30
                radius: 1
                color: step.state_ === "done" ? Theme.ok : Theme.border
            }

            Rectangle {
                id: marker
                width: 28
                height: 28
                radius: 14
                color: step.state_ === "done" ? Theme.ok
                     : step.state_ === "active" ? Theme.accentSoft
                     : step.state_ === "failed" ? Theme.errorSoft
                     : Theme.surfaceAlt
                border.width: step.state_ === "pending" ? 1 : 0
                border.color: Theme.borderStrong

                Icon {
                    anchors.centerIn: parent
                    visible: step.state_ === "done" || step.state_ === "failed"
                    name: step.state_ === "done" ? "dialog-ok-apply" : "dialog-close"
                    size: 14
                    color: step.state_ === "done" ? (Theme.dark ? "#0E1015" : "#FFFFFF") : Theme.error
                }
                Spinner {
                    anchors.centerIn: parent
                    visible: step.state_ === "active"
                    size: 16
                    color: Theme.accent
                }
                UiText {
                    anchors.centerIn: parent
                    visible: step.state_ === "pending"
                    text: step.index + 1
                    variant: "caption"
                    tone: "subtle"
                    font.weight: Font.DemiBold
                }
            }

            ColumnLayout {
                id: textColumn
                anchors.left: marker.right
                anchors.leftMargin: 14
                anchors.right: parent.right
                y: 4
                spacing: 2
                UiText {
                    text: step.modelData.title
                    font.weight: step.state_ === "active" ? Font.DemiBold : Font.Medium
                    tone: step.state_ === "pending" ? "muted" : step.state_ === "failed" ? "error" : "default"
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
                UiText {
                    visible: text.length > 0
                    text: step.modelData.detail || ""
                    variant: "small"
                    tone: "muted"
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}

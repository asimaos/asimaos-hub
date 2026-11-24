pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

// Left rail of a guided flow (installer, rescue): brand header, step list, reassurance footnote.
Rectangle {
    id: rail
    property string title: "Asima OS"
    property string subtitle
    property var steps: []          // step labels
    property int current: 0
    property bool finished: false
    property string footnote

    implicitWidth: 300
    clip: true
    gradient: Gradient {
        orientation: Gradient.Vertical
        GradientStop { position: 0.0; color: Theme.heroFrom }
        GradientStop { position: 0.55; color: Theme.heroMid }
        GradientStop { position: 1.0; color: Theme.heroTo }
    }

    // soft decorative light
    Rectangle { width: 420; height: 420; radius: 210; color: "#FFFFFF"; opacity: 0.07; x: -210; y: rail.height - 260 }
    Rectangle { width: 220; height: 220; radius: 110; color: "#FFFFFF"; opacity: 0.06; x: rail.width - 120; y: -70 }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        anchors.topMargin: 32
        spacing: 0

        RowLayout {
            spacing: 12
            Rectangle {
                implicitWidth: 46
                implicitHeight: 46
                radius: 14
                color: Qt.rgba(1, 1, 1, 0.16)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.25)
                AsimaMark { anchors.centerIn: parent; size: 36 }
            }
            ColumnLayout {
                spacing: 1
                UiText { text: rail.title; variant: "heading"; color: "#FFFFFF" }
                UiText { text: rail.subtitle; variant: "caption"; color: Qt.rgba(1, 1, 1, 0.82) }
            }
        }

        Item { Layout.preferredHeight: 44 }

        Repeater {
            model: rail.steps
            delegate: Item {
                id: stepItem
                required property string modelData
                required property int index
                readonly property string state_: rail.finished || index < rail.current ? "done"
                                               : index === rail.current ? "active" : "pending"
                Layout.fillWidth: true
                implicitHeight: 50

                Rectangle {
                    visible: stepItem.index < rail.steps.length - 1
                    x: 13
                    y: 30
                    width: 2
                    height: stepItem.height - 30
                    radius: 1
                    color: Qt.rgba(1, 1, 1, stepItem.state_ === "done" ? 0.75 : 0.28)
                }
                Rectangle {
                    id: dot
                    width: 28
                    height: 28
                    radius: 14
                    color: stepItem.state_ === "done" ? "#FFFFFF"
                         : stepItem.state_ === "active" ? Qt.rgba(1, 1, 1, 0.2) : "transparent"
                    border.width: stepItem.state_ === "done" ? 0 : 2
                    border.color: stepItem.state_ === "active" ? "#FFFFFF" : Qt.rgba(1, 1, 1, 0.45)
                    Behavior on color { ColorAnimation { duration: Theme.normal } }

                    Icon {
                        anchors.centerIn: parent
                        visible: stepItem.state_ === "done"
                        name: "checkmark"
                        size: 14
                        color: Theme.heroMid
                    }
                    UiText {
                        anchors.centerIn: parent
                        visible: stepItem.state_ !== "done"
                        text: stepItem.index + 1
                        variant: "caption"
                        color: "#FFFFFF"
                        font.weight: Font.Bold
                        opacity: stepItem.state_ === "active" ? 1 : 0.75
                    }
                }
                UiText {
                    anchors.left: dot.right
                    anchors.leftMargin: 14
                    anchors.verticalCenter: dot.verticalCenter
                    text: stepItem.modelData
                    color: "#FFFFFF"
                    opacity: stepItem.state_ === "pending" ? 0.72 : 1
                    font.pixelSize: Theme.textMd + 1
                    font.weight: stepItem.state_ === "active" ? Font.Bold : Font.Medium
                }
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            visible: rail.footnote.length > 0
            Layout.fillWidth: true
            spacing: 10
            Icon { name: "object-locked"; size: 16; color: "#FFFFFF"; Layout.alignment: Qt.AlignTop; Layout.topMargin: 2 }
            UiText {
                text: rail.footnote
                variant: "small"
                color: Qt.rgba(1, 1, 1, 0.9)
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }
    Accessible.role: Accessible.List
    Accessible.name: qsTr("Steps")
}

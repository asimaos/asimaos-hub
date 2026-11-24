import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as B

// One step of a guided flow: scrollable content with a title, and a fixed bar with Back / Continue.
Item {
    id: page
    property string title
    property string subtitle
    property bool canContinue: true
    property string nextText: qsTr("Continue")
    property string nextVariant: "primary"
    property string nextIcon: "go-next"
    property bool showBack: true
    property bool showNext: true
    property bool showFooter: true
    property string backText: qsTr("Back")
    property string hint: ""                // small text left of the Continue button
    property int maxContentWidth: 880
    default property alias content: contentColumn.data
    property alias footerStart: footerStartRow.data
    readonly property real contentWidth: contentColumn.width
    signal next()
    signal back()

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: wrapper.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            B.ScrollBar.vertical: DScrollBar {}

            Item {
                id: wrapper
                width: flick.width
                height: column.implicitHeight + 88

                ColumnLayout {
                    id: column
                    width: Math.min(page.maxContentWidth, wrapper.width - 96)
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 52
                    spacing: 28

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        UiText { text: page.title; variant: "title"; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                        UiText {
                            visible: text.length > 0
                            text: page.subtitle
                            tone: "muted"
                            font.pixelSize: Theme.textLg - 1
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }
                    }
                    ColumnLayout {
                        id: contentColumn
                        Layout.fillWidth: true
                        spacing: 20
                    }
                }
            }
        }

        Rectangle {
            visible: page.showFooter
            Layout.fillWidth: true
            implicitHeight: 80
            color: Theme.surface

            Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.border }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 40
                anchors.rightMargin: 40
                spacing: 12
                DButton {
                    visible: page.showBack
                    text: page.backText
                    variant: "ghost"
                    large: true
                    iconName: "go-previous"
                    onClicked: page.back()
                }
                RowLayout {
                    id: footerStartRow
                    visible: children.length > 0
                    spacing: 10
                }
                Item { Layout.fillWidth: true }
                UiText {
                    visible: text.length > 0
                    text: page.hint
                    variant: "small"
                    tone: "muted"
                }
                DButton {
                    visible: page.showNext
                    text: page.nextText
                    variant: page.nextVariant
                    iconName: page.nextIcon
                    iconRight: page.nextIcon === "go-next"
                    large: true
                    enabled: page.canContinue
                    onClicked: page.next()
                }
            }
        }
    }
}

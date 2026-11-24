import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as B

// Scrollable app page: title, subtitle, header actions and a centred content column.
Item {
    id: page
    property string title
    property string subtitle
    property int maxContentWidth: 1140
    default property alias content: contentColumn.data
    property alias headerActions: actionRow.data
    readonly property real contentWidth: contentColumn.width
    // Screenshots and deep links: open the page scrolled so that this card is at the top.
    property Item startAt: null

    Timer {
        interval: 700
        running: page.startAt !== null
        onTriggered: flick.contentY = Math.max(0, Math.min(page.startAt.mapToItem(wrapper, 0, 0).y - 24,
                                                           flick.contentHeight - flick.height))
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: wrapper.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        B.ScrollBar.vertical: DScrollBar {}

        Item {
            id: wrapper
            width: flick.width
            height: column.implicitHeight + 72

            ColumnLayout {
                id: column
                width: Math.min(page.maxContentWidth, wrapper.width - 72)
                anchors.horizontalCenter: parent.horizontalCenter
                y: 36
                spacing: 24

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        UiText {
                            text: page.title
                            variant: "title"
                            Layout.fillWidth: true
                        }
                        UiText {
                            visible: text.length > 0
                            text: page.subtitle
                            tone: "muted"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                    RowLayout {
                        id: actionRow
                        spacing: 8
                        Layout.alignment: Qt.AlignBottom
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
}

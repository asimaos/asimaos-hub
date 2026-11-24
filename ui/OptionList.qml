pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as B

// Searchable single-choice list. model: [{ id, title, subtitle?, keywords? }]; the search also
// matches the keywords, which aren't shown.
ColumnLayout {
    id: list
    property var model: []
    property string currentId
    property bool searchable: true
    property string placeholder: qsTr("Search")
    property int listHeight: 320
    signal picked(string id)

    spacing: 10

    readonly property var filtered: {
        const q = search.text.trim().toLowerCase()
        if (!q.length)
            return list.model
        return list.model.filter(m => (m.title + " " + (m.subtitle || "") + " " + m.id + " " + (m.keywords || "")).toLowerCase().indexOf(q) >= 0)
    }

    DTextField {
        id: search
        visible: list.searchable
        Layout.fillWidth: true
        placeholderText: list.placeholder
        leftPadding: 40
        Icon {
            name: "edit-find"
            size: 16
            color: Theme.textSubtle
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: list.listHeight
        radius: Theme.radiusM
        color: Theme.surface
        border.width: 1
        border.color: Theme.border
        clip: true

        ListView {
            id: view
            anchors.fill: parent
            anchors.margins: 6
            clip: true
            spacing: 2
            model: list.filtered
            boundsBehavior: Flickable.StopAtBounds
            B.ScrollBar.vertical: DScrollBar {}

            delegate: Rectangle {
                id: option
                required property var modelData
                readonly property bool chosen: modelData.id === list.currentId
                width: view.width
                height: option.modelData.subtitle ? 50 : 40
                radius: Theme.radiusS
                color: chosen ? Theme.accentSoft : (hover.containsMouse ? Theme.surfaceHover : "transparent")

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        UiText {
                            text: option.modelData.title
                            font.weight: option.chosen ? Font.DemiBold : Font.Medium
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        UiText {
                            visible: !!option.modelData.subtitle
                            text: option.modelData.subtitle || ""
                            variant: "caption"
                            tone: "muted"
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }
                    Icon { visible: option.chosen; name: "checkmark"; size: 16; color: Theme.accentText }
                }
                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        list.currentId = option.modelData.id
                        list.picked(option.modelData.id)
                    }
                }
                Accessible.role: Accessible.ListItem
                Accessible.name: modelData.title
                Accessible.selected: chosen
            }

            function showCurrent(mode) {
                for (let i = 0; i < list.filtered.length; ++i)
                    if (list.filtered[i].id === list.currentId) { positionViewAtIndex(i, mode); break }
            }
            Component.onCompleted: showCurrent(ListView.Center)
            // Chosen elsewhere (a time zone that follows the language): scrolled into view when it
            // isn't already.
            Connections {
                target: list
                function onCurrentIdChanged() { view.showCurrent(ListView.Contain) }
            }
        }
    }
}

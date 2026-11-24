pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Asima.Ui

DPage {
    id: page
    title: qsTr("Guides & wiki")
    subtitle: qsTr("How to set up and use Asima OS, and answers for everything else. They open in your web browser.")

    UiText {
        visible: Backend.links.length === 0
        text: qsTr("The guides can't be reached right now.")
        tone: "muted"
    }

    Repeater {
        model: Backend.links
        delegate: Card {
            id: entry
            required property var modelData
            Layout.fillWidth: true
            title: modelData.title
            subtitle: modelData.detail
            icon: modelData.icon
            actions: [ DButton { text: qsTr("Open"); variant: "secondary"; iconName: "applications-internet"; onClicked: Backend.openLink(entry.modelData.url) } ]
        }
    }
}

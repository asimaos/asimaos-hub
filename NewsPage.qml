pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Asima.Ui

DPage {
    id: page
    title: qsTr("What's new")
    subtitle: qsTr("News from the Asima OS project, and the changes in each version.")

    UiText {
        visible: Backend.releases.length === 0 && Backend.news.length === 0
        text: Backend.feedState === "loading" ? qsTr("Loading…") : qsTr("Nothing to show: the release server can't be reached.")
        tone: "muted"
    }

    Repeater {
        model: Backend.news
        delegate: Card {
            id: news
            required property var modelData
            Layout.fillWidth: true
            title: modelData.title
            subtitle: modelData.date
            icon: "news-subscribe"
            tone: "info"
            spacing: 6
            actions: [ DButton {
                visible: !!news.modelData.link
                text: qsTr("Read more")
                variant: "ghost"
                iconName: "applications-internet"
                onClicked: Backend.openLink(news.modelData.link)
            } ]
            UiText {
                Layout.fillWidth: true
                visible: !!news.modelData.text
                text: news.modelData.text || ""
                wrapMode: Text.WordWrap
            }
        }
    }

    Repeater {
        model: Backend.releases
        delegate: Card {
            id: release
            required property var modelData
            Layout.fillWidth: true
            title: qsTr("Asima OS %1").arg(modelData.version)
            subtitle: modelData.date
            icon: modelData.current ? "checkmark" : "view-calendar"
            tone: modelData.current ? "ok" : "info"
            spacing: 6
            actions: [ StatusPill { visible: !!release.modelData.current; text: qsTr("You have this"); tone: "ok" } ]
            Repeater {
                model: release.modelData.notes || []
                delegate: UiText {
                    required property var modelData
                    Layout.fillWidth: true
                    text: "•  " + modelData
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}

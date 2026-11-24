pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

// App sidebar: brand header, navigation (optionally grouped by "section"), footer slot.
// pages: [{ key, label, icon, section?, badge?, badgeTone? }]
Rectangle {
    id: sidebar
    property string appName
    property string appSubtitle
    // The app's icon in Asima UI's assets/apps (updater, maintenance, …); empty: the Asima OS mark.
    property string appIcon: ""
    property var pages: []
    property string current
    signal navigate(string key)
    default property alias footer: footerColumn.data

    implicitWidth: 256
    color: Theme.sidebar

    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: Theme.border
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        anchors.topMargin: 20
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.bottomMargin: 22
            spacing: 12
            AsimaMark { size: 38; icon: sidebar.appIcon }
            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true
                UiText { text: sidebar.appName; variant: "heading"; Layout.fillWidth: true; elide: Text.ElideRight }
                UiText { text: sidebar.appSubtitle; variant: "caption"; tone: "muted"; Layout.fillWidth: true; elide: Text.ElideRight }
            }
        }

        Repeater {
            model: sidebar.pages
            delegate: ColumnLayout {
                id: entry
                required property var modelData
                required property int index
                readonly property bool newSection: (modelData.section || "") !== ""
                    && (index === 0 || (sidebar.pages[index - 1].section || "") !== modelData.section)
                Layout.fillWidth: true
                spacing: 4

                UiText {
                    visible: entry.newSection
                    text: entry.modelData.section || ""
                    variant: "overline"
                    tone: "subtle"
                    Layout.leftMargin: 14
                    Layout.topMargin: 14
                    Layout.bottomMargin: 2
                }
                NavItem {
                    Layout.fillWidth: true
                    label: entry.modelData.label
                    iconName: entry.modelData.icon
                    badge: entry.modelData.badge || ""
                    badgeTone: entry.modelData.badgeTone || "accent"
                    active: sidebar.current === entry.modelData.key
                    onClicked: sidebar.navigate(entry.modelData.key)
                }
            }
        }

        Item { Layout.fillHeight: true }

        ColumnLayout {
            id: footerColumn
            Layout.fillWidth: true
            spacing: 8
        }
    }
}

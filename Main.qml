import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as B
import Asima.Ui

B.ApplicationWindow {
    id: win
    width: 1280
    height: 820
    minimumWidth: 980
    minimumHeight: 640
    visible: true
    title: qsTr("Asima Hub")
    color: Theme.window
    font.family: Theme.fontFamily

    property string startPage: "updates"
    property string themeMode: "system"
    // Away from Asima OS (Windows, another Linux) there is nothing to update: it opens on Get Asima OS.
    property string page: startPage === "updates" && !Backend.installed ? "get" : startPage

    readonly property var pages: (Backend.installed ? [
        { key: "updates", label: qsTr("Updates"), icon: "download",
          badge: Backend.latest.newer && !Backend.download.done ? qsTr("New") : "", badgeTone: "accent" }] : []).concat([
        { key: "get", label: qsTr("Get Asima OS"), icon: "drive-removable-media-usb" },
        { key: "news", label: qsTr("What's new"), icon: "view-calendar" },
        { key: "help", label: qsTr("Guides & wiki"), icon: "help-contents" },
        { key: "report", label: qsTr("Problem report"), icon: "tools-report-bug" }
    ])

    function notify(message, tone) { toast.show(message, tone) }

    Component.onCompleted: Theme.mode = themeMode

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Sidebar {
            Layout.fillHeight: true
            appName: qsTr("Asima Hub")
            appSubtitle: qsTr("Releases and news")   // the footer shows whether the release server answers
            appIcon: "hub"
            pages: win.pages
            current: win.page
            onNavigate: key => win.page = key

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: footer.implicitHeight + 24
                radius: Theme.radiusL - 2
                color: Theme.surface
                border.width: 1
                border.color: Theme.border
                RowLayout {
                    id: footer
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10
                    StatusGlyph {
                        tone: Backend.feedState === "ok" ? "ok" : Backend.feedState === "loading" ? "info" : "warn"
                        size: 22
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        UiText {
                            text: Backend.feedState === "ok" ? qsTr("Connected")
                                  : Backend.feedState === "loading" ? qsTr("Connecting…")
                                  : Backend.feedState === "unset" ? qsTr("No release server") : qsTr("Offline")
                            variant: "small"
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        UiText {
                            text: Backend.installed ? qsTr("Asima OS %1").arg(Backend.installed) : qsTr("Not running on Asima OS")
                            variant: "caption"
                            tone: "muted"
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Loader {
                id: pageLoader
                anchors.fill: parent
                sourceComponent: win.page === "news" ? newsPage : win.page === "help" ? helpPage
                               : win.page === "report" ? reportPage : win.page === "get" ? getPage : updatesPage
                onLoaded: enter.restart()
            }
            ParallelAnimation {
                id: enter
                NumberAnimation { target: pageLoader.item; property: "opacity"; from: 0; to: 1; duration: Theme.normal; easing.type: Easing.OutCubic }
                NumberAnimation { target: pageLoader.item; property: "y"; from: 10; to: 0; duration: Theme.slow; easing.type: Easing.OutCubic }
            }
        }
    }

    Component { id: updatesPage; UpdatesPage {} }
    Component { id: newsPage; NewsPage {} }
    Component { id: helpPage; HelpPage {} }
    Component { id: reportPage; ReportPage {} }
    Component { id: getPage; GetPage {} }

    Toast { id: toast }

    Connections {
        target: Backend
        function onToast(message, tone) { toast.show(message, tone) }
    }
}

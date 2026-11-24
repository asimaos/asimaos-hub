import QtQuick
import QtQuick.Layouts
import Asima.Ui

DPage {
    id: page
    title: qsTr("Updates")
    subtitle: qsTr("Download new versions of Asima OS. Asima Updater checks and installs them.")

    readonly property var l: Backend.latest
    readonly property var d: Backend.download

    headerActions: [
        DButton {
            visible: Backend.configured
            text: qsTr("Check again")
            variant: "ghost"
            iconName: "view-refresh"
            enabled: Backend.feedState !== "loading"
            onClicked: Backend.refresh()
        }
    ]

    InfoBanner {
        visible: Backend.feedState === "unset"
        Layout.fillWidth: true
        tone: "warn"
        title: qsTr("No release server")
        text: qsTr("This copy of Asima Hub was built without the address of a release server. Get Asima Hub from the Asima OS website.")
    }
    InfoBanner {
        visible: Backend.feedState === "error"
        Layout.fillWidth: true
        tone: "error"
        title: qsTr("Can't check for updates")
        text: Backend.feedError
    }
    InfoBanner {
        visible: Backend.feedState === "ok" && !page.l.version
        Layout.fillWidth: true
        tone: "info"
        title: qsTr("No version on the release server yet")
        text: qsTr("When a version of Asima OS is published, it appears here. The news are on the What's new page.")
    }

    Card {
        visible: !!page.l.version
        Layout.fillWidth: true
        padding: 24
        RowLayout {
            Layout.fillWidth: true
            spacing: 20
            IconTile { name: page.l.newer ? "download" : "checkmark"; tone: page.l.newer ? "accent" : "ok"; size: 64 }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                UiText {
                    text: page.l.newer ? qsTr("Asima OS %1 is available").arg(page.l.version) : qsTr("Asima OS is up to date")
                    variant: "title"
                }
                UiText {
                    Layout.fillWidth: true
                    text: page.l.newer ? qsTr("Released %1 · %2 to download · you have %3").arg(page.l.date).arg(Theme.bytes(page.l.size)).arg(Backend.installed || qsTr("an unknown version"))
                                       : qsTr("You have %1, the newest version.").arg(Backend.installed)
                    tone: "muted"
                    wrapMode: Text.WordWrap
                }
            }
        }

        ColumnLayout {
            visible: !!page.l.newer
            Layout.fillWidth: true
            Layout.topMargin: 8
            spacing: 10
            DProgressBar {
                visible: !!page.d.active
                Layout.fillWidth: true
                value: page.d.total > 0 ? page.d.received / page.d.total : 0
            }
            UiText {
                visible: !!page.d.active
                text: qsTr("%1 of %2").arg(Theme.bytes(page.d.received)).arg(Theme.bytes(page.d.total))
                tone: "muted"
            }
            UiText {
                visible: !!page.d.error
                Layout.fillWidth: true
                text: page.d.error || ""
                color: Theme.error
                wrapMode: Text.WordWrap
            }
            RowLayout {
                spacing: 10
                DButton {
                    visible: !page.d.done && !page.d.active
                    text: page.d.received > 0 ? qsTr("Continue the download") : qsTr("Download")
                    variant: "primary"
                    iconName: "download"
                    onClicked: Backend.downloadLatest()
                }
                DButton {
                    visible: !!page.d.active
                    text: qsTr("Pause")
                    variant: "secondary"
                    iconName: "media-playback-pause"
                    onClicked: Backend.cancelDownload()
                }
                DButton {
                    visible: !!page.d.done && !page.d.install
                    text: qsTr("Install now")
                    variant: "primary"
                    iconName: "run-install"
                    onClicked: Backend.install()
                }
                DButton {
                    visible: !!page.d.done && !page.d.install
                    text: qsTr("Open in Asima Updater")
                    variant: "ghost"
                    onClicked: Backend.openInUpdater()
                }
                UiText {
                    visible: !!page.d.done && !page.d.install
                    text: qsTr("Downloaded and checked")
                    color: Theme.ok
                }
                DButton {
                    visible: page.d.install === "installed"
                    text: qsTr("Restart now")
                    variant: "primary"
                    iconName: "system-reboot"
                    onClicked: Backend.restart()
                }
                UiText {
                    visible: page.d.install === "installed"
                    Layout.fillWidth: true
                    text: qsTr("Installed. Asima OS %1 starts after a restart; the version you have now stays as the fallback.").arg(page.l.version || "")
                    color: Theme.ok
                    wrapMode: Text.WordWrap
                }
            }
            ColumnLayout {
                visible: page.d.install === "installing" || page.d.install === "checking"
                Layout.fillWidth: true
                spacing: 6
                DProgressBar { Layout.fillWidth: true; value: page.d.installProgress || 0; indeterminate: page.d.install === "checking" }
                UiText { text: page.d.installStep || ""; tone: "muted" }
            }
        }
    }

    Card {
        visible: !!page.l.newer && (page.l.notes || []).length > 0
        Layout.fillWidth: true
        title: qsTr("What's new in %1").arg(page.l.version || "")
        icon: "view-calendar"
        tone: "info"
        spacing: 6
        Repeater {
            model: page.l.notes || []
            delegate: UiText {
                required property var modelData
                Layout.fillWidth: true
                text: "•  " + modelData
                wrapMode: Text.WordWrap
            }
        }
    }

    InfoBanner {
        Layout.fillWidth: true
        tone: "info"
        title: qsTr("Safe to download")
        text: qsTr("Each download is checked against the release server's checksum, and Asima Updater checks the release signature before it installs anything. A cut-off download continues where it stopped.")
    }
}

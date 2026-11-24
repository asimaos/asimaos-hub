pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Asima.Ui

// Get Asima OS (D39): what this PC gets, the ISO, and the USB stick. The installer on the stick
// chooses the disk; nothing here touches a disk except the stick the person picks.
DPage {
    id: page
    title: qsTr("Get Asima OS")
    subtitle: qsTr("See what this PC gets, download Asima OS and write it to a USB stick.")

    readonly property var iso: Backend.latest.iso || ({})
    readonly property var d: Backend.isoDownload
    readonly property bool busy: Writer.state === "writing" || Writer.state === "verifying"
    // The stick being written stays chosen; only a listed stick that holds the ISO can be written.
    property string chosen: Writer.target
    readonly property bool chosenFits: Writer.drives.some(s => s.id === page.chosen && !page.tooSmall(s))
    function tooSmall(stick) { return page.iso.size > 0 && stick.size < page.iso.size }

    // ── 1. This PC ───────────────────────────────────────────────────────────
    Card {
        Layout.fillWidth: true
        title: qsTr("1. What you'll get on this PC")
        subtitle: Backend.pcSummary
        icon: "computer"
        tone: Backend.pcCheck.some(i => i.blocks) ? "warn" : "ok"
        spacing: 0
        Repeater {
            model: Backend.pcCheck
            delegate: ListRow {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                title: modelData.title
                subtitle: modelData.detail
                value: modelData.value
                tone: modelData.tone
                separator: index < Backend.pcCheck.length - 1
            }
        }
    }

    // ── 2. The ISO ───────────────────────────────────────────────────────────
    Card {
        Layout.fillWidth: true
        title: qsTr("2. Download Asima OS")
        subtitle: page.iso.url ? qsTr("Asima OS %1 · %2 · checked against the release server's signed list")
                                     .arg(Backend.latest.version).arg(Theme.bytes(page.iso.size))
               : Backend.feedState === "ok" ? qsTr("No ISO on the release server yet. It appears here once one is published.")
               : Backend.feedState === "loading" ? qsTr("Asking the release server…")
               : qsTr("The release server can't be reached right now.")
        icon: "download"
        tone: page.d.done ? "ok" : "info"
        ColumnLayout {
            visible: !!page.iso.url
            Layout.fillWidth: true
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
                    text: page.d.received > 0 ? qsTr("Continue the download") : qsTr("Download the ISO")
                    variant: "primary"
                    iconName: "download"
                    onClicked: Backend.downloadIso()
                }
                DButton {
                    visible: !!page.d.active
                    text: qsTr("Pause")
                    variant: "secondary"
                    iconName: "media-playback-pause"
                    onClicked: Backend.cancelDownload()
                }
                UiText {
                    visible: !!page.d.done
                    text: qsTr("Downloaded and checked")
                    color: Theme.ok
                }
            }
        }
    }

    // ── 3. The USB stick ─────────────────────────────────────────────────────
    Card {
        Layout.fillWidth: true
        title: qsTr("3. Write it to a USB stick")
        subtitle: qsTr("The whole stick is erased. Use one of at least 8 GB with nothing on it that you need.")
        icon: "drive-removable-media-usb"
        tone: Writer.state === "done" ? "ok" : Writer.state === "error" ? "error" : "info"
        actions: [ DButton {
            text: qsTr("Look again")
            variant: "ghost"
            iconName: "view-refresh"
            enabled: !page.busy
            onClicked: Writer.refreshDrives()
        } ]

        UiText {
            visible: Writer.drives.length === 0
            Layout.fillWidth: true
            text: qsTr("No USB stick found. Plug one in, then press \"Look again\".")
            tone: "muted"
            wrapMode: Text.WordWrap
        }
        Repeater {
            model: Writer.drives
            delegate: SelectCard {
                required property var modelData
                Layout.fillWidth: true
                iconName: "drive-removable-media-usb"
                title: modelData.name
                subtitle: modelData.detail
                selected: page.chosen === modelData.id
                enabled: !page.busy
                disabledLabel: page.tooSmall(modelData) ? qsTr("Too small") : ""
                disabledReason: page.tooSmall(modelData) ? qsTr("Asima OS needs a bigger stick.") : ""
                onToggled: page.chosen = modelData.id
            }
        }
        DProgressBar {
            visible: page.busy
            Layout.fillWidth: true
            value: Writer.progress
        }
        UiText {
            visible: !!Writer.message
            Layout.fillWidth: true
            text: Writer.message
            color: Writer.state === "error" ? Theme.error : Writer.state === "done" ? Theme.ok : Theme.textMuted
            wrapMode: Text.WordWrap
        }
        RowLayout {
            spacing: 10
            DButton {
                text: qsTr("Write to the stick")
                variant: "danger"
                iconName: "media-flash"
                enabled: page.chosenFits && !!page.d.done && !page.busy
                onClicked: confirm.ask({
                    title: qsTr("Erase this stick?"),
                    text: qsTr("Everything on it is deleted, then Asima OS is written to it and checked. Type ERASE to go on."),
                    tone: "error",
                    icon: "edit-delete-shred",
                    confirmText: qsTr("Erase and write"),
                    requiredWord: "ERASE"
                }, () => Writer.write(page.chosen, page.d.file, page.iso.sha256))
            }
            DButton {
                visible: page.busy
                text: qsTr("Stop")
                variant: "secondary"
                iconName: "process-stop"
                onClicked: Writer.cancel()
            }
            UiText {
                visible: !page.d.done && Writer.drives.length > 0
                text: qsTr("Download the ISO first.")
                tone: "muted"
            }
        }
    }

    InfoBanner {
        Layout.fillWidth: true
        tone: "info"
        title: qsTr("Installing")
        text: qsTr("Start the PC from the stick and choose \"Install Asima OS\". The installer asks which disk to use and erases only that one: back up first, or install on a second disk to keep what is on the first.")
    }

    ConfirmDialog { id: confirm }
}

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as B
import QtQuick.Dialogs
import Asima.Ui

// Problem reports are made by Asima Maintenance on the computer (it reads the logs); Asima Hub
// only sends one, after the person has read it here.
DPage {
    id: page
    title: qsTr("Problem report")
    subtitle: qsTr("Send a report that Asima Maintenance made, so the Asima OS team can find the cause.")

    readonly property var r: Backend.report

    Card {
        Layout.fillWidth: true
        title: qsTr("1. Make the report")
        subtitle: qsTr("Open Asima Maintenance → Health → Problem report, read it, then save it.")
        icon: "document-new"
    }

    Card {
        Layout.fillWidth: true
        title: qsTr("2. Open it here")
        subtitle: qsTr("Read it once more. You can still change or remove anything.")
        icon: "document-open"
        actions: [ DButton { text: qsTr("Open a report…"); variant: "secondary"; iconName: "document-open"; onClicked: openDialog.open() } ]

        Connections {
            target: Backend
            function onReportChanged() { if (reportText.text !== Backend.report.text) reportText.text = Backend.report.text }
        }
        B.ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: 260
            B.TextArea {
                id: reportText
                text: page.r.text || ""
                placeholderText: qsTr("Or paste the report here.")
                font.family: "Noto Sans Mono"
                font.pixelSize: Theme.textXs
                wrapMode: TextEdit.Wrap
                color: Theme.text
                selectByMouse: true
                background: Rectangle { color: Theme.surfaceAlt; radius: Theme.radiusS; border.color: Theme.border }
                onTextChanged: if (text !== (page.r.text || "")) Backend.setReportText(text)
            }
        }
    }

    Card {
        Layout.fillWidth: true
        title: qsTr("3. Send it by email")
        subtitle: Backend.canSendReports ? qsTr("The report is saved in Downloads and your mail app opens with the Asima OS team's address: attach it and send it. Nothing else leaves this computer.")
                                         : qsTr("The release server hasn't named an address for reports yet. Save the report and share it where you ask for help.")
        icon: "mail-send"
        tone: page.r.state === "mail" ? "ok" : page.r.state === "error" ? "error" : "info"
        RowLayout {
            spacing: 10
            DButton {
                text: qsTr("Save and write an email")
                variant: "primary"
                iconName: "mail-send"
                enabled: Backend.canSendReports && (page.r.text || "").trim().length > 0
                onClicked: Backend.sendReport()
            }
            UiText {
                visible: !!page.r.message && !!page.r.state
                Layout.fillWidth: true
                text: page.r.message || ""
                color: page.r.state === "error" ? Theme.error : page.r.state === "mail" ? Theme.ok : Theme.textMuted
                wrapMode: Text.WordWrap
            }
        }
    }

    FileDialog {
        id: openDialog
        title: qsTr("Open a problem report")
        nameFilters: [qsTr("Text files (*.txt)"), qsTr("All files (*)")]
        onAccepted: Backend.loadReport(selectedFile)
    }
}

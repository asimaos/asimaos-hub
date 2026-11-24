import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as B

// Modal confirmation. Optionally requires typing a word (e.g. "RESET") before confirming, and can
// ask for secrets: an existing one (`secret`: its label) and/or a new one typed twice (`newSecret`,
// at least `newSecretMin` characters). The callback receives { secret, newSecret }; the fields are
// cleared as soon as the dialog closes, so secrets don't linger in the UI.
B.Popup {
    id: dialog
    property string title
    property string text
    property string tone: "accent"          // accent | error | warn | info
    property string iconName: "help-about"
    property string confirmText: qsTr("Continue")
    property string cancelText: qsTr("Cancel")
    property string requiredWord: ""
    property string secretLabel: ""
    property string newSecretLabel: ""
    property int newSecretMin: 8
    property var onConfirmed: null
    readonly property bool secretsReady: (secretLabel.length === 0 || secretField.text.length > 0)
        && (newSecretLabel.length === 0 || (newField.text.length >= newSecretMin && newField.text === repeatField.text))

    function ask(options, callback) {
        title = options.title || ""
        text = options.text || ""
        tone = options.tone || "accent"
        iconName = options.icon || (tone === "error" ? "edit-reset" : "help-about")
        confirmText = options.confirmText || qsTr("Continue")
        requiredWord = options.requiredWord || ""
        secretLabel = options.secret || ""
        newSecretLabel = options.newSecret || ""
        newSecretMin = options.newSecretMin || 8
        onConfirmed = callback || null
        typed.text = ""
        open()
    }
    onClosed: {
        secretField.text = ""
        newField.text = ""
        repeatField.text = ""
    }

    parent: B.Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(480, (parent ? parent.width : 480) - 48)
    modal: true
    focus: true
    padding: 24
    closePolicy: B.Popup.CloseOnEscape | B.Popup.CloseOnPressOutside

    B.Overlay.modal: Rectangle { color: Theme.overlay }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.normal }
            NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: Theme.normal; easing.type: Easing.OutCubic }
        }
    }
    exit: Transition { NumberAnimation { property: "opacity"; to: 0; duration: Theme.fast } }

    background: Rectangle {
        radius: Theme.radiusXl
        color: Theme.surface
        border.width: 1
        border.color: Theme.border
    }

    contentItem: ColumnLayout {
        spacing: 16
        RowLayout {
            spacing: 14
            Layout.fillWidth: true
            IconTile {
                name: dialog.iconName
                tone: dialog.tone
                size: 44
                Layout.alignment: Qt.AlignTop
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                UiText { text: dialog.title; variant: "subtitle"; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                UiText { text: dialog.text; tone: "muted"; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            }
        }
        ColumnLayout {
            visible: dialog.requiredWord.length > 0
            Layout.fillWidth: true
            spacing: 6
            UiText {
                text: qsTr("Type %1 to confirm").arg(dialog.requiredWord)
                variant: "small"
                font.weight: Font.DemiBold
            }
            DTextField {
                id: typed
                Layout.fillWidth: true
                placeholderText: dialog.requiredWord
            }
        }
        ColumnLayout {
            visible: dialog.secretLabel.length > 0
            Layout.fillWidth: true
            spacing: 6
            UiText { text: dialog.secretLabel; variant: "small"; font.weight: Font.DemiBold }
            PasswordField { id: secretField; Layout.fillWidth: true }
        }
        ColumnLayout {
            visible: dialog.newSecretLabel.length > 0
            Layout.fillWidth: true
            spacing: 6
            UiText { text: dialog.newSecretLabel; variant: "small"; font.weight: Font.DemiBold }
            PasswordField {
                id: newField
                Layout.fillWidth: true
                placeholderText: qsTr("At least %1 characters").arg(dialog.newSecretMin)
            }
            PasswordField {
                id: repeatField
                Layout.fillWidth: true
                placeholderText: qsTr("Repeat it")
                tone: repeatField.text.length > 0 && repeatField.text !== newField.text ? "error" : ""
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 10
            Item { Layout.fillWidth: true }
            DButton {
                text: dialog.cancelText
                variant: "ghost"
                onClicked: dialog.close()
            }
            DButton {
                text: dialog.confirmText
                variant: dialog.tone === "error" ? "danger" : "primary"
                enabled: dialog.secretsReady && (dialog.requiredWord.length === 0
                         || typed.text.trim().toUpperCase() === dialog.requiredWord.toUpperCase())
                onClicked: {
                    const cb = dialog.onConfirmed
                    const values = { secret: secretField.text, newSecret: newField.text }
                    dialog.close()
                    if (cb) cb(values)
                }
            }
        }
    }
}

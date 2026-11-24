import QtQuick

// Password input with a show/hide toggle.
DTextField {
    id: field
    property bool revealed: false
    echoMode: revealed ? TextInput.Normal : TextInput.Password
    passwordCharacter: "•"
    rightPadding: 46
    inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase

    Item {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 42
        height: parent.height
        Icon {
            anchors.centerIn: parent
            name: field.revealed ? "password-show-off" : "password-show-on"
            size: 16
            color: Theme.textMuted
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: field.revealed = !field.revealed
        }
        Accessible.role: Accessible.Button
        Accessible.name: field.revealed ? qsTr("Hide passphrase") : qsTr("Show passphrase")
    }
}

import QtQuick

// Small rounded status label with a dot. tone: ok | warn | error | info | accent | neutral
Rectangle {
    id: pill
    property string text
    property string tone: "ok"
    property bool dot: true

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 24
    radius: height / 2
    color: Theme.statusSoft(tone)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Rectangle {
            visible: pill.dot
            width: 6
            height: 6
            radius: 3
            color: Theme.statusColor(pill.tone)
            anchors.verticalCenter: parent.verticalCenter
        }
        UiText {
            text: pill.text
            variant: "caption"
            color: Theme.statusColor(pill.tone)
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    Accessible.role: Accessible.StaticText
    Accessible.name: text
}

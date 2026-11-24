import QtQuick
import QtQuick.Layouts

// Inline message. tone: info | ok | warn | error | accent
Rectangle {
    id: banner
    property string tone: "info"
    property string title
    property string text
    property string iconName: ""   // empty → vector status glyph for the tone
    default property alias actions: actionRow.data

    implicitHeight: row.implicitHeight + 28
    radius: Theme.radiusL - 2
    color: Theme.statusSoft(tone)
    border.width: 1
    border.color: Qt.alpha(Theme.statusColor(tone), Theme.dark ? 0.28 : 0.22)

    RowLayout {
        id: row
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 12

        Icon {
            visible: banner.iconName.length > 0
            name: banner.iconName
            size: 20
            color: Theme.statusColor(banner.tone)
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 1
        }
        StatusGlyph {
            visible: banner.iconName.length === 0
            tone: banner.tone === "accent" ? "info" : banner.tone
            color: Theme.statusColor(banner.tone)
            size: 20
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 1
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            UiText {
                visible: text.length > 0
                text: banner.title
                font.weight: Font.DemiBold
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            UiText {
                visible: text.length > 0
                text: banner.text
                variant: "small"
                tone: "muted"
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
        RowLayout {
            id: actionRow
            spacing: 8
            Layout.alignment: Qt.AlignVCenter
        }
    }
}

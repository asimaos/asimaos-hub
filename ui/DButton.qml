import QtQuick
import QtQuick.Controls.Basic as B

// Asima OS button. variant: primary | secondary | soft | ghost | danger | onAccent
B.Button {
    id: control
    property string variant: "secondary"
    property string iconName
    property bool iconRight: false        // e.g. "Continue →"
    property bool large: false
    property bool busy: false

    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    implicitHeight: large ? 44 : 36
    leftPadding: large ? 20 : 16
    rightPadding: large ? 20 : 16
    font.family: Theme.fontFamily
    font.pixelSize: large ? Theme.textMd + 1 : Theme.textMd
    font.weight: Font.DemiBold

    readonly property color fg: {
        switch (variant) {
        case "primary":
        case "danger": return Theme.textOnAccent
        case "onAccent": return Theme.textOnAccent
        case "soft": return Theme.accentText
        default: return Theme.text
        }
    }
    readonly property color bgNormal: {
        switch (variant) {
        case "primary": return Theme.accent
        case "danger": return Theme.errorFill
        case "soft": return Theme.accentSoft
        case "onAccent": return Qt.rgba(1, 1, 1, 0.18)
        case "ghost": return "transparent"
        default: return Theme.surface
        }
    }
    readonly property color bgHover: {
        switch (variant) {
        case "primary": return Theme.brandHover
        case "danger": return Qt.darker(Theme.errorFill, 1.12)
        case "soft": return Qt.darker(Theme.accentSoft, Theme.dark ? 0.8 : 1.04)
        case "onAccent": return Qt.rgba(1, 1, 1, 0.26)
        default: return Theme.surfaceHover
        }
    }
    readonly property color bgPressed: {
        switch (variant) {
        case "primary": return Theme.brandPressed
        case "danger": return Qt.darker(Theme.errorFill, 1.25)
        case "onAccent": return Qt.rgba(1, 1, 1, 0.34)
        default: return Qt.darker(bgHover, Theme.dark ? 0.85 : 1.05)
        }
    }

    contentItem: Item {
        implicitWidth: row.implicitWidth
        implicitHeight: row.implicitHeight
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8
            layoutDirection: control.iconRight ? Qt.RightToLeft : Qt.LeftToRight
            Spinner {
                visible: control.busy
                size: 16
                color: control.fg
                anchors.verticalCenter: parent.verticalCenter
            }
            Icon {
                visible: control.iconName.length > 0 && !control.busy
                name: control.iconName
                size: 16
                color: control.fg
                anchors.verticalCenter: parent.verticalCenter
            }
            UiText {
                text: control.text
                font: control.font
                color: control.fg
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    background: Rectangle {
        implicitWidth: 88
        radius: Theme.radiusM
        color: control.down ? control.bgPressed : control.hovered ? control.bgHover : control.bgNormal
        border.width: control.variant === "secondary" ? 1 : 0
        border.color: Theme.borderStrong
        Behavior on color { ColorAnimation { duration: Theme.fast } }

        Rectangle {
            // keyboard focus ring
            anchors.fill: parent
            anchors.margins: -3
            radius: parent.radius + 3
            color: "transparent"
            border.width: 2
            border.color: Theme.accent
            opacity: control.visualFocus ? 0.7 : 0
        }
    }

    opacity: enabled ? 1.0 : 0.5
    Accessible.name: text
}

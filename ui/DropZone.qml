import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

// Dashed drop target for files, with a centred message and actions.
Item {
    id: zone
    property string iconName: "document-import"
    property string title
    property string text
    property var acceptSuffixes: []
    default property alias actions: actionRow.data
    signal fileDropped(url file)

    implicitHeight: column.implicitHeight + 64
    implicitWidth: 400

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusL
        color: drop.containsDrag ? Theme.accentSoft : Theme.surfaceAlt
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: drop.containsDrag ? Theme.accent : Theme.borderStrong
            strokeWidth: 1.5
            strokeStyle: ShapePath.DashLine
            dashPattern: [5, 4]
            fillColor: "transparent"
            PathRectangle {
                x: 1
                y: 1
                width: zone.width - 2
                height: zone.height - 2
                radius: Theme.radiusL
            }
        }
    }

    ColumnLayout {
        id: column
        anchors.centerIn: parent
        width: Math.min(zone.width - 48, 520)
        spacing: 10

        IconTile {
            Layout.alignment: Qt.AlignHCenter
            name: zone.iconName
            tone: "accent"
            size: 52
        }
        UiText {
            Layout.fillWidth: true
            text: zone.title
            variant: "heading"
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
        UiText {
            Layout.fillWidth: true
            visible: text.length > 0
            text: zone.text
            variant: "small"
            tone: "muted"
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
        RowLayout {
            id: actionRow
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6
            spacing: 10
        }
    }

    DropArea {
        id: drop
        anchors.fill: parent
        onDropped: function(event) {
            if (event.hasUrls && event.urls.length > 0)
                zone.fileDropped(event.urls[0])
        }
    }
}

import QtQuick

// Rounded tinted square holding an icon: the visual anchor of cards and rows.
Rectangle {
    id: tile
    property string name
    property string tone: "accent"
    property int size: 40

    width: size
    height: size
    implicitWidth: size
    implicitHeight: size
    radius: Math.round(size * 0.3)
    color: Theme.statusSoft(tone)

    Icon {
        anchors.centerIn: parent
        name: tile.name
        size: Math.round(tile.size * 0.5)
        color: Theme.statusColor(tile.tone)
    }
}

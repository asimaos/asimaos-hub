import QtQuick

// A system-theme icon (Breeze on Asima OS) recoloured to one tint.
Image {
    id: icon
    property string name
    property color color: Theme.text
    property int size: 18

    width: size
    height: size
    sourceSize: Qt.size(size, size)
    source: name.length > 0 ? "image://dicon/" + name + "/" + Theme.hex(color) : ""
    fillMode: Image.PreserveAspectFit
    smooth: true
    cache: true
    Accessible.ignored: true
}

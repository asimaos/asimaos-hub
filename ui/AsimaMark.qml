import QtQuick

// The Asima OS mark (an endless ribbon, assets/make-mark.py), or with `icon` set one of the Asima OS
// apps' icons (assets/make-app-icons.py: updater, maintenance, manager, gaming, dev, appcenter). Wrapped in an
// Item so layouts use `size`, not the SVG's pixel size.
Item {
    id: mark
    property int size: 36
    property string icon: ""

    implicitWidth: size
    implicitHeight: size

    Image {
        anchors.fill: parent
        sourceSize: Qt.size(mark.size * 2, mark.size * 2)
        // Absolute path: a relative one would resolve against the page using the mark.
        source: mark.icon ? "qrc:/qt/qml/Asima/Ui/assets/apps/" + mark.icon + ".svg"
                          : "qrc:/qt/qml/Asima/Ui/assets/asimaos-mark.svg"
        smooth: true
        mipmap: true
    }
    Accessible.role: Accessible.Graphic
    Accessible.name: "Asima OS"
}

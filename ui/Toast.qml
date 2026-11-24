import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as B

// Short confirmation message at the bottom of the window.
B.Popup {
    id: toast
    property string message
    property string tone: "ok"

    function show(text, kind) {
        message = text
        tone = kind || "ok"
        open()
        timer.restart()
    }

    parent: B.Overlay.overlay
    x: parent ? (parent.width - width) / 2 : 0
    y: parent ? parent.height - height - 28 : 0
    width: Math.min(560, content.implicitWidth + 40)
    padding: 0
    modal: false
    focus: false
    closePolicy: B.Popup.NoAutoClose

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.normal }
            NumberAnimation { property: "y"; from: toast.parent ? toast.parent.height : 0; duration: Theme.slow; easing.type: Easing.OutCubic }
        }
    }
    exit: Transition { NumberAnimation { property: "opacity"; to: 0; duration: Theme.normal } }

    Timer { id: timer; interval: 3800; onTriggered: toast.close() }

    background: Rectangle {
        radius: Theme.radiusL
        color: Theme.dark ? "#262D39" : "#1B1F27"
    }
    contentItem: RowLayout {
        id: content
        spacing: 12
        Item { implicitWidth: 6 }
        StatusGlyph {
            tone: toast.tone
            size: 20
            glyphColor: "#1B1F27"
            color: toast.tone === "ok" ? "#4ADE80" : toast.tone === "error" ? "#F87171"
                 : toast.tone === "warn" ? "#FACC15" : "#A5B4FC"
        }
        UiText {
            Layout.fillWidth: true
            Layout.topMargin: 14
            Layout.bottomMargin: 14
            text: toast.message
            color: "#F3F5F8"
            wrapMode: Text.WordWrap
        }
        Item { implicitWidth: 6 }
    }
}

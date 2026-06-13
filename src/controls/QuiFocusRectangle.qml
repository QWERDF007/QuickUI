import QtQuick
import QtQuick.Controls
import quickui

Item {
    id: control

    property int radius: 4
    property color focusColor: QuiColor.Highlight

    anchors.fill: parent

    Rectangle {
        width: control.width
        height: control.height
        anchors.centerIn: parent
        color: "transparent"
        border.width: 2
        radius: control.radius
        border.color: control.focusColor
        z: 65535
    }
}


import QtQuick
import QtQuick.Controls

Item {
    id: control

    property color color: "#3D3D3D"
    property int elevation: 5
    property int radius: 4

    anchors.fill: parent

    Repeater {
        model: Math.max(0, control.elevation)

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            opacity: 0.01 * (control.elevation - index + 1)
            anchors.margins: -index
            radius: control.radius + index
            border.width: index
            border.color: control.color
        }
    }
}


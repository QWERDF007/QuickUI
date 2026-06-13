import QtQuick
import QtQuick.Controls

import quickui

TextField{
    id:control
    property alias textColor: control.color
    property color bgColor: QuiColor.Gray110
    color: QuiColor.FontPrimary
    font: QuiFont.Body
    renderType: Text.NativeRendering
    selectionColor: QuiColor.Highlight
    selectedTextColor: color
    placeholderTextColor: QuiColor.Gray110
    selectByMouse: true
    hoverEnabled: true
    background: Item {
        implicitWidth: 200
        implicitHeight: 40
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 2
            color: control.focus ? QuiColor.Highlight : hovered ? "white" : bgColor
        }
    }
}

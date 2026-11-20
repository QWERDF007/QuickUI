import QtQuick
import QtQuick.Controls

import quickui

TextInput{
    id:control
    property color bgColor: QuiColor.Gray110
    property alias textColor: control.color
    color: enabled ? QuiColor.FontPrimary : QuiColor.FontDark
    font: QuiFont.Body
    renderType: Text.NativeRendering
    selectionColor: QuiColor.Highlight
    selectedTextColor: color
    selectByMouse: true
}

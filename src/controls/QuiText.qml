import QtQuick
import QtQuick.Controls

import quickui

Text {
    id:control
    property alias textColor: control.color
    renderType: Text.NativeRendering
    font: QuiFont.Body
    color: QuiColor.FontPrimary
}

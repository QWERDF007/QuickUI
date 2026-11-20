import QtQuick
import QtQuick.Controls

import quickui

TextArea {
    id:control
    renderType: TextEdit.NativeRendering
    font: QuiFont.Body
    color: enabled ? QuiColor.FontPrimary : QuiColor.FontDark
    placeholderTextColor: enabled ? palette.placeholderText : QuiColor.FontDark
    selectionColor: QuiColor.Highlight
}

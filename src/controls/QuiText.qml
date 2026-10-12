import QtQuick
import QtQuick.Controls

import quickui

Text {
    id:control
    property alias textColor: control.color
    renderType: Text.CurveRendering
    renderTypeQuality: Text.VeryHighRenderTypeQuality
    font: QuiFont.Body
    color: QuiColor.FontPrimary
}

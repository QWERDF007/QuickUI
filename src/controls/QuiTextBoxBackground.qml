import QtQuick

import quickui

Rectangle {
    id: control
    property Item inputItem
    property bool hovered: false
    property bool invalid: false

    implicitWidth: 200
    implicitHeight: 32
    radius: 4
    border.width: 1
    border.color: !enabled ? QuiColor.CardBorder
                : invalid ? QuiColor.Error
                : inputItem && inputItem.activeFocus ? QuiColor.Highlight
                : hovered ? QuiColor.FontCaption : QuiColor.CardBorder
    color: !enabled ? QuiColor.ItemDisabled
         : invalid ? Qt.tint(QuiColor.CardBackground, Qt.rgba(QuiColor.Error.r, QuiColor.Error.g, QuiColor.Error.b, 0.09))
         : hovered ? QuiColor.ItemHover : QuiColor.CardBackground
}

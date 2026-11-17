import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic

import quickui

QuiButtonBase {
    property string contentDescription: ""
    property color normalColor: checkable && checked ? QuiColor.Highlight : QuiColor.Button
    property alias backgroundColor: control.normalColor
    property color hoverColor: normalColor === QuiColor.White ? Qt.darker(normalColor, 1.05) : Qt.lighter(normalColor, 1.2)
    property color pressedColor: normalColor === QuiColor.White ? Qt.darker(normalColor, 1.1) : Qt.lighter(normalColor, 1.3)
    property color textColor: QuiColor.FontPrimary
    property color borderColor: control.enabled && (control.hovered || control.highlighted || control.activeFocus) ? QuiColor.Highlight : QuiColor.Border
    property int borderWidth: 2
    Accessible.role: Accessible.Button
    Accessible.name: control.text
    Accessible.description: contentDescription
    Accessible.onPressAction: control.clicked()
    id: control
    focusPolicy: Qt.NoFocus
    background: Rectangle {
        implicitWidth: 30
        radius: 4
        color:  {
            if (enabled) {
                return  pressed ? pressedColor : hovered ? hoverColor : normalColor
            }
            return normalColor
        }
        border.width: control.borderWidth
        border.color: control.borderColor
    }
    function activateFromKeyboard(event) {
        if (!control.enabled)
            return
        if (control.checkable)
            control.toggle()
        control.clicked()
        event.accepted = true
    }
    Keys.onEnterPressed: (event) => control.activateFromKeyboard(event)
    Keys.onReturnPressed: (event) => control.activateFromKeyboard(event)
    contentItem: QuiText {
        text: control.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font: control.font
        color: control.textColor
    }
}

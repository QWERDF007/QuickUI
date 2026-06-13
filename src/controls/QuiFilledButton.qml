import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic

import quickui

Button {
    property string contentDescription: ""
    property color normalColor: QuiColor.Button
    property color hoverColor: Qt.lighter(normalColor, 1.2)
    property color pressedColor: Qt.lighter(normalColor,1.3)
    property color textColor: Qt.rgba(1,1,1,1)
    Accessible.role: Accessible.Button
    Accessible.name: control.text
    Accessible.description: contentDescription
    Accessible.onPressAction: control.clicked()
    id: control
    focusPolicy:Qt.TabFocus
    font: QuiFont.Body
    verticalPadding: 0
    horizontalPadding:12
    opacity: enabled ? 1 : 0.3
    background: QuiControlBackground{
        implicitWidth: 30
        implicitHeight: 30
        radius: 4
        bottomMargin: enabled ? 2 : 0
        border.width: enabled ? 1 : 0
        border.color: Qt.darker(control.normalColor, 1.2)
        color: pressed ? pressedColor : hovered ? hoverColor : normalColor
        shadow: !pressed && enabled
        QuiFocusRectangle{
            visible: control.visualFocus
            radius:4
        }
    }
    contentItem: QuiText {
        text: control.text
        font: control.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: control.textColor
    }
}

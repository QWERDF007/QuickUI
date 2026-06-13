import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic

import quickui

Button {
    property string contentDescription: ""
    property color normalColor: checkable && checked ? QuiColor.Highlight : QuiColor.Button
    property color hoverColor: Qt.lighter(normalColor, 1.2)
    property color pressedColor: Qt.lighter(normalColor, 1.3)
    property color textColor: QuiColor.FontPrimary
    Accessible.role: Accessible.Button
    Accessible.name: control.text
    Accessible.description: contentDescription
    Accessible.onPressAction: control.clicked()
    id: control
    verticalPadding: 0
    horizontalPadding: 12
    font: QuiFont.Body
    focusPolicy: Qt.NoFocus
    opacity: enabled ? 1 : 0.3
    background: QuiControlBackground {
        implicitWidth: 30
        implicitHeight: 30
        radius: 4
        color:  {
            if (enabled) {
                return  pressed ? pressedColor : hovered ? hoverColor : normalColor
            }
            return normalColor
        }
        shadow: !pressed && enabled
        QuiFocusRectangle {
            visible: control.activeFocus
            radius:4
        }
        // QuiShadow {
        //     color: "#000000"
        //     radius: 4
        // }
    }
    contentItem: QuiText {
        text: control.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font: control.font
        color: control.textColor
    }
}

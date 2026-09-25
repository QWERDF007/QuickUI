import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl

import quickui

TabButton {
    id: control
    font: QuiFont.Body
    property color normalColor: "transparent"
    property color hoverColor: QuiColor.Hovered
    property color pressedColor: Qt.darker(QuiColor.Hovered, 1.08)
    property color checkedColor: "transparent"
    property color normalTextColor: QuiColor.FontPrimary
    property color checkedTextColor: QuiColor.Highlight
    property color textColor: checked ? checkedTextColor : normalTextColor
    property color indicatorColor: QuiColor.Highlight
    property bool showIndicator: false
    property int indicatorHeight: 2
    property real radius: 2

    contentItem: IconLabel {
        id: content
        spacing: control.spacing
        mirrored: control.mirrored
        display: control.display
        alignment: Qt.AlignCenter

        icon: control.icon
        text: control.text
        font: control.font
        color: control.enabled ? control.textColor : QuiColor.FontDark
        opacity: enabled ? 1 : 0.4
    }

    background: Rectangle {
        id: bg
        implicitHeight: 32
        implicitWidth: 60
        opacity: enabled ? 1 : 0.4
        color: enabled ? (control.down ? control.pressedColor : control.hovered ? control.hoverColor : (control.checked ? control.checkedColor : control.normalColor)) : control.normalColor
        radius: control.radius
        clip: true

        Rectangle {
            id: indicator
            visible: control.checked && control.showIndicator
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: control.indicatorHeight
            color: control.indicatorColor
        }
    }
}

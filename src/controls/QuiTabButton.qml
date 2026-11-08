import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl

import quickui

TabButton {
    id: control

    font: QuiFont.Subtitle

    // 基础背景色彩
    property color normalColor: QuiColor.Primary
    property color hoverColor: QuiColor.Hovered
    property color pressedColor: Qt.lighter(normalColor, 1.3)
    property color checkedColor: normalColor
    property color checkedHoverColor: checkedColor === "transparent" ? hoverColor : Qt.lighter(checkedColor, 1.15)
    property color checkedPressedColor: checkedColor === "transparent" ? pressedColor : Qt.darker(checkedColor, 1.15)

    // 文字色彩
    property color normalTextColor: QuiColor.FontPrimary
    property color checkedTextColor: QuiColor.Highlight
    property color hoverTextColor: checked ? checkedTextColor : "#FFFFFF"
    property color disabledTextColor: QuiColor.FontDark

    property color textColor: {
        if (!control.enabled) return disabledTextColor
        if (control.checked) return checkedTextColor
        if (control.hovered) return hoverTextColor
        return normalTextColor
    }

    // 指示条配置
    property color indicatorColor: QuiColor.Highlight
    property bool showIndicator: false
    property int indicatorHeight: 2
    property real radius: 2

    implicitWidth: Math.max(content.implicitWidth + leftPadding + rightPadding, 80)
    implicitHeight: 48

    contentItem: IconLabel {
        id: content
        spacing: control.spacing
        mirrored: control.mirrored
        display: control.display
        alignment: Qt.AlignCenter

        icon: control.icon
        text: control.text
        font: control.font
        color: control.textColor
        opacity: control.enabled ? 1.0 : 0.4
    }

    background: Rectangle {
        id: bg
        anchors.fill: parent
        radius: control.radius
        opacity: control.enabled ? 1.0 : 0.4

        color: {
            if (!control.enabled) return control.normalColor
            if (control.checked) {
                if (control.down) return control.checkedPressedColor
                if (control.hovered) return control.checkedHoverColor
                return control.checkedColor
            }
            if (control.down) return control.pressedColor
            if (control.hovered) return control.hoverColor
            return control.normalColor
        }

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

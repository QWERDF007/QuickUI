import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Templates as T

import quickui

T.ToolButton {
    id: control

    property color normalColor: "transparent"
    property color hoverColor: QuiColor.ItemHover
    property color pressedColor: QuiColor.ItemPress
    property color checkColor: QuiColor.ItemCheck
    property color disableColor: QuiColor.ItemDisabled
    property int radius: 4

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 6
    spacing: 6

    icon.width: 20
    icon.height: 20
    icon.color: {
        if (!control.enabled) {
            return QuiColor.FontCaption
        }
        if (control.checked) {
            return QuiColor.Primary
        }
        return QuiColor.FontPrimary
    }

    contentItem: IconLabel {
        spacing: control.spacing
        mirrored: control.mirrored
        display: control.display

        icon: control.icon
        text: control.text
        font: control.font
        color: control.icon.color
    }

    background: Rectangle {
        implicitWidth: 32
        implicitHeight: 32
        radius: control.radius
        border.color: control.enabled && control.hovered ? QuiColor.Border : "transparent"
        border.width: 1

        color: {
            if (!control.enabled) {
                return disableColor
            } else if (control.down || control.checked || control.highlighted) {
                return checkColor
            } else if (control.hovered) {
                return hoverColor
            }
            return normalColor
        }
    }
}

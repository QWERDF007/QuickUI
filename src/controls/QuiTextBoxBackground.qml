import QtQuick
import QtQuick.Controls

import quickui

QuiControlBackground {
    property Item inputItem
    id: control

    color: {
        if (inputItem && !inputItem.enabled) {
            return QuiColor.ItemDisabled
        }
        if (inputItem && inputItem.activeFocus) {
            return QuiColor.themeMode === QuiColor.Dark ? Qt.darker(QuiColor.CardBackground, 1.2) : QuiColor.CardBackground
        }
        if (inputItem && inputItem.hovered) {
            return QuiColor.themeMode === QuiColor.Dark ? Qt.lighter(QuiColor.CardBackground, 1.15) : Qt.darker(QuiColor.CardBackground, 1.02)
        }
        return QuiColor.CardBackground
    }

    border.width: 1
    gradient: Gradient {
        GradientStop { position: 0.0; color: d.startColor }
        GradientStop {
            position: control.height > 0 ? Math.max(0.0, 1.0 - d.offsetSize / control.height) : 0.0
            color: d.startColor
        }
        GradientStop {
            position: control.height > 0 ? Math.max(0.0, 1.0 - d.offsetSize / control.height) : 0.0
            color: d.endColor
        }
        GradientStop { position: 1.0; color: d.endColor }
    }
    bottomMargin: inputItem && inputItem.activeFocus ? 2 : 1

    QtObject {
        id: d
        property int offsetSize: inputItem && inputItem.activeFocus ? 2 : 3
        property color startColor: QuiColor.CardBorder
        property color endColor: {
            if (!control.enabled) {
                return d.startColor
            }
            if (inputItem && inputItem.activeFocus) {
                return QuiColor.Highlight
            }
            return QuiColor.ButtonShadow
        }
    }
}

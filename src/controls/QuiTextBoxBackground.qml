import QtQuick
import QtQuick.Controls

import quickui

QuiControlBackground {
    property Item inputItem
    id:control
    color: "red"
    border.width: 1
    gradient: Gradient {
        GradientStop { position: 0.0; color: d.startColor }
        GradientStop { position: control.height > 0 ? Math.max(0, 1 - d.offsetSize / control.height) : 0; color: d.startColor }
        GradientStop { position: 1.0; color: d.endColor }
    }
    bottomMargin: inputItem && inputItem.activeFocus ? 2 : 1
    QtObject{
        id:d
        property int offsetSize  : inputItem && inputItem.activeFocus ? 2 : 3
        property color startColor: Qt.rgba(232/255,232/255,232/255,1)
        property color endColor: {
            if(!control.enabled){
                return d.startColor
            }
            return inputItem && inputItem.activeFocus ? QuiColor.Primary : Qt.rgba(132/255,132/255,132/255,1)
        }
    }
}

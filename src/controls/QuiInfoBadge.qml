import QtQuick
import QtQuick.Controls

import quickui

Item {
    id:control
    property int count: 0
    property int max: 99
    width: childrenRect.width
    height: 20
    property alias icon: badge_icon
    property alias text: badge_text
    property color contentColor: QuiColor.FontPrimary
    QuiTextIcon {
        id: badge_icon
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        iconSource: QuiFontIcon.Info
        iconSize: 12
        color: control.contentColor
    }
    QuiText{
        id: badge_text
        anchors.left: badge_icon.right
        anchors.leftMargin: 2
        verticalAlignment: Text.AlignVCenter
        anchors.verticalCenter: parent.verticalCenter
        text: count <= max ? count: "%1+".arg(max)
        font: QuiFont.Caption
        color: control.contentColor
    }
}

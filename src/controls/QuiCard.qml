import QtQuick
import QtQuick.Controls
import quickui

Rectangle {
    id: control

    property bool hoverEnabled: false
    property bool clickable: false
    property alias hovered: mouseArea.containsMouse
    property alias mouseX: mouseArea.mouseX
    property alias mouseY: mouseArea.mouseY
    property color cardColor: QuiColor.CardBackground
    property color hoverColor: QuiColor.ItemHover
    property color borderColor: QuiColor.CardBorder
    property color hoverBorderColor: QuiColor.CardBorder
    property int elevation: 0

    signal clicked()
    signal doubleClicked()

    radius: 8
    color: cardColor
    border.color: (hoverEnabled && mouseArea.containsMouse) ? hoverBorderColor : borderColor
    border.width: 1

    Rectangle {
        id: hoverOverlay
        anchors.fill: parent
        radius: control.radius
        color: (control.hoverEnabled && mouseArea.containsMouse) ? control.hoverColor : "transparent"
        visible: control.hoverEnabled
    }

    QuiShadow {
        id: shadow
        visible: control.elevation > 0
        radius: control.radius
        elevation: control.elevation
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: control.hoverEnabled || control.clickable
        enabled: control.hoverEnabled || control.clickable
        cursorShape: control.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (control.clickable) {
                control.clicked()
            }
        }
        onDoubleClicked: {
            control.doubleClicked()
        }
    }
}

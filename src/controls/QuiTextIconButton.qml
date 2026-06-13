import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Basic

import quickui

Button {
    id:control
    display: Button.IconOnly
    property int iconSize: 20
    property int iconSource
    property int radius:4
    property string contentDescription: ""
    property color hoverColor: Qt.lighter(normalColor, 1.2)
    property color pressedColor: Qt.lighter(normalColor, 1.3)
    property color normalColor: QuiColor.Button
    property Component iconDelegate: com_icon
    property color color: pressed ? pressedColor : hovered ? hoverColor : normalColor
    property color iconColor: enabled ? QuiColor.FontPrimary : "#6E6E6E"
    property color textColor: QuiColor.FontPrimary
    readonly property bool hostingPopupOpen: {
        var ancestor = control.parent
        while (ancestor) {
            if (ancestor instanceof Popup)
                return ancestor.opened
            ancestor = ancestor.parent
        }
        return true
    }
    Accessible.role: Accessible.Button
    Accessible.name: control.text
    Accessible.description: contentDescription
    Accessible.onPressAction: control.clicked()
    focusPolicy:Qt.TabFocus
    padding: 0
    verticalPadding: 4
    horizontalPadding: 4
    font: QuiFont.Caption
    background: Rectangle{
        implicitWidth: 30
        implicitHeight: 30
        radius: control.radius
        color:control.color
        QuiFocusRectangle{
            visible: control.activeFocus
        }
    }
    Component{
        id:com_icon
        QuiTextIcon {
            id:text_icon
            font.pixelSize: iconSize
            iconSize: control.iconSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            iconColor: control.iconColor
            iconSource: control.iconSource
        }
    }
    Component{
        id:com_row
        RowLayout{
            QuiLoader{
                sourceComponent: iconDelegate
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                visible: display !== Button.TextOnly
            }
            QuiText{
                text:control.text
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                visible: display !== Button.IconOnly
                color: control.textColor
                font: control.font
            }
        }
    }
    Component{
        id:com_column
        ColumnLayout{
            QuiLoader{
                sourceComponent: iconDelegate
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                visible: display !== Button.TextOnly
            }
            QuiText{
                text:control.text
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                visible: display !== Button.IconOnly
                color: control.textColor
                font: control.font
            }
        }
    }
    contentItem: QuiLoader{
        sourceComponent: {
            if(display === Button.TextUnderIcon){
                return com_column
            }
            return com_row
        }
    }
    QuiToolTip{
        id:tool_tip
        visible: control.text !== ""
                && control.display === Button.IconOnly
                && control.hovered
                && control.visible
                && !control.pressed
                && control.hostingPopupOpen
        text:control.text
        delay: 200
    }

    onVisibleChanged: {
        if (!control.visible)
            tool_tip.close()
    }

    onHoveredChanged: {
        if (!control.hovered)
            tool_tip.close()
    }

    onPressedChanged: {
        if (control.pressed)
            tool_tip.close()
    }

    Component.onDestruction: tool_tip.close()
}

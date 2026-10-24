import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Basic

import quickui

TextField {
    id: control

    signal commit(string text)

    property bool disabled: false
    property int iconSource: 0
    property bool cleanEnabled: true

    property color normalColor: QuiColor.FontPrimary
    property color disableColor: QuiColor.FontCaption
    property color placeholderNormalColor: QuiColor.FontCaption
    property color placeholderFocusColor: QuiColor.FontDark
    property color placeholderDisableColor: QuiColor.FontCaption

    enabled: !disabled
    onEnabledChanged: {
        if (disabled !== !enabled) {
            disabled = !enabled
        }
    }
    onDisabledChanged: {
        if (enabled !== !disabled) {
            enabled = !disabled
        }
    }

    color: !enabled ? disableColor : normalColor
    font: QuiFont.Body
    renderType: Text.NativeRendering
    selectionColor: Utils.withOpacity(QuiColor.Highlight, 0.4)
    selectedTextColor: color
    placeholderTextColor: {
        if (!enabled) {
            return placeholderDisableColor
        }
        if (focus) {
            return placeholderFocusColor
        }
        return placeholderNormalColor
    }
    selectByMouse: true
    verticalAlignment: Text.AlignVCenter

    implicitWidth: 240
    implicitHeight: 32
    padding: 7
    leftPadding: padding + 4
    rightPadding: {
        var w = 0
        if (control.cleanEnabled && !control.readOnly) {
            w += 28
        }
        if (control.iconSource !== 0) {
            w += 20
        }
        return w + 8
    }

    background: QuiTextBoxBackground {
        inputItem: control
    }

    Keys.onEnterPressed: (event) => d.handleCommit(event)
    Keys.onReturnPressed: (event) => d.handleCommit(event)

    QtObject {
        id: d
        function handleCommit(event) {
            control.commit(control.text)
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        acceptedButtons: Qt.RightButton
        onClicked: (mouse) => {
            if (control.echoMode === TextInput.Password) {
                return
            }
            if (control.readOnly && control.text === "") {
                return
            }
            control.forceActiveFocus()
            var clickPos = control.positionAt(mouse.x, mouse.y)
            if (control.selectionStart === control.selectionEnd || clickPos < control.selectionStart || clickPos > control.selectionEnd) {
                control.cursorPosition = clickPos
            }
            menu_loader.popup(mouse.x, mouse.y)
        }
    }

    RowLayout {
        height: parent.height
        anchors.right: parent.right
        anchors.rightMargin: 5
        spacing: 4

        QuiTextIconButton {
            id: clean_btn
            iconSource: QuiFontIcon.Cancel
            iconSize: 10
            implicitWidth: 24
            implicitHeight: 20
            Layout.preferredWidth: 24
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignVCenter
            radius: 3
            focusPolicy: Qt.NoFocus
            normalColor: QuiColor.Transparent
            hoverColor: QuiColor.ItemHover
            pressedColor: QuiColor.ItemPress
            iconColor: clean_btn.hovered ? QuiColor.FontPrimary : QuiColor.FontCaption
            visible: control.cleanEnabled && !control.readOnly && control.text !== ""
            contentDescription: "Clean"
            onClicked: {
                control.clear()
                control.forceActiveFocus()
            }
        }

        QuiTextIcon {
            id: icon_end
            iconSource: control.iconSource
            iconSize: 12
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: 4
            iconColor: control.enabled ? QuiColor.FontCaption : QuiColor.FontDark
            visible: control.iconSource !== 0
        }
    }

    QuiLoader {
        id: menu_loader
        property real menuX: 0
        property real menuY: 0
        function popup(x, y) {
            menuX = x
            menuY = y
            sourceComponent = menu
        }
    }

    Component {
        id: menu
        QuiTextBoxMenu {
            inputItem: control
            Component.onCompleted: {
                popup(menu_loader.menuX, menu_loader.menuY)
            }
            onClosed: {
                menu_loader.sourceComponent = undefined
            }
        }
    }
}

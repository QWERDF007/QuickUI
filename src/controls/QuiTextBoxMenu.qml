import QtQuick
import QtQuick.Controls

import quickui

QuiMenu {
    property string cutText: qsTr("剪切")
    property string copyText: qsTr("复制")
    property string pasteText: qsTr("粘贴")
    property string selectAllText: qsTr("全选")
    property var inputItem
    id: menu

    animationEnabled: false
    width: 120
    focus: false

    onVisibleChanged: {
        if (visible && inputItem) {
            inputItem.forceActiveFocus()
        }
    }

    Connections {
        target: inputItem ? inputItem : null
        function onTextChanged() {
            menu.close()
        }
        function onActiveFocusChanged() {
            if (inputItem && !inputItem.activeFocus) {
                menu.close()
            }
        }
    }

    QuiMenuItem {
        text: menu.cutText
        visible: menu.inputItem ? menu.inputItem.selectedText !== "" && !menu.inputItem.readOnly : false
        height: visible ? implicitHeight : 0
        onTriggered: {
            if (menu.inputItem) {
                menu.inputItem.cut()
            }
        }
    }

    QuiMenuItem {
        text: menu.copyText
        visible: menu.inputItem ? menu.inputItem.selectedText !== "" : false
        height: visible ? implicitHeight : 0
        onTriggered: {
            if (menu.inputItem) {
                menu.inputItem.copy()
            }
        }
    }

    QuiMenuItem {
        text: menu.pasteText
        visible: menu.inputItem ? !menu.inputItem.readOnly && menu.inputItem.canPaste : false
        height: visible ? implicitHeight : 0
        onTriggered: {
            if (menu.inputItem) {
                menu.inputItem.paste()
            }
        }
    }

    QuiMenuItem {
        text: menu.selectAllText
        visible: menu.inputItem ? menu.inputItem.text !== "" : false
        height: visible ? implicitHeight : 0
        onTriggered: {
            if (menu.inputItem) {
                menu.inputItem.selectAll()
            }
        }
    }
}

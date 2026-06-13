import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Templates as T
import quickui

T.ComboBox {
    id: control
    signal commit(string text)
    property color normalColor: QuiColor.Primary
    property color hoverColor: QuiColor.Hovered
    // property alias bg: _bg
    property alias content: _content
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)
    font: QuiFont.Body
    leftPadding: padding + (!control.mirrored || !indicator || !indicator.visible ? 0 : indicator.width + spacing)
    rightPadding: padding + (control.mirrored || !indicator || !indicator.visible ? 0 : indicator.width + spacing)
    delegate: QuiItemDelegate {
        width: ListView.view.width
        onImplicitWidthChanged: { // 在下拉选项内容长度变化时修改下拉框的宽度
            ListView.view.implicitWidth = Math.max(ListView.view.implicitWidth, implicitWidth)
        }

        // text: control.textRole ? (Array.isArray(control.model) ? modelData[control.textRole] : model[control.textRole]) : modelData
        text: {
            if (!control.textRole) {
                return modelData
            }
            if (modelData && modelData[control.textRole] !== undefined) {
                return modelData[control.textRole]
            }
            if (model && model[control.textRole] !== undefined) {
                return model[control.textRole]
            }
            return ""
        }
        palette.text: control.palette.text
        font: control.font
        palette.highlightedText: control.palette.highlightedText
        highlighted: control.highlightedIndex === index
        hoverEnabled: control.hoverEnabled
    }
    focusPolicy: Qt.TabFocus
    indicator: QuiTextIcon {
        x: control.mirrored ? control.padding : control.width - width - control.padding
        y: control.topPadding + (control.availableHeight - height) / 2
        width: 28
        iconSource: QuiFontIcon.ChevronDown
        iconColor: QuiColor.FontPrimary
        iconSize: 15
        opacity: enabled ? 1 : 0.3
    }
    contentItem: T.TextField {
        id: _content
        enabled: control.editable
        leftPadding: !control.mirrored ? 10 : control.editable && activeFocus ? 3 : 1
        rightPadding: control.mirrored ? 10 : control.editable && activeFocus ? 3 : 1
        topPadding: 6 - control.padding
        bottomPadding: 6 - control.padding
        renderType: Text.NativeRendering
        selectionColor: Utils.withOpacity(control.normalColor, 0.5)
        selectedTextColor: color
        text: control.editable ? control.editText : control.displayText
        autoScroll: control.editable
        font: control.font
        readOnly: control.down
        color: QuiColor.FontPrimary
        inputMethodHints: control.inputMethodHints
        validator: control.validator
        selectByMouse: control.selectTextByMouse
        verticalAlignment: Text.AlignVCenter
        background: QuiControlBackground {
            id: _bg
            border.width: 1
            bottomMargin: !control.editable ? 1 : contentItem && contentItem.activeFocus ? 2 : 1
            color: control.hovered ? control.hoverColor : control.normalColor
        }

        Keys.onEnterPressed: (event) => handleCommit(event)
        Keys.onReturnPressed: (event) => handleCommit(event)
        function handleCommit(event) {
            control.commit(control.editText)
            if (event) {
                event.accepted = true
            }
            accepted()
        }
    }
    background: Rectangle {
        implicitWidth: 140
        implicitHeight: 32
        visible: !control.flat || control.down
        radius: 4
        QuiFocusRectangle{
            visible: control.visualFocus
            radius:4
            anchors.margins: -2
        }
        color: control.hovered ? control.hoverColor : control.normalColor
    }

    popup: T.Popup {
        id: _popup
        y: control.height
        width: Math.max(control.width, contentItem.implicitWidth)
        height: Math.min(contentItem.implicitHeight,
                         Math.max(0, (control.Window ? control.Window.height : contentItem.implicitHeight) - topMargin - bottomMargin))
        topMargin: 6
        bottomMargin: 6
        // modal: true // 会影响 hovered 属性
        contentItem: ListView {
            id: view
            clip: true
            implicitHeight: contentHeight
            model: control.delegateModel
            currentIndex: control.highlightedIndex
            highlightMoveDuration: 0
            boundsMovement: Flickable.StopAtBounds
            T.ScrollIndicator.vertical: ScrollIndicator { }
        }
        enter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 83
            }
        }
        exit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 83
            }
        }
        background: Rectangle {
            color: control.normalColor
            border.color: Qt.darker(control.normalColor, 1.2)
            border.width: 1
            radius: 5
            QuiShadow {
                radius: 5
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import quickui

Item {
    id: control

    property alias text: input.text
    property alias inputItem: input
    property string placeholderText: ""
    property bool readOnly: false
    property bool invalid: false
    property bool canDecrease: true
    property bool canIncrease: true
    property bool flat: false
    property font font: QuiFont.Body

    signal decreaseRequested()
    signal increaseRequested()
    signal commitRequested()
    signal cancelRequested()
    signal textEdited(string text)

    implicitWidth: 200
    implicitHeight: 32

    function finishEditing() {
        if (control.enabled && !control.readOnly && !input.inputMethodComposing)
            control.commitRequested()
    }

    Timer {
        id: blurCommit
        interval: 0
        onTriggered: control.finishEditing()
    }

    HoverHandler {
        id: hover
    }

    QuiTextBoxBackground {
        id: frame
        anchors.fill: parent
        inputItem: input
        hovered: hover.hovered
        invalid: control.invalid
        border.width: control.flat ? 0 : 1
        color: control.flat ? "transparent" : (!control.enabled ? QuiColor.ItemDisabled : invalid ? Qt.tint(QuiColor.CardBackground, Qt.rgba(QuiColor.Error.r, QuiColor.Error.g, QuiColor.Error.b, 0.09)) : hovered ? QuiColor.ItemHover : QuiColor.CardBackground)

        RowLayout {
            anchors.fill: parent
            anchors.margins: 1
            spacing: 0

            QuiTextIconButton {
                objectName: "stepperMinus"
                Layout.preferredWidth: 28
                Layout.fillHeight: true
                iconSource: QuiFontIcon.CalculatorSubtract
                iconSize: 12
                radius: 2
                normalColor: QuiColor.Transparent
                hoverColor: QuiColor.ItemHover
                pressedColor: Qt.darker(QuiColor.ItemHover, 1.05)
                focusPolicy: Qt.NoFocus
                enabled: control.enabled && !control.readOnly && !input.inputMethodComposing && control.canDecrease
                onClicked: control.decreaseRequested()
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: QuiColor.CardBorder
            }

            TextInput {
                id: input
                objectName: "stepperInput"
                Layout.fillWidth: true
                Layout.fillHeight: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: !control.enabled ? QuiColor.FontCaption : control.invalid ? QuiColor.Error : QuiColor.FontPrimary
                font: control.font
                selectByMouse: true
                selectionColor: QuiColor.Highlight
                selectedTextColor: color
                readOnly: control.readOnly
                enabled: control.enabled
                clip: true
                autoScroll: true
                inputMethodHints: Qt.ImhFormattedNumbersOnly

                onTextEdited: control.textEdited(text)
                onEditingFinished: {
                    if (activeFocus) control.finishEditing()
                    else blurCommit.restart()
                }
                Keys.onEscapePressed: function(event) {
                    if (inputMethodComposing) {
                        event.accepted = false
                        return
                    }
                    control.cancelRequested()
                    event.accepted = true
                }
                Keys.onUpPressed: function(event) {
                    if (inputMethodComposing || control.readOnly || !control.enabled) {
                        event.accepted = false
                        return
                    }
                    if (control.canIncrease)
                        control.increaseRequested()
                    event.accepted = true
                }
                Keys.onDownPressed: function(event) {
                    if (inputMethodComposing || control.readOnly || !control.enabled) {
                        event.accepted = false
                        return
                    }
                    if (control.canDecrease)
                        control.decreaseRequested()
                    event.accepted = true
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: QuiColor.CardBorder
            }

            QuiTextIconButton {
                objectName: "stepperPlus"
                Layout.preferredWidth: 28
                Layout.fillHeight: true
                iconSource: QuiFontIcon.Add
                iconSize: 12
                radius: 2
                normalColor: QuiColor.Transparent
                hoverColor: QuiColor.ItemHover
                pressedColor: Qt.darker(QuiColor.ItemHover, 1.05)
                focusPolicy: Qt.NoFocus
                enabled: control.enabled && !control.readOnly && !input.inputMethodComposing && control.canIncrease
                onClicked: control.increaseRequested()
            }
        }

        QuiText {
            anchors.left: parent.left
            anchors.leftMargin: 26
            anchors.right: parent.right
            anchors.rightMargin: 26
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text.length === 0 && !input.activeFocus
            text: control.placeholderText
            elide: Text.ElideRight
            color: QuiColor.FontCaption
        }
    }

    QuiToolTip {
        visible: control.invalid && hover.hovered
        text: "输入未保存：请检查格式或范围"
        delay: 300
    }
}

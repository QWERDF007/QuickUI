import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import quickui

Item {
    id: control

    // 公共属性
    property string label: ""
    property real value: 0
    property real minValue: 0
    property real maxValue: 10000
    property real step: 1
    property int decimals: 0
    property bool enabled: true

    // 信号
    signal editingFinished()

    // 内部状态
    property real _internalValue: value

    implicitWidth: 200
    implicitHeight: 32

    onValueChanged: {
        if (_internalValue !== value) {
            _internalValue = value
            textInput.text = formatValue(value)
        }
    }

    // 使用指定的小数位数格式化值
    function formatValue(val) {
        return val.toFixed(decimals)
    }

    // 验证并将值限制在范围内
    function clampValue(val) {
        if (isNaN(val)) return _internalValue
        return Math.max(minValue, Math.min(maxValue, val))
    }

    // 应用新值
    function applyValue(newVal) {
        var clamped = clampValue(newVal)
        if (clamped !== _internalValue) {
            _internalValue = clamped
            control.value = clamped
        }
        textInput.text = formatValue(_internalValue)
    }

    RowLayout {
        anchors.fill: parent
        spacing: 4

        // 标签
        QuiText {
            id: labelText
            text: control.label
            visible: control.label !== ""
            Layout.preferredWidth: visible ? implicitWidth : 0
            opacity: control.enabled ? 1 : 0.5
        }

        // 带按钮的输入框
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors.fill: parent
                radius: 4
                color: QuiColor.Button
                opacity: control.enabled ? 1 : 0.5

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 2
                    spacing: 0

                    // 减号按钮
                    QuiTextIconButton {
                        id: minusBtn
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: parent.height
                        iconSource: QuiFontIcon.CalculatorSubtract
                        iconSize: 12
                        radius: 2
                        enabled: control.enabled && control._internalValue > control.minValue
                        normalColor: QuiColor.Transparent
                        hoverColor: Qt.lighter(QuiColor.Button, 1.3)
                        pressedColor: Qt.lighter(QuiColor.Button, 1.5)
                        onClicked: {
                            applyValue(_internalValue - step)
                            control.editingFinished()
                        }
                    }

                    // 文本输入
                    TextInput {
                        id: textInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: QuiColor.FontPrimary
                        font: QuiFont.Body
                        selectByMouse: true
                        selectionColor: QuiColor.Highlight
                        selectedTextColor: color
                        enabled: control.enabled
                        text: formatValue(control._internalValue)
                        
                        validator: DoubleValidator {
                            bottom: control.minValue
                            top: control.maxValue
                            decimals: control.decimals
                        }

                        onEditingFinished: {
                            var newVal = parseFloat(text)
                            applyValue(newVal)
                            control.editingFinished()
                        }

                        Keys.onUpPressed: {
                            applyValue(_internalValue + step)
                        }

                        Keys.onDownPressed: {
                            applyValue(_internalValue - step)
                        }
                    }

                    // 加号按钮
                    QuiTextIconButton {
                        id: plusBtn
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: parent.height
                        iconSource: QuiFontIcon.Add
                        iconSize: 12
                        radius: 2
                        enabled: control.enabled && control._internalValue < control.maxValue
                        normalColor: QuiColor.Transparent
                        hoverColor: Qt.lighter(QuiColor.Button, 1.3)
                        pressedColor: Qt.lighter(QuiColor.Button, 1.5)
                        onClicked: {
                            applyValue(_internalValue + step)
                            control.editingFinished()
                        }
                    }
                }

                // 聚焦时底部高亮线
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 2
                    radius: 1
                    color: textInput.activeFocus ? QuiColor.Highlight : QuiColor.Transparent
                }
            }
        }
    }
}

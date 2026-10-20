import QtQuick
import QtQuick.Layouts

import quickui

Item {
    id: control

    property string label: ""
    property real value: 0
    property real minValue: 0
    property real maxValue: 10000
    property real step: 1
    property int decimals: 0
    property bool readOnly: false
    property bool invalid: false
    property font font: QuiFont.Body
    property alias text: field.text
    property alias inputItem: field.inputItem

    signal editingFinished()

    property real _committed: value
    property bool _applying: false

    implicitWidth: 200
    implicitHeight: 32

    onValueChanged: {
        if (_applying)
            return
        const dirty = isDirty()
        _committed = value
        if (!field.inputItem.activeFocus || !dirty)
            field.text = formatValue(_committed)
        if (!field.inputItem.activeFocus)
            invalid = false
    }
    onDecimalsChanged: {
        if (!field.inputItem.activeFocus)
            field.text = formatValue(_committed)
    }
    Component.onCompleted: field.text = formatValue(_committed)

    readonly property real _effective: {
        const parsed = parse(field.text)
        return parsed.valid ? parsed.value : _committed
    }
    readonly property real _stepSize: Math.abs(step) > 0 ? Math.abs(step) : 1
    readonly property bool canDecrease: _effective > minValue
    readonly property bool canIncrease: _effective < maxValue

    function roundTo(number, places) {
        return Number(number.toFixed(Math.max(0, Math.min(15, places))))
    }

    function formatValue(number) {
        if (!isFinite(number))
            return ""
        let text = Number(number).toFixed(Math.max(0, Math.min(15, decimals)))
        if (decimals > 0 && text.indexOf("e") === -1) {
            text = text.replace(/0+$/, "")
            if (text.endsWith("."))
                text = text.slice(0, -1)
        }
        return text === "-0" ? "0" : text
    }

    function clampValue(number) {
        if (!isFinite(number))
            return _committed
        return Math.max(minValue, Math.min(maxValue, number))
    }

    function parse(text) {
        const trimmed = String(text).trim()
        if (!/^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?$/.test(trimmed))
            return { valid: false }
        const number = Number(trimmed)
        if (!isFinite(number))
            return { valid: false }
        if (number !== roundTo(number, decimals))
            return { valid: false }
        if (number < minValue || number > maxValue)
            return { valid: false }
        return { valid: true, value: number }
    }

    function isDirty() {
        return field.text !== formatValue(_committed)
    }

    function applyValue(number) {
        if (!isFinite(number))
            return
        const clamped = clampValue(number)
        _applying = true
        value = clamped
        _applying = false
        _committed = clamped
        field.text = formatValue(clamped)
        invalid = false
    }

    function acceptValue(number) {
        const rounded = roundTo(number, decimals)
        _applying = true
        value = rounded
        _applying = false
        _committed = rounded
        field.text = formatValue(rounded)
        invalid = false
        editingFinished()
    }

    function commitDraft() {
        if (!enabled || readOnly || field.inputItem.inputMethodComposing)
            return
        if (!isDirty()) {
            invalid = false
            return
        }
        const parsed = parse(field.text)
        if (!parsed.valid) {
            invalid = true
            return
        }
        if (parsed.value === _committed) {
            field.text = formatValue(_committed)
            invalid = false
            return
        }
        acceptValue(parsed.value)
    }

    function stepBy(direction) {
        if (!enabled || readOnly || field.inputItem.inputMethodComposing)
            return
        const parsed = parse(field.text)
        if (!parsed.valid) {
            invalid = true
            return
        }
        let next = parsed.value + direction * _stepSize
        if (!isFinite(next)) {
            invalid = true
            return
        }
        next = Math.max(minValue, Math.min(maxValue, roundTo(next, decimals)))
        if (next === _committed) {
            field.text = formatValue(_committed)
            invalid = false
            return
        }
        acceptValue(next)
    }

    function cancelDraft() {
        field.text = formatValue(_committed)
        invalid = false
    }

    RowLayout {
        anchors.fill: parent
        spacing: 4

        QuiText {
            id: labelText
            text: control.label
            font: control.font
            visible: control.label !== ""
            Layout.preferredWidth: visible ? implicitWidth : 0
            opacity: control.enabled ? 1 : 0.5
        }

        QuiStepperField {
            id: field
            Layout.fillWidth: true
            Layout.fillHeight: true
            readOnly: control.readOnly
            invalid: control.invalid
            font: control.font
            canDecrease: control.enabled && control.canDecrease
            canIncrease: control.enabled && control.canIncrease
            onDecreaseRequested: control.stepBy(-1)
            onIncreaseRequested: control.stepBy(1)
            onCommitRequested: control.commitDraft()
            onCancelRequested: control.cancelDraft()
            onTextEdited: control.invalid = false
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Templates as T
import quickui

/**
 * 两级下拉组合框：一级为普通项或可展开项，点击可展开项后在右侧横向展开二级子项。
 *
 * optionGroups 为两级结构：[{label, value, subOptions: [{label, value}]}]
 * - 一级项带 subOptions 时显示展开箭头，点击后在右侧展开二级子项；
 * - 叶子项（value 非空）点击后发送 commit(value)。
 * - visible 为 false 的项只用于保持当前值显示，不出现在一级菜单中。
 *
 * 复用 QuiComboBox 的标准机制：扁平化列表作为 model（textRole 显示
 * displayLabel，valueRole 取 value），内容框显示由引擎的 currentIndex/
 * displayText 驱动；savedValue 用于打开时定位已选项。
 */
QuiComboBox {
    id: control

    property var optionGroups: []
    property string savedValue: ""
    property var commitValue: null
    readonly property bool _hasGroups: _level0Model.some(function(entry) { return entry.expandable })
    signal aboutToOpen()

    model: _flatModel
    textRole: "displayLabel"
    valueRole: "value"

    property var _flatModel: []
    property var _level0Model: []
    readonly property var _level1Model: _expandedIndex >= 0 && _expandedIndex < optionGroups.length
        ? (optionGroups[_expandedIndex].subOptions || []).map(function(entry) {
            return { label: String(entry.label), value: _stringValue(entry.value) }
        }) : []
    property int _expandedIndex: -1

    function _stringValue(value) {
        return value === undefined || value === null ? "" : String(value)
    }

    function _rebuildLevels() {
        const l0 = []
        for (let i = 0; i < optionGroups.length; ++i) {
            const entry = optionGroups[i]
            if (entry && entry.visible === false)
                continue
            const subs = entry.subOptions || []
            l0.push({
                sourceIndex: i,
                label: String(entry.label),
                value: _stringValue(entry.value),
                expandable: subs.length > 0,
            })
        }
        _level0Model = l0

        if (_expandedIndex >= optionGroups.length)
            _expandedIndex = -1
    }

    function _flatten() {
        const flat = []
        for (let i = 0; i < optionGroups.length; ++i) {
            const entry = optionGroups[i]
            const subs = entry.subOptions || []
            const label = String(entry.label)
            const displayLabel = entry.displayLabel !== undefined
                    ? String(entry.displayLabel) : label
            flat.push({
                label: label,
                displayLabel: displayLabel,
                value: _stringValue(entry.value),
                level: 0,
                expandable: subs.length > 0,
                expanded: false,
            })
            // 扁平列表始终包含全部二级项（只用于内容框显示与值定位），
            // 展开/收起由 popup 的 _level0Model/_level1Model 独立控制。
            for (let j = 0; j < subs.length; ++j) {
                flat.push({
                    label: String(subs[j].label),
                    displayLabel: label + " / " + String(subs[j].label),
                    value: _stringValue(subs[j].value),
                    level: 1,
                    expandable: false,
                    expanded: false,
                })
            }
        }
        _flatModel = flat
        _locateSelection()
    }

    function _locateSelection() {
        for (let i = 0; i < _flatModel.length; ++i) {
            if (String(_flatModel[i].value) === savedValue) {
                currentIndex = i
                return
            }
        }
        currentIndex = -1
    }

    function _commitValue(value) {
        if (!enabled || !value) return false
        const selected = _flatModel.findIndex(function(entry) { return !entry.expandable && entry.value === value })
        if (selected < 0) return false
        if (typeof commitValue === "function" && commitValue(value) !== true) {
            _locateSelection()
            return false
        }
        currentIndex = _flatModel.findIndex(function(entry) { return !entry.expandable && entry.value === value })
        control.commit(value)
        popup.close()
        return true
    }

    function _activateGroup(row, focusOutputs) {
        if (!enabled || row < 0 || row >= _level0Model.length) return
        const entry = _level0Model[row]
        level0List.currentIndex = row
        _expandedIndex = entry.expandable ? entry.sourceIndex : -1
        if (entry.expandable && focusOutputs) {
            level1List.currentIndex = 0
            level1List.forceActiveFocus()
        } else if (!entry.expandable && focusOutputs) {
            _commitValue(entry.value)
        }
    }

    onOptionGroupsChanged: { _rebuildLevels(); _flatten() }
    onSavedValueChanged: _locateSelection()
    onEnabledChanged: { if (!enabled) popup.close() }
    Keys.onDownPressed: popup.open()
    Keys.onUpPressed: popup.open()
    Keys.onReturnPressed: popup.open()
    Keys.onEnterPressed: popup.open()
    Keys.onSpacePressed: popup.open()
    Connections {
        target: control.Window.window
        function onActiveChanged() { if (target && !target.active) popup.close() }
    }

    popup: T.Popup {
        id: popup
        y: control.height
        width: Math.min(Math.max(control.width, 180) * (control._hasGroups ? 2 : 1) + 8,
                        control.Window.window ? control.Window.window.width - 24 : 480)
        height: Math.min(Math.max(level0List.contentHeight, level1List.contentHeight) + 8,
                         Math.max(0, control.Window.window ? control.Window.window.height - 40 : 400))
        padding: 4
        margins: 6
        focus: true
        closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutside
        onAboutToShow: {
            control.aboutToOpen()
            control._expandedIndex = -1
            control._rebuildLevels()
            control._flatten()
        }
        onOpened: { level0List.currentIndex = 0; level0List.forceActiveFocus() }
        onClosed: control._expandedIndex = -1

        contentItem: RowLayout {
            spacing: 0
            enabled: control.enabled
            ListView {
                id: level0List
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Math.max(control.width, 180)
                clip: true
                model: control._level0Model
                boundsMovement: Flickable.StopAtBounds
                keyNavigationEnabled: true
                Keys.onRightPressed: control._activateGroup(currentIndex, true)
                Keys.onReturnPressed: control._activateGroup(currentIndex, true)
                Keys.onEnterPressed: control._activateGroup(currentIndex, true)
                ScrollBar.vertical: QuiScrollBar {}
                delegate: QuiItemDelegate {
                    required property var modelData
                    required property int index
                    width: level0List.width
                    height: 32
                    text: modelData.label
                    highlighted: level0List.currentIndex === index
                    hoverEnabled: true
                    font: control.font
                    rightPadding: modelData.expandable ? 28 : 10
                    contentItem: QuiText {
                        text: modelData.label
                        font: control.font
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                    onHoveredChanged: { if (hovered) control._activateGroup(index, false) }
                    onClicked: control._activateGroup(index, true)
                    QuiTextIcon {
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        visible: modelData.expandable
                        iconSource: QuiFontIcon.ChevronRightMed
                        iconSize: 13
                    }
                }
            }
            ListView {
                id: level1List
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Math.max(control.width, 180)
                visible: control._hasGroups
                clip: true
                model: control._level1Model
                boundsMovement: Flickable.StopAtBounds
                keyNavigationEnabled: true
                Keys.onLeftPressed: level0List.forceActiveFocus()
                Keys.onReturnPressed: { if (currentIndex >= 0) control._commitValue(model[currentIndex].value) }
                Keys.onEnterPressed: { if (currentIndex >= 0) control._commitValue(model[currentIndex].value) }
                ScrollBar.vertical: QuiScrollBar {}
                delegate: QuiItemDelegate {
                    required property var modelData
                    required property int index
                    width: level1List.width
                    height: 32
                    text: modelData.label
                    highlighted: level1List.currentIndex === index
                    hoverEnabled: true
                    font: control.font
                    rightPadding: modelData.value === control.savedValue ? 28 : 10
                    contentItem: QuiText {
                        text: modelData.label
                        font: control.font
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                    onHoveredChanged: { if (hovered) level1List.currentIndex = index }
                    onClicked: control._commitValue(modelData.value)
                    QuiTextIcon {
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        visible: modelData.value === control.savedValue
                        iconSource: QuiFontIcon.CheckMark
                        iconSize: 13
                    }
                }
            }
        }
        background: Rectangle {
            color: QuiColor.Primary
            border.color: Qt.darker(QuiColor.Primary, 1.2)
            border.width: 1
            radius: 5
        }
    }
}

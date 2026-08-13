import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Templates as T
import quickui

/**
 * 两级下拉组合框：一级为普通项或可展开项，点击可展开项后在右侧横向展开二级子项。
 *
 * optionGroups 为两级结构：[{label, value, subOptions: [{label, value}]}]
 * - 一级项带 subOptions 时显示展开箭头，点击后在右侧展开二级子项；
 * - 叶子项（value 非空）点击后发送 commit(value)。
 *
 * 复用 QuiComboBox 的标准机制：扁平化列表作为 model（textRole 显示
 * displayLabel，valueRole 取 value），内容框显示由引擎的 currentIndex/
 * displayText 驱动；savedValue 用于打开时定位已选项。
 */
QuiComboBox {
    id: control

    property var optionGroups: []
    property string savedValue: ""
    signal aboutToOpen()

    model: _flatModel
    textRole: "displayLabel"
    valueRole: "value"

    property var _flatModel: []
    property var _level0Model: []
    property var _level1Model: []
    property int _expandedIndex: -1

    function _stringValue(value) {
        return value === undefined || value === null ? "" : String(value)
    }

    function _rebuildLevels() {
        const l0 = []
        for (let i = 0; i < optionGroups.length; ++i) {
            const entry = optionGroups[i]
            const subs = entry.subOptions || []
            l0.push({
                label: String(entry.label),
                value: _stringValue(entry.value),
                expandable: subs.length > 0,
            })
        }
        _level0Model = l0

        if (_expandedIndex >= 0 && _expandedIndex < optionGroups.length) {
            const subs = optionGroups[_expandedIndex].subOptions || []
            const l1 = []
            for (let j = 0; j < subs.length; ++j) {
                l1.push({ label: String(subs[j].label), value: _stringValue(subs[j].value) })
            }
            _level1Model = l1
        } else {
            _level1Model = []
            _expandedIndex = -1
        }
    }

    function _flatten() {
        const flat = []
        for (let i = 0; i < optionGroups.length; ++i) {
            const entry = optionGroups[i]
            const subs = entry.subOptions || []
            const label = String(entry.label)
            flat.push({
                label: label,
                displayLabel: label,
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
        // 保持当前展开状态重建扁平列表，确保二级项也在其中可被定位。
        _flatten()
        for (let i = 0; i < _flatModel.length; ++i) {
            if (String(_flatModel[i].value) === value) {
                currentIndex = i
                break
            }
        }
        control.commit(value)
        popup.close()
    }

    onOptionGroupsChanged: {
        _rebuildLevels()
        _flatten()
    }

    onSavedValueChanged: {
        // 未展开时跟随外部值变化（模型切换/参数联动）重定位显示。
        if (!popup.opened)
            _flatten()
    }

    popup: T.Popup {
        id: popup
        y: control.height
        width: Math.max(control.width, level0List.implicitWidth)
        height: Math.min(level0List.contentHeight + 8,
                         Math.max(0, (control.Window ? control.Window.height : level0List.contentHeight) - 40))
        topMargin: 6
        bottomMargin: 6

        onAboutToShow: {
            control.aboutToOpen()
            control._expandedIndex = -1
            control._rebuildLevels()
            control._flatten()
        }

        onOpened: {
            if (control._level1Model.length > 0)
                subPopup.open()
        }
        onClosed: subPopup.close()

        contentItem: ListView {
            id: level0List
            clip: true
            implicitHeight: contentHeight
            model: control._level0Model
            boundsMovement: Flickable.StopAtBounds

            delegate: Item {
                width: level0List.width
                height: 32
                implicitWidth: Math.max(level0Text.implicitWidth + 16 + 26, 150)

                required property var modelData

                onImplicitWidthChanged: {
                    level0List.implicitWidth = Math.max(level0List.implicitWidth, implicitWidth)
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 3
                    color: level0Hover.hovered ? QuiColor.Hovered : "transparent"
                }

                HoverHandler {
                    id: level0Hover
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onHoveredChanged: {
                        // 悬浮一级项即展开/收起二级菜单。
                        if (!hovered)
                            return
                        if (modelData.expandable) {
                            control._expandedIndex = index
                            control._rebuildLevels()
                            subPopup.open()
                        } else {
                            control._expandedIndex = -1
                            control._rebuildLevels()
                            subPopup.close()
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.expandable) {
                            control._expandedIndex = index
                            control._rebuildLevels()
                            subPopup.open()
                        } else if (modelData.value.length > 0) {
                            control._commitValue(modelData.value)
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 6
                    spacing: 6

                    QuiText {
                        id: level0Text
                        Layout.fillWidth: true
                        text: modelData.label
                        elide: Text.ElideRight
                        font: QuiFont.Body
                        color: modelData.value.length > 0 && modelData.value === control.savedValue
                               ? QuiColor.Highlight : QuiColor.FontPrimary
                    }

                    QuiTextIcon {
                        Layout.preferredWidth: 16
                        visible: modelData.expandable
                        iconSource: QuiFontIcon.ChevronRightMed
                        iconColor: QuiColor.FontPrimary
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

    T.Popup {
        id: subPopup
        x: popup.x + popup.width
        y: popup.y
        width: Math.max(level1List.implicitWidth, 130)
        height: Math.min(level1List.contentHeight + 8,
                         Math.max(0, (control.Window ? control.Window.height : level1List.contentHeight) - 40))
        topMargin: 6
        bottomMargin: 6

        onClosed: {
            // 二级菜单单独被关闭（点击外部）时，一级菜单一并收起，行为与整体菜单一致。
            popup.close()
        }

        contentItem: ListView {
            id: level1List
            clip: true
            implicitHeight: contentHeight
            model: control._level1Model
            boundsMovement: Flickable.StopAtBounds

            delegate: Item {
                width: level1List.width
                height: 32
                implicitWidth: Math.max(level1Text.implicitWidth + 16 + 26, 130)

                required property var modelData

                onImplicitWidthChanged: {
                    level1List.implicitWidth = Math.max(level1List.implicitWidth, implicitWidth)
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 3
                    color: level1Hover.hovered ? QuiColor.Hovered : "transparent"
                }

                HoverHandler {
                    id: level1Hover
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.value.length > 0) {
                            control._commitValue(modelData.value)
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 6
                    spacing: 6

                    QuiText {
                        id: level1Text
                        Layout.fillWidth: true
                        text: modelData.label
                        elide: Text.ElideRight
                        font: QuiFont.Body
                        color: modelData.value === control.savedValue ? QuiColor.Highlight : QuiColor.FontPrimary
                    }

                    QuiTextIcon {
                        Layout.preferredWidth: 16
                        visible: modelData.value === control.savedValue
                        iconSource: QuiFontIcon.CheckMark
                        iconColor: QuiColor.Highlight
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

import QtQuick
import QtTest
import quickui

Item {
    id: root
    width: 640
    height: 400

    Component {
        id: comboBoxComponent
        QuiComboBox {
            editable: true
            model: ["Alpha", "Beta"]
        }
    }

    Component {
        id: containerComponent
        Item { width: 640; height: 400 }
    }

    TestCase {
        name: "QuiComboBoxTest"
        when: windowShown

        function visibleText(item, text) {
            if (item.visible && item.text === text) return item
            for (const child of item.children) {
                const match = visibleText(child, text)
                if (match) return match
            }
            return null
        }

        function test_groupedSelectionAndSiblingNavigation() {
            const combo = createTemporaryObject(groupComboComponent, root)
            verify(combo !== null)
            const committed = []
            combo.commit.connect(function(value) { committed.push(value) })
            const scene = root.Window.window.contentItem
            mouseClick(combo, combo.width / 2, combo.height / 2)
            tryCompare(combo.popup, "visible", true)
            const group = visibleText(combo.popup.contentItem, "Source")
            verify(group !== null)
            mouseClick(group, group.width / 2, group.height / 2)
            tryVerify(function() { return visibleText(scene, "Output") !== null })
            const output = visibleText(scene, "Output")
            verify(visibleText(combo.popup.contentItem, "Output") !== null,
                   "both selection columns must belong to the same popup content")
            mouseClick(output, output.width / 2, output.height / 2)
            compare(committed.length, 1)
            compare(committed[0], "source/output")
            tryCompare(combo.popup, "visible", false)
            compare(combo.currentValue, "source/output")

            mouseClick(combo, combo.width / 2, combo.height / 2)
            const nextGroup = visibleText(combo.popup.contentItem, "Source")
            verify(nextGroup !== null)
            mouseMove(nextGroup, nextGroup.width / 2, nextGroup.height / 2)
            tryVerify(function() { return visibleText(scene, "Output") !== null })
            tryVerify(function() { return visibleText(scene, "Clear") !== null })
            const clear = visibleText(scene, "Clear")
            verify(clear !== null)
            mouseMove(clear, clear.width / 2, clear.height / 2)
            wait(30)
            verify(combo.popup.visible)
            mouseClick(clear, clear.width / 2, clear.height / 2)
            compare(committed.length, 2)
            compare(committed[1], "clear")
        }

        function test_groupedSelectionDisabledWhileOpen_data() {
            return [{ tag: "control", ancestor: false }, { tag: "ancestor", ancestor: true }]
        }

        function test_groupedSelectionDisabledWhileOpen(data) {
            const container = createTemporaryObject(containerComponent, root)
            const combo = createTemporaryObject(groupComboComponent, container)
            const committed = []
            combo.commit.connect(function(value) { committed.push(value) })
            combo.savedValue = "clear"
            const selected = combo.currentIndex
            const scene = root.Window.window.contentItem
            mouseClick(combo, combo.width / 2, combo.height / 2)
            tryCompare(combo.popup, "visible", true)
            const group = visibleText(combo.popup.contentItem, "Source")
            verify(group !== null)
            mouseClick(group, group.width / 2, group.height / 2)
            tryVerify(function() { return visibleText(scene, "Output") !== null })
            if (data.ancestor) container.enabled = false
            else combo.enabled = false
            wait(30)
            const output = visibleText(scene, "Output")
            if (output !== null)
                mouseClick(output, output.width / 2, output.height / 2)
            wait(30)
            compare(committed.length, 0)
            compare(combo.currentIndex, selected)
            if (combo.popup.visible) combo.popup.close()
        }

        function test_groupedWindowEdgeFit() {
            const combo = createTemporaryObject(groupComboComponent, root, { x: root.width - 240, y: 64 })
            mouseClick(combo, combo.width / 2, combo.height / 2)
            tryCompare(combo.popup, "opened", true)
            tryVerify(function() {
                const item = combo.popup.contentItem
                const start = item.mapToItem(root, 0, 0)
                const end = item.mapToItem(root, item.width, item.height)
                return start.x >= 4 && start.y >= 4 && end.x <= root.width - 4 && end.y <= root.height - 4
            }, 1000, "the complete two-column popup must fit inside its window")
        }

        function test_groupedRejectedCommit() {
            const combo = createTemporaryObject(groupComboComponent, root)
            combo.savedValue = "clear"
            const selected = combo.currentIndex
            const committed = []
            combo.commit.connect(function(value) { committed.push(value) })
            combo.commitValue = function(value) { return false }
            mouseClick(combo, combo.width / 2, combo.height / 2)
            const group = visibleText(combo.popup.contentItem, "Source")
            verify(group !== null)
            mouseClick(group, group.width / 2, group.height / 2)
            const output = visibleText(combo.popup.contentItem, "Output")
            verify(output !== null)
            mouseClick(output, output.width / 2, output.height / 2)
            compare(combo.currentIndex, selected)
            compare(combo.savedValue, "clear")
            compare(committed.length, 0)
            verify(combo.popup.visible)
            combo.commitValue = function(value) { combo.savedValue = value; return true }
            mouseClick(output, output.width / 2, output.height / 2)
            compare(committed.length, 1)
            compare(combo.savedValue, "source/output")
            tryCompare(combo.popup, "visible", false)
        }

        function test_groupedKeyboardAndDismissal() {
            const combo = createTemporaryObject(groupComboComponent, root)
            const committed = []
            combo.commit.connect(function(value) { committed.push(value) })
            mouseClick(combo, combo.width / 2, combo.height / 2)
            tryCompare(combo.popup, "opened", true)
            keyClick(Qt.Key_Right)
            keyClick(Qt.Key_Return)
            compare(committed.length, 1)
            compare(committed[0], "source/output")
            tryCompare(combo.popup, "visible", false)
            mouseClick(combo, combo.width / 2, combo.height / 2)
            tryCompare(combo.popup, "opened", true)
            keyClick(Qt.Key_Escape)
            tryCompare(combo.popup, "visible", false)
            compare(committed.length, 1)
            mouseClick(combo, combo.width / 2, combo.height / 2)
            tryCompare(combo.popup, "opened", true)
            mouseClick(root, root.width - 2, root.height - 2)
            tryCompare(combo.popup, "visible", false)
            compare(committed.length, 1)
        }

        function test_commitSignal() {
            const comboBox = createTemporaryObject(comboBoxComponent, root)
            verify(comboBox !== null)

            const committed = []
            comboBox.commit.connect(function(text) {
                committed.push(text)
            })

            comboBox.editText = "Manual"
            const event = { accepted: false }
            comboBox.content.handleCommit(event)

            compare(committed.length, 1)
            compare(committed[0], "Manual")
            verify(event.accepted)
        }
    }

    Component {
        id: groupComboComponent
        QuiGroupComboBox {
            width: 240
            height: 32
            optionGroups: [
                { label: "Source", value: "", subOptions: [{ label: "Output", value: "source/output" }] },
                { label: "Clear", value: "clear", subOptions: [] }
            ]
        }
    }
}


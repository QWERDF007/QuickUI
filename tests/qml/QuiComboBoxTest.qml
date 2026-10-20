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
            mouseClick(output, output.width / 2, output.height / 2)
            compare(committed.length, 1)
            compare(committed[0], "source/output")
            tryCompare(combo.popup, "visible", false)

            mouseClick(combo, combo.width / 2, combo.height / 2)
            const nextGroup = visibleText(combo.popup.contentItem, "Source")
            verify(nextGroup !== null)
            mouseMove(nextGroup, nextGroup.width / 2, nextGroup.height / 2)
            tryVerify(function() { return visibleText(scene, "Output") !== null })
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


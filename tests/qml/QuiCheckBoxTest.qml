import QtQuick
import QtTest
import quickui

Item {
    id: root

    Component {
        id: checkBoxComponent
        QuiCheckBox {
            text: "Enabled"
            animationEnabled: false
        }
    }

    TestCase {
        name: "QuiCheckBoxTest"
        when: windowShown

        function test_statesAliasesAndListenerBoundary() {
            const checkBox = createTemporaryObject(checkBoxComponent, root)
            verify(checkBox !== null)

            compare(checkBox.checkState, Qt.Unchecked)
            checkBox.bordercheckedColor = "#ff0000"
            compare(checkBox.borderCheckedColor.toString(), "#ff0000")
            checkBox.checkedPreesedColor = "#0000ff"
            compare(checkBox.checkedPressedColor.toString(), "#0000ff")

            let calls = 0
            checkBox.clickListener = function() { calls += 1 }
            checkBox.width = 120
            checkBox.height = 32
            checkBox.checked = true
            compare(calls, 1)

            checkBox.clickListener = null
            checkBox.checked = false
            compare(calls, 1)

            checkBox.checkState = Qt.PartiallyChecked
            compare(checkBox.checkState, Qt.PartiallyChecked)
            checkBox.size = 4
            compare(checkBox.indicator.width, 4)
        }
    }
}


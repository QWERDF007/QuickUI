import QtQuick
import QtTest
import quickui

Item {
    id: root

    Component {
        id: buttonComponent
        QuiButton {
            text: "Apply"
            checkable: true
        }
    }

    TestCase {
        name: "QuiButtonTest"
        when: windowShown

        function test_defaultAndCheckedColors() {
            const button = createTemporaryObject(buttonComponent, root)
            verify(button !== null)

            compare(button.normalColor.toString(), QuiColor.Button.toString())
            button.checked = true
            compare(button.normalColor.toString(), QuiColor.Highlight.toString())
            button.enabled = false
            compare(button.opacity, 0.3)
        }

        function test_enterKeysTriggerClick() {
            const button = createTemporaryObject(buttonComponent, root)
            verify(button !== null)

            let clickCount = 0
            button.clicked.connect(function() {
                clickCount += 1
            })
            button.forceActiveFocus()
            tryCompare(button, "activeFocus", true)

            keyPress(Qt.Key_Return)
            compare(clickCount, 1)
            verify(button.checked)
            keyPress(Qt.Key_Enter)
            compare(clickCount, 2)
            verify(!button.checked)
        }
    }
}


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
    }
}


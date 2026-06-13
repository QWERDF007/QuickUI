import QtQuick
import QtQuick.Controls
import QtTest
import quickui

Item {
    id: root

    Component {
        id: textFieldComponent
        QuiTextField {
            text: "field"
            placeholderText: "placeholder"
        }
    }

    Component {
        id: textInputComponent
        QuiTextInput {
            text: "input"
        }
    }

    Component {
        id: textAreaComponent
        QuiTextArea {
            text: "line1\nline2"
        }
    }

    Component {
        id: textBoxBackgroundComponent
        Item {
            width: 0
            height: 0
            TextInput {
                id: input
            }
            QuiTextBoxBackground {
                id: background
                width: parent.width
                height: parent.height
                inputItem: input
            }
            property alias background: background
            property alias input: input
        }
    }

    TestCase {
        name: "QuiInputControlsTest"
        when: windowShown

        function test_textFieldDefaultsAndAliases() {
            const field = createTemporaryObject(textFieldComponent, root)
            verify(field !== null)

            compare(field.text, "field")
            compare(field.textColor.toString(), QuiColor.FontPrimary.toString())
            field.textColor = "#ff0000"
            compare(field.color.toString(), "#ff0000")
            compare(field.selectionColor.toString(), QuiColor.Highlight.toString())
            verify(field.selectByMouse)
        }

        function test_textInputDefaultsAndAliases() {
            const input = createTemporaryObject(textInputComponent, root)
            verify(input !== null)

            compare(input.text, "input")
            compare(input.textColor.toString(), QuiColor.FontPrimary.toString())
            input.textColor = "#00ff00"
            compare(input.color.toString(), "#00ff00")
            verify(input.selectByMouse)
        }

        function test_textAreaDefaults() {
            const area = createTemporaryObject(textAreaComponent, root)
            verify(area !== null)

            compare(area.text, "line1\nline2")
            compare(area.color.toString(), QuiColor.FontPrimary.toString())
            compare(area.selectionColor.toString(), QuiColor.Highlight.toString())
        }

        function test_textBoxBackgroundZeroSizeAndFocusBinding() {
            const item = createTemporaryObject(textBoxBackgroundComponent, root)
            verify(item !== null)

            compare(item.background.width, 0)
            compare(item.background.height, 0)
            verify(item.background.inputItem === item.input)
            compare(item.background.bottomMargin, 1)
        }
    }
}


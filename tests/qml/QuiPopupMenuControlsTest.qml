import QtQuick
import QtQuick.Controls
import QtTest
import quickui

Item {
    id: root
    width: 320
    height: 240

    Component {
        id: popupComponent
        QuiPopup {
            width: 120
            height: 80
            maskOpacity: 0.25
        }
    }

    Component {
        id: tooltipComponent
        Item {
            width: 80
            height: 30
            QuiToolTip {
                id: tooltip
                text: "Tip"
            }
            property alias tooltip: tooltip
        }
    }

    Component {
        id: menuComponent
        QuiMenu {
            animationEnabled: false
            QuiMenuItem {
                text: "Open"
                iconSource: QuiFontIcon.OpenWith
                checkable: true
                checked: true
            }
        }
    }

    Component {
        id: menuItemComponent
        QuiMenuItem {
            text: "Checked"
            iconSource: QuiFontIcon.CheckMark
            checkable: true
            checked: true
        }
    }

    Component {
        id: dialogComponent
        QuiContentDialog {
            title: "Title"
            message: "Message"
            useNeutralButton: true
        }
    }

    Component {
        id: editorComponent
        QuiEditor {
            description: "Name"
            text: "Initial"
        }
    }

    TestCase {
        name: "QuiPopupMenuControlsTest"
        when: windowShown

        function test_popupOpenCloseAndMask() {
            const popup = createTemporaryObject(popupComponent, root)
            verify(popup !== null)

            popup.parent = root
            compare(popup.maskOpacity, 0.25)
            compare(popup.modal, true)
            popup.open()
            tryCompare(popup, "opened", true)
            popup.close()
            tryCompare(popup, "opened", false)
        }

        function test_toolTipContent() {
            const item = createTemporaryObject(tooltipComponent, root)
            verify(item !== null)

            compare(item.tooltip.text, "Tip")
            compare(item.tooltip.padding, 6)
            verify(item.tooltip.implicitWidth >= 0)
        }

        function test_menuAndMenuItemCreation() {
            const menu = createTemporaryObject(menuComponent, root)
            verify(menu !== null)

            compare(menu.animationEnabled, false)
            compare(menu.count, 1)
            verify(menu.itemAt(0).checked)

            const item = createTemporaryObject(menuItemComponent, root)
            verify(item !== null)
            compare(item.text, "Checked")
            verify(item.checked)
            compare(item.iconSource, QuiFontIcon.CheckMark)
        }

        function test_contentDialogPropertiesAndSignals() {
            const dialog = createTemporaryObject(dialogComponent, root)
            verify(dialog !== null)

            compare(dialog.title, "Title")
            compare(dialog.message, "Message")
            verify(dialog.useNeutralButton)

            let positiveClickCount = 0
            dialog.positiveClicked.connect(function() {
                positiveClickCount += 1
            })
            dialog.positiveClicked()
            compare(positiveClickCount, 1)
        }

        function test_editorAliasesAndSignal() {
            const editor = createTemporaryObject(editorComponent, root)
            verify(editor !== null)

            compare(editor.description, "Name")
            compare(editor.text, "Initial")
            editor.text = "Changed"
            compare(editor.text, "Changed")

            let editTextChangedCount = 0
            let latestText = ""
            editor.editTextChanged.connect(function(text) {
                editTextChangedCount += 1
                latestText = text
            })
            editor.editTextChanged(editor.text)
            compare(editTextChangedCount, 1)
            compare(latestText, "Changed")
        }
    }
}

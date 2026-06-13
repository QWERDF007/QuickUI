import QtQuick
import QtQuick.Controls
import QtTest
import quickui

Item {
    id: root

    Component {
        id: filledButtonComponent
        QuiFilledButton {
            text: "Confirm"
        }
    }

    Component {
        id: textIconButtonComponent
        QuiTextIconButton {
            text: "Add"
            iconSource: QuiFontIcon.Add
        }
    }

    Component {
        id: toggleSwitchComponent
        QuiToggleSwitch {
            width: 120
            height: 32
            text: "Enabled"
        }
    }

    Component {
        id: infoBadgeComponent
        QuiInfoBadge {
            count: 120
            max: 99
        }
    }

    Component {
        id: progressBarComponent
        QuiProgressBar {
            value: 0.25
            width: 200
            height: 20
        }
    }

    TestCase {
        name: "QuiButtonIndicatorControlsTest"
        when: windowShown

        function test_filledButtonStates() {
            const button = createTemporaryObject(filledButtonComponent, root)
            verify(button !== null)

            compare(button.normalColor.toString(), QuiColor.Button.toString())
            compare(button.textColor.toString(), "#ffffff")
            button.enabled = false
            compare(button.opacity, 0.3)
        }

        function test_textIconButtonDisplayAndColors() {
            const button = createTemporaryObject(textIconButtonComponent, root)
            verify(button !== null)

            compare(button.iconSource, QuiFontIcon.Add)
            compare(button.display, Button.IconOnly)
            verify(button.hostingPopupOpen)
            button.display = Button.TextBesideIcon
            compare(button.display, Button.TextBesideIcon)
            button.enabled = false
            compare(button.iconColor.toString(), "#6e6e6e")
        }

        function test_toggleSwitchListenerAndDisabledColors() {
            const toggle = createTemporaryObject(toggleSwitchComponent, root)
            verify(toggle !== null)

            compare(toggle.checked, false)
            toggle.clickListener()
            compare(toggle.checked, true)
            toggle.clickListener()
            compare(toggle.checked, false)

            toggle.enabled = false
            compare(toggle.textColor.toString(), "#a1a1a1")
        }

        function test_infoBadgeOverflowText() {
            const badge = createTemporaryObject(infoBadgeComponent, root)
            verify(badge !== null)

            compare(badge.text.text, "99+")
            badge.count = 3
            compare(badge.text.text, "3")
            compare(badge.icon.iconSource, QuiFontIcon.Info)
        }

        function test_progressBarDeterminateAndIndeterminate() {
            const bar = createTemporaryObject(progressBarComponent, root)
            verify(bar !== null)

            compare(bar.value, 0.25)
            compare(bar.textVisible, true)
            compare(bar.progressVisible, false)
            bar.indeterminate = true
            verify(bar.indeterminate)
            bar.indeterminate = false
            verify(!bar.indeterminate)
        }
    }
}


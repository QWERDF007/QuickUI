import QtQuick
import QtTest
import quickui

Item {
    id: root

    Component {
        id: iconComponent
        QuiTextIcon {
            iconSource: QuiFontIcon.ChevronDown
            iconSize: 20
        }
    }

    Component {
        id: backgroundComponent
        QuiControlBackground {
            width: 0
            height: 0
        }
    }

    TestCase {
        name: "QuiPrimitiveControlsTest"
        when: windowShown

        function test_textIconAndBackgroundBoundaries() {
            const icon = createTemporaryObject(iconComponent, root)
            verify(icon !== null)
            compare(icon.text.charCodeAt(0), QuiFontIcon.ChevronDown)
            icon.iconSource = 0
            compare(icon.text, "")

            const background = createTemporaryObject(backgroundComponent, root)
            verify(background !== null)
            compare(background.width, 0)
            compare(background.height, 0)
        }
    }
}


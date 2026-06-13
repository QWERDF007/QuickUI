import QtQuick
import QtQuick.Controls
import QtTest
import quickui

Item {
    id: root

    Component {
        id: focusRectangleComponent
        Item {
            width: 48
            height: 32
            QuiFocusRectangle {
                id: focusRectangle
                radius: 9
                focusColor: "#123456"
            }
            property alias focusRectangle: focusRectangle
        }
    }

    Component {
        id: shadowComponent
        Item {
            width: 60
            height: 40
            QuiShadow {
                id: shadow
                elevation: 3
                radius: 6
                color: "#222222"
            }
            property alias shadow: shadow
        }
    }

    Component {
        id: itemDelegateComponent
        QuiItemDelegate {
            text: "Choice"
        }
    }

    Component {
        id: textComponent
        QuiText {
            text: "Body"
        }
    }

    TestCase {
        name: "QuiBasicDecorationsTest"
        when: windowShown

        function test_focusRectangleFillsParentAndExposesColors() {
            const item = createTemporaryObject(focusRectangleComponent, root)
            verify(item !== null)

            compare(item.focusRectangle.width, item.width)
            compare(item.focusRectangle.height, item.height)
            compare(item.focusRectangle.radius, 9)
            compare(item.focusRectangle.focusColor.toString(), "#123456")
        }

        function test_shadowAcceptsZeroAndNegativeElevation() {
            const item = createTemporaryObject(shadowComponent, root)
            verify(item !== null)

            compare(item.shadow.width, item.width)
            compare(item.shadow.height, item.height)
            compare(item.shadow.elevation, 3)
            compare(item.shadow.radius, 6)
            compare(item.shadow.color.toString(), "#222222")

            item.shadow.elevation = 0
            compare(item.shadow.elevation, 0)
            item.shadow.elevation = -1
            compare(item.shadow.elevation, -1)
        }

        function test_itemDelegateContentAndHighlightStates() {
            const delegate = createTemporaryObject(itemDelegateComponent, root)
            verify(delegate !== null)

            compare(delegate.text, "Choice")
            compare(delegate.padding, 0)
            compare(delegate.verticalPadding, 8)
            compare(delegate.horizontalPadding, 10)
            compare(delegate.contentItem.text, "Choice")
            verify(!delegate.background.visible)

            delegate.highlighted = true
            verify(delegate.background.visible)
        }

        function test_textUsesQuickUiFontAndColorAliases() {
            const text = createTemporaryObject(textComponent, root)
            verify(text !== null)

            compare(text.text, "Body")
            compare(text.font.pixelSize, QuiFont.Body.pixelSize)
            compare(text.textColor.toString(), QuiColor.FontPrimary.toString())
            text.textColor = "#ff00ff"
            compare(text.color.toString(), "#ff00ff")
        }
    }
}

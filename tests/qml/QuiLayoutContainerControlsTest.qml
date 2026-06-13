import QtQuick
import QtQuick.Controls
import QtTest
import quickui

Item {
    id: root

    Component {
        id: pageComponent
        QuiPage {
            title: "Overview"
            animationEnabled: false
        }
    }

    Component {
        id: scrollablePageComponent
        QuiScrollablePage {
            width: 200
            height: 120
            Rectangle {
                width: 100
                height: 300
            }
        }
    }

    Component {
        id: expanderComponent
        QuiExpander {
            headerText: "Details"
            contentHeight: 80
            Rectangle {
                width: 20
                height: 20
            }
        }
    }

    Component {
        id: tabButtonComponent
        QuiTabButton {
            text: "Tab"
        }
    }

    Component {
        id: loaderComponent
        QuiLoader {
            sourceComponent: Rectangle {
                width: 10
                height: 20
            }
        }
    }

    TestCase {
        name: "QuiLayoutContainerControlsTest"
        when: windowShown

        function test_pageHeaderAndAnimationFlags() {
            const page = createTemporaryObject(pageComponent, root)
            verify(page !== null)

            compare(page.title, "Overview")
            compare(page.animationEnabled, false)
            compare(page.opacity, 1)
        }

        function test_scrollablePageAcceptsContent() {
            const page = createTemporaryObject(scrollablePageComponent, root)
            verify(page !== null)

            compare(page.width, 200)
            compare(page.height, 120)
            verify(page.content.length > 0)
        }

        function test_expanderStateAndContentHeight() {
            const expander = createTemporaryObject(expanderComponent, root)
            verify(expander !== null)

            compare(expander.headerText, "Details")
            compare(expander.expand, false)
            expander.expand = true
            compare(expander.expand, true)
            compare(expander.contentHeight, 80)
        }

        function test_tabButtonColorsAndDisabledOpacity() {
            const tab = createTemporaryObject(tabButtonComponent, root)
            verify(tab !== null)

            compare(tab.text, "Tab")
            compare(tab.normalColor.toString(), QuiColor.Primary.toString())
            tab.enabled = false
            verify(tab.contentItem.opacity < 1)
        }

        function test_loaderCreatesAndClearsItem() {
            const loader = createTemporaryObject(loaderComponent, root)
            verify(loader !== null)
            compare(loader.status, Loader.Ready)
            verify(loader.item !== null)
            loader.sourceComponent = undefined
            compare(loader.status, Loader.Null)
        }
    }
}


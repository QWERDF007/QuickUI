import QtQuick
import QtQuick.Controls
import QtTest
import quickui

Item {
    id: root

    Component {
        id: sliderComponent
        QuiSlider {
            from: 0
            to: 10
            value: 5
            precision: 1
            width: 200
        }
    }

    Component {
        id: spinEditorComponent
        QuiSpinEditor {
            value: 5
            minValue: 0
            maxValue: 10
            step: 2
            decimals: 1
        }
    }

    Component {
        id: scrollBarComponent
        QuiScrollBar {
            orientation: Qt.Vertical
            width: 12
            height: 100
            size: 0.5
        }
    }

    Component {
        id: splitViewComponent
        QuiSplitView {
            width: 200
            height: 100
            orientation: Qt.Horizontal
            Item { SplitView.preferredWidth: 80 }
            Item { SplitView.preferredWidth: 120 }
        }
    }

    TestCase {
        name: "QuiNumericScrollControlsTest"
        when: windowShown

        function test_sliderDefaultsAndPrecision() {
            const slider = createTemporaryObject(sliderComponent, root)
            verify(slider !== null)

            compare(slider.value, 5)
            compare(slider.text, "5")
            compare(slider.tooltipEnabled, true)
            slider.value = 2.5
            compare(slider.value, 2.5)
        }

        function test_spinEditorFormattingClampingAndSignals() {
            const editor = createTemporaryObject(spinEditorComponent, root)
            verify(editor !== null)

            compare(editor.formatValue(2), "2.0")
            compare(editor.clampValue(-1), 0)
            compare(editor.clampValue(11), 10)

            let editingFinishedCount = 0
            editor.editingFinished.connect(function() {
                editingFinishedCount += 1
            })
            editor.applyValue(20)
            compare(editor.value, 10)
            editor.editingFinished()
            compare(editingFinishedCount, 1)
        }

        function test_scrollBarOrientationAndSizeBounds() {
            const scrollBar = createTemporaryObject(scrollBarComponent, root)
            verify(scrollBar !== null)

            compare(scrollBar.orientation, Qt.Vertical)
            verify(scrollBar.minimumSize >= 0.3)
            scrollBar.orientation = Qt.Horizontal
            compare(scrollBar.orientation, Qt.Horizontal)
        }

        function test_splitViewHandleConfiguration() {
            const splitView = createTemporaryObject(splitViewComponent, root)
            verify(splitView !== null)

            compare(splitView.backgroundWidth, 4)
            compare(splitView.handleWidth, 2)
            splitView.orientation = Qt.Vertical
            compare(splitView.backgroundHeight, 4)
            compare(splitView.handleHeight, 2)
        }
    }
}

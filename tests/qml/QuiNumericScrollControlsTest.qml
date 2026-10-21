import QtQuick
import QtQuick.Controls
import QtTest
import quickui

Item {
    id: root
    width: 360
    height: 160

    Component {
        id: containerComponent
        FocusScope { width: 240; height: 64 }
    }

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
            width: 200
            height: 32
            value: 5
            minValue: 0
            maxValue: 10
            step: 2
            decimals: 1
        }
    }

    Component {
        id: preciseSpinEditorComponent
        QuiSpinEditor {
            width: 200
            height: 32
            value: 0.123456789
            minValue: 0
            maxValue: 1
            step: 0.05
            decimals: 6
        }
    }

    Component {
        id: scrollingEditorComponent
        Flickable {
            width: 240
            height: 100
            contentHeight: 600
            clip: true
            property alias editor: scrollingEditor
            QuiSpinEditor {
                id: scrollingEditor
                width: 200
                height: 32
                value: 5
                minValue: 0
                maxValue: 10
                step: 2
                decimals: 1
            }
        }
    }

    Component {
        id: lifetimeComponent
        Loader { width: 200; height: 32; sourceComponent: spinEditorComponent }
    }

    Component {
        id: stepperFieldComponent
        QuiStepperField {
            width: 200
            height: 32
            text: "5"
            canDecrease: false
            canIncrease: true
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

        function childByName(item, name) {
            for (let i = 0; i < item.children.length; ++i) {
                const child = item.children[i]
                if (child.objectName === name)
                    return child
                const found = childByName(child, name)
                if (found)
                    return found
            }
            return null
        }

        function test_sliderDefaultsAndPrecision() {
            const slider = createTemporaryObject(sliderComponent, root)
            verify(slider !== null)

            compare(slider.value, 5)
            compare(slider.text, "5")
            compare(slider.tooltipEnabled, true)
            slider.value = 2.5
            compare(slider.value, 2.5)
        }

        function test_spinEditorFormattingAndClamping() {
            const editor = createTemporaryObject(spinEditorComponent, root)
            verify(editor !== null)

            compare(editor.formatValue(2), "2")
            compare(editor.formatValue(2.5), "2.5")
            compare(editor.formatValue(-0), "0")
            compare(editor.clampValue(-1), 0)
            compare(editor.clampValue(11), 10)
            compare(editor.text, "5")
        }

        function test_spinEditorButtonsAndKeyboardStep() {
            const editor = createTemporaryObject(spinEditorComponent, root)
            verify(editor !== null)
            const plus = childByName(editor, "stepperPlus")
            const minus = childByName(editor, "stepperMinus")
            verify(plus !== null && minus !== null)

            let finished = 0
            editor.editingFinished.connect(function() { finished += 1 })

            mouseClick(plus, plus.width / 2, plus.height / 2)
            compare(editor.value, 7)
            compare(finished, 1)
            mouseClick(minus, minus.width / 2, minus.height / 2)
            compare(editor.value, 5)
            compare(finished, 2)

            editor.applyValue(10)
            verify(!plus.enabled)
            mouseClick(plus, plus.width / 2, plus.height / 2)
            compare(editor.value, 10)
            compare(finished, 2)
        }

        function test_spinEditorManualInputValidation_data() {
            return [
                { tag: "decimal", text: "7.5", valid: true, value: 7.5 },
                { tag: "scientific", text: "1e1", valid: true, value: 10 },
                { tag: "trailing garbage", text: "7.5abc", valid: false, value: 5 },
                { tag: "extra separator", text: "1.2.3", valid: false, value: 5 },
                { tag: "above maximum", text: "11", valid: false, value: 5 },
                { tag: "below minimum", text: "-1", valid: false, value: 5 },
                { tag: "extra precision", text: "5.55", valid: false, value: 5 },
                { tag: "not a number", text: "NaN", valid: false, value: 5 },
                { tag: "infinity", text: "Infinity", valid: false, value: 5 }
            ]
        }

        function test_spinEditorManualInputValidation(data) {
            const editor = createTemporaryObject(spinEditorComponent, root)
            verify(editor !== null)
            let finished = 0
            editor.editingFinished.connect(function() { finished += 1 })

            editor.inputItem.forceActiveFocus()
            keyClick(Qt.Key_A, Qt.ControlModifier)
            for (const character of data.text)
                keyClick(character)
            compare(editor.text, data.text)
            keyClick(Qt.Key_Return)
            compare(editor.value, data.value)
            compare(editor.invalid, !data.valid)
            compare(finished, data.valid ? 1 : 0)
            root.forceActiveFocus()
            wait(30)
            compare(editor.value, data.value)
            compare(finished, data.valid ? 1 : 0)
            if (!data.valid) {
                editor.inputItem.forceActiveFocus()
                keyClick(Qt.Key_Escape)
                compare(editor.text, "5")
                compare(editor.invalid, false)
                compare(finished, 0)
            }
        }

        function test_spinEditorFractionalUserSteps_data() {
            return [
                { tag: "tenths", value: 0.1, step: 0.1, first: 0.2, second: 0.3 },
                { tag: "negative twentieths", value: -0.2, step: 0.05, first: -0.15, second: -0.1 }
            ]
        }

        function test_spinEditorFractionalUserSteps(data) {
            const editor = createTemporaryObject(spinEditorComponent, root, {
                value: data.value, step: data.step, minValue: -1, maxValue: 1, decimals: 2
            })
            verify(editor !== null)
            let finished = 0
            editor.editingFinished.connect(function() { finished += 1 })
            const plus = childByName(editor, "stepperPlus")
            mouseClick(plus, plus.width / 2, plus.height / 2)
            compare(editor.value, data.first)
            editor.inputItem.forceActiveFocus()
            keyClick(Qt.Key_Up)
            compare(editor.value, data.second)
            keyClick(Qt.Key_Down)
            compare(editor.value, data.first)
            compare(finished, 3)
            editor.enabled = false
            mouseClick(plus, plus.width / 2, plus.height / 2)
            keyClick(Qt.Key_Up)
            compare(editor.value, data.first)
            compare(finished, 3)
        }

        function test_spinEditorStrictRangeAndLargeFiniteValues() {
            const editor = createTemporaryObject(spinEditorComponent, root)
            verify(editor !== null)
            editor.decimals = 15
            editor.maxValue = 5
            editor.inputItem.text = "5.000000000001"
            editor.commitDraft()
            compare(editor.value, 5)
            compare(editor.invalid, true)

            editor.minValue = -Infinity
            editor.maxValue = Infinity
            editor.inputItem.text = "1e300"
            editor.commitDraft()
            compare(editor.value, 1e300)
            compare(editor.invalid, false)
        }

        function test_spinEditorAlignedLabels() {
            const editor = createTemporaryObject(spinEditorComponent, root)
            verify(editor !== null)
            editor.label = "X"
            editor.labelWidth = 48
            verify(waitForPolish(root.Window.window))
            const left = editor.inputItem.mapToItem(editor, 0, 0).x
            editor.label = "宽度"
            verify(waitForPolish(root.Window.window))
            compare(editor.inputItem.mapToItem(editor, 0, 0).x, left)
            editor.label = ""
            verify(waitForPolish(root.Window.window))
            verify(editor.inputItem.mapToItem(editor, 0, 0).x < left)
        }

        function test_spinEditorConsumerRejectsBeforeCommit() {
            const editor = createTemporaryObject(spinEditorComponent, root)
            verify(editor !== null)
            let accepted = false
            let attempts = 0
            let finished = 0
            editor.commitValue = function(number) { attempts += 1; return accepted }
            editor.editingFinished.connect(function() { finished += 1 })
            editor.inputItem.forceActiveFocus()
            editor.text = "7.5"
            editor.commitDraft()
            compare(editor.value, 5)
            compare(editor.text, "7.5")
            compare(editor.invalid, true)
            compare(finished, 0)
            editor.commitDraft()
            compare(attempts, 2)
            compare(editor.value, 5)
            compare(editor.invalid, true)
            accepted = true
            editor.commitDraft()
            compare(editor.value, 7.5)
            compare(editor.invalid, false)
            compare(finished, 1)
            accepted = false
            editor.stepBy(1)
            compare(editor.value, 7.5)
            compare(editor.invalid, true)
            editor.cancelDraft()
            compare(editor.text, "7.5")
            compare(editor.invalid, false)
        }

        function test_spinEditorEscapeRestoresCommittedValue() {
            const editor = createTemporaryObject(spinEditorComponent, root)
            verify(editor !== null)
            let finished = 0
            editor.editingFinished.connect(function() { finished += 1 })

            editor.inputItem.forceActiveFocus()
            editor.inputItem.text = "9"
            keyClick(Qt.Key_Escape)
            compare(editor.text, "5")
            compare(editor.value, 5)
            compare(editor.invalid, false)
            compare(finished, 0)
        }

        function test_spinEditorEnterAndBlurCommitOnce() {
            const editor = createTemporaryObject(spinEditorComponent, root)
            verify(editor !== null)
            let finished = 0
            editor.editingFinished.connect(function() { finished += 1 })

            editor.inputItem.forceActiveFocus()
            editor.inputItem.text = "6"
            keyClick(Qt.Key_Return)
            compare(editor.value, 6)
            compare(finished, 1)
            root.forceActiveFocus()
            compare(finished, 1)
        }

        function test_spinEditorDraftThenButtonCommitsOnce() {
            const editor = createTemporaryObject(spinEditorComponent, root)
            verify(editor !== null)
            let finished = 0
            editor.editingFinished.connect(function() { finished += 1 })
            editor.inputItem.forceActiveFocus()
            editor.inputItem.selectAll()
            keyClick(Qt.Key_6)
            const plus = childByName(editor, "stepperPlus")
            mouseClick(plus, plus.width / 2, plus.height / 2)
            compare(editor.value, 8)
            compare(finished, 1)
            root.forceActiveFocus()
            wait(30)
            compare(finished, 1)
        }

        function test_spinEditorBlurCommitsDraft() {
            const editor = createTemporaryObject(spinEditorComponent, root)
            let finished = 0
            editor.editingFinished.connect(function() { finished += 1 })
            editor.inputItem.forceActiveFocus()
            verify(editor.inputItem.activeFocus)
            editor.inputItem.text = "6"
            root.forceActiveFocus()
            tryCompare(editor, "value", 6)
            compare(finished, 1)
        }

        function test_spinEditorDestroyedAfterBlur() {
            const loader = createTemporaryObject(lifetimeComponent, root)
            const editor = loader.item
            verify(editor !== null)
            let finished = 0
            editor.editingFinished.connect(function() { finished += 1 })
            editor.inputItem.forceActiveFocus()
            verify(editor.inputItem.activeFocus)
            editor.inputItem.text = "6"
            root.forceActiveFocus()
            loader.active = false
            wait(30)
            compare(finished, 0)
        }

        function test_spinEditorDisabledDraft_data() {
            return [{ tag: "control", ancestor: false }, { tag: "ancestor", ancestor: true }]
        }

        function test_spinEditorDisabledDraft(data) {
            const container = createTemporaryObject(containerComponent, root)
            const editor = createTemporaryObject(spinEditorComponent, container)
            let finished = 0
            editor.editingFinished.connect(function() { finished += 1 })
            editor.inputItem.forceActiveFocus()
            verify(editor.inputItem.activeFocus)
            editor.inputItem.text = "6"
            if (data.ancestor) container.enabled = false
            else editor.enabled = false
            root.forceActiveFocus()
            wait(30)
            compare(editor.value, 5)
            compare(finished, 0)
        }

        function test_spinEditorProgrammaticValueDoesNotNotify() {
            const editor = createTemporaryObject(spinEditorComponent, root)
            verify(editor !== null)
            let finished = 0
            editor.editingFinished.connect(function() { finished += 1 })

            editor.value = 8
            compare(editor.text, "8")
            compare(finished, 0)
        }

        function test_spinEditorFocusedExternalValueRefresh() {
            const editor = createTemporaryObject(spinEditorComponent, root)
            verify(editor !== null)
            let finished = 0
            editor.editingFinished.connect(function() { finished += 1 })

            editor.inputItem.forceActiveFocus()
            verify(editor.inputItem.activeFocus)
            editor.value = 8
            compare(editor.text, "8")
            keyClick(Qt.Key_Return)
            compare(editor.value, 8)
            compare(finished, 0)
        }

        function test_spinEditorReadOnlyAndWheel() {
            const editor = createTemporaryObject(spinEditorComponent, root)
            verify(editor !== null)
            let finished = 0
            editor.editingFinished.connect(function() { finished += 1 })
            editor.readOnly = true

            editor.inputItem.forceActiveFocus()
            editor.inputItem.text = "9"
            editor.commitDraft()
            compare(editor.value, 5)
            compare(finished, 0)
            const plus = childByName(editor, "stepperPlus")
            verify(!plus.enabled)
            mouseWheel(editor.inputItem, editor.inputItem.width / 2, editor.inputItem.height / 2,
                       0, 120, Qt.NoButton)
            compare(editor.value, 5)
            compare(finished, 0)
        }

        function test_spinEditorUnfocusedWheelScrollsPanel() {
            const panel = createTemporaryObject(scrollingEditorComponent, root)
            verify(panel !== null)
            const editor = panel.editor
            let finished = 0
            editor.editingFinished.connect(function() { finished += 1 })
            root.forceActiveFocus()
            verify(!editor.inputItem.activeFocus)
            mouseWheel(editor.inputItem, editor.inputItem.width / 2, editor.inputItem.height / 2,
                       0, -120, Qt.NoButton)
            tryVerify(function() { return panel.contentY > 0 })
            compare(editor.value, 5)
            compare(finished, 0)
        }

        function test_spinEditorHighPrecisionNotRewritten() {
            const editor = createTemporaryObject(preciseSpinEditorComponent, root)
            verify(editor !== null)
            compare(editor.value, 0.123456789)
            compare(editor.text, "0.123457")
            let finished = 0
            editor.editingFinished.connect(function() { finished += 1 })
            editor.inputItem.forceActiveFocus()
            root.forceActiveFocus()
            compare(editor.value, 0.123456789)
            compare(finished, 0)
        }

        function test_stepperFieldSignalsAndDisabledButtons() {
            const field = createTemporaryObject(stepperFieldComponent, root)
            verify(field !== null)
            let increased = 0
            field.increaseRequested.connect(function() { increased += 1 })
            const plus = childByName(field, "stepperPlus")
            const minus = childByName(field, "stepperMinus")
            verify(plus !== null && minus !== null)
            verify(!minus.enabled)
            mouseClick(plus, plus.width / 2, plus.height / 2)
            compare(increased, 1)
            compare(field.text, "5")
        }

        function test_stepperFieldReadOnlyKeyboard() {
            const field = createTemporaryObject(stepperFieldComponent, root)
            field.canDecrease = true
            field.readOnly = true
            let steps = 0
            let commits = 0
            field.increaseRequested.connect(function() { steps += 1 })
            field.decreaseRequested.connect(function() { steps += 1 })
            field.commitRequested.connect(function() { commits += 1 })
            field.inputItem.forceActiveFocus()
            verify(field.inputItem.activeFocus)
            keyClick(Qt.Key_Up)
            keyClick(Qt.Key_Down)
            keyClick(Qt.Key_9)
            keyClick(Qt.Key_Return)
            root.forceActiveFocus()
            wait(30)
            compare(field.text, "5")
            compare(steps, 0)
            compare(commits, 0)
            verify(!childByName(field, "stepperPlus").enabled)
            verify(!childByName(field, "stepperMinus").enabled)
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

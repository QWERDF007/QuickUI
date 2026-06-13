import QtQuick
import QtTest

Item {
    width: 640
    height: 480

    TestCase {
        name: "QuickUiDummy"

        function test_dummy() {
        }
    }

    QuickUiModuleTest {}
    UtilsTest {}
    QuiButtonTest {}
    QuiCheckBoxTest {}
    QuiComboBoxTest {}
    QuiImageTest {}
    QuiBasicDecorationsTest {}
    QuiPrimitiveControlsTest {}
    QuiInputControlsTest {}
    QuiButtonIndicatorControlsTest {}
    QuiNumericScrollControlsTest {}
    QuiPopupMenuControlsTest {}
    QuiLayoutContainerControlsTest {}
}

import QtQuick
import QtTest
import quickui

Item {
    TestCase {
        name: "QuickUiModuleTest"
        when: windowShown

        function test_singletonsAndEnums() {
            compare(QuiColor.Highlight.toString(), "#009688")
            compare(QuiColor.Transparent.a, 0)
            compare(QuiFont.Body.pixelSize, 16)
            compare(QuiFont.TitleLarge.pixelSize, 40)
            compare(QuiFontIcon.ChevronDown, 0xe70d)
            compare(QuiDialogButtonFlag.PositiveButton, 0x0004)
        }
    }
}


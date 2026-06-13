import QtQuick
import QtTest
import quickui

Item {
    TestCase {
        name: "UtilsTest"
        when: windowShown

        function test_clampAndOpacity() {
            compare(Utils.clamp(-10, 0, 1), 0)
            compare(Utils.clamp(10, 0, 1), 1)
            compare(Utils.clamp(0.25, 0, 1), 0.25)

            const half = Utils.withOpacity(Qt.rgba(1, 0, 0, 1), 0.5)
            compare(half.r, 1)
            compare(half.g, 0)
            compare(half.b, 0)
            fuzzyCompare(half.a, 0.5, 0.001)

            compare(Utils.withOpacity(Qt.rgba(0, 1, 0, 1), -1).a, 0)
            compare(Utils.withOpacity(Qt.rgba(0, 1, 0, 1), 2).a, 1)
        }
    }
}


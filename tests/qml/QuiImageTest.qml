import QtQuick
import QtTest
import quickui

Item {
    id: root

    Component {
        id: imageComponent
        QuiImage {
            width: 0
            height: 0
        }
    }

    TestCase {
        name: "QuiImageTest"
        when: windowShown

        function test_zeroSizedOperationsAreNoops() {
            const imageView = createTemporaryObject(imageComponent, root)
            verify(imageView !== null)

            compare(imageView.stepSize, 0.1)
            compare(imageView.fitInView(), false)
            compare(imageView.scaleInCenter(2), false)
            compare(imageView.scaleImageByWheel({ x: 0, y: 0, angleDelta: { y: 120 } }), false)

            imageView.currentImagePath = "C:/tmp/nonexistent.png"
            verify(String(imageView.source).indexOf("file:///") === 0)
            imageView.currentImagePath = ""
            compare(String(imageView.source), "")
        }
    }
}


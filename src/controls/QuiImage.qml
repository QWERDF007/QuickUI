import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Item {
    id: control

    clip: true

    default property alias children: image.data

    property bool isInit: false
    property bool needFitInView: false
    property bool isDragging: mouseArea.drag.active
    property bool scalable: true

    property alias image: image
    property url source: ""
    property string currentImagePath: ""
    property real brightness: 0.0
    property real contrast: 0.0

    property real imageSourceScale: {
        if (control.width > 0 && control.height > 0 && image.sourceSize.width > 0
                && image.sourceSize.height > 0 && image.source !== Qt.url("")
                && image.status === Image.Ready) {
            return Math.min(control.height / image.sourceSize.height,
                            control.width / image.sourceSize.width)
        }
        return 1.0
    }

    property real stepSize: {
        if (control.width <= 0 || control.height <= 0 || image.sourceSize.width <= 0
                || image.sourceSize.height <= 0) {
            return 0.1
        }

        const baseStep = Math.min(image.sourceSize.width / control.width,
                                  image.sourceSize.height / control.height) * 0.1
        return Math.min(Math.max(baseStep * Math.pow(1.5, image.scale - 2), 0.1), 8.0)
    }

    property var scaledImagePos: mapFromItem(image, 0, 0)

    property real from: 0.25
    property real to: 32

    Image {
        id: image

        visible: false
        smooth: false
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        source: control.source
        transformOrigin: Item.TopLeft

        onXChanged: control.updateImagePos()
        onYChanged: control.updateImagePos()
        onStatusChanged: {
            if (image.status === Image.Ready) {
                if (control.isInit) {
                    control.fitInView()
                } else {
                    control.needFitInView = true
                }
            }
        }
    }

    MultiEffect {
        source: image
        anchors.fill: image
        x: image.x
        y: image.y
        scale: image.scale
        transformOrigin: Item.TopLeft
        brightness: control.brightness
        contrast: control.contrast
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        enabled: control.visible && image.status === Image.Ready
        drag.target: null
        drag.axis: Drag.XAndYAxis
        acceptedButtons: Qt.AllButtons

        onPressed: function(event) {
            if ((event.modifiers & Qt.ControlModifier) || event.button === Qt.MiddleButton) {
                drag.target = image
            } else {
                drag.target = null
            }
        }

        onWheel: function(event) {
            if (control.scalable && control.scaleImageByWheel(event)) {
                control.updateImagePos()
            }
        }
    }

    function scaleInCenter(scale) {
        if (!hasRenderableImage()) {
            return false
        }

        const scaleOrigin = mapToItem(image, 0, 0)
        image.scale = Math.min(Math.max(control.from, scale), control.to)
        const dx = (control.width - image.sourceSize.width * image.scale) / 2
        const dy = (control.height - image.sourceSize.height * image.scale) / 2
        const pos = mapFromItem(image, scaleOrigin)

        image.x -= pos.x
        image.y -= pos.y
        image.x -= scaledImagePos.x - dx
        image.y -= scaledImagePos.y - dy
        return true
    }

    function scaleImageByWheel(wheel) {
        if (!hasRenderableImage() || !wheel || !wheel.angleDelta) {
            return false
        }

        const scaleOrigin = mapToItem(image, wheel.x, wheel.y)
        const step = wheel.angleDelta.y / 120 * control.stepSize
        image.scale = Math.min(Math.max(control.from, image.scale + step), control.to)
        const pos = mapFromItem(image, scaleOrigin)

        image.x -= pos.x - wheel.x
        image.y -= pos.y - wheel.y
        return true
    }

    function updateImagePos() {
        scaledImagePos = mapFromItem(image, 0, 0)
    }

    function fitInView() {
        if (!hasRenderableImage()) {
            return false
        }

        control.imageSourceScale = Math.min(control.height / image.sourceSize.height,
                                            control.width / image.sourceSize.width)
        const scaleOrigin = mapToItem(image, 0, 0)
        image.scale = control.imageSourceScale
        const dx = (control.width - image.sourceSize.width * image.scale) / 2
        const dy = (control.height - image.sourceSize.height * image.scale) / 2
        const pos = mapFromItem(image, scaleOrigin)

        image.x -= pos.x
        image.y -= pos.y
        image.x -= scaledImagePos.x - dx
        image.y -= scaledImagePos.y - dy
        return true
    }

    function hasRenderableImage() {
        return control.width > 0 && control.height > 0 && image.sourceSize.width > 0
                && image.sourceSize.height > 0
    }

    onCurrentImagePathChanged: {
        source = currentImagePath.length > 0 ? "file:///" + currentImagePath : ""
    }

    onVisibleChanged: {
        if (visible && !isInit) {
            isInit = true
        }
    }

    onHeightChanged: {
        if (visible && isInit && needFitInView) {
            if (control.fitInView()) {
                needFitInView = false
            }
        }
    }
}

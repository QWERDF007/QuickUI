import QtQuick
import QtQuick.Controls
import quickui

Item {
    id: control
    clip: true
    width: 200
    height: 200

    property bool _init: false
    property alias image: _image
    property alias status: _image.status
    property alias source: _image.source
    property alias sourceSize: _image.sourceSize
    property alias fillMode: _image.fillMode
    property bool imageDragEnable: false
    property bool isFitInView: true
    property real from: 0.1
    property real to: 32.0

    property real stepSize: {
        if (_image.scale < 2 || _image.paintedWidth * _image.scale < control.width || _image.paintedHeight * _image.scale < control.height) {
            return 0.1
        } else if (_image.scale < 10) {
            return 1.0
        } else {
            return 2.0
        }
    }

    property var scaledImagePos: mapFromItem(_image, 0, 0)
    property real imageSourceScale: {
        if (_image.source !== Qt.url("") && _image.status === Image.Ready && _image.sourceSize.width > 0 && _image.sourceSize.height > 0) {
            return Math.min(control.height / _image.sourceSize.height, control.width / _image.sourceSize.width)
        }
        return 1.0
    }

    // 显示区域映射到图像上的矩形 [x, y, w, h]
    property var imageRect: [0, 0, 0, 0]
    signal updateImageRect()

    onUpdateImageRect: {
        var pt1 = mapToItem(_image, 0, 0)
        var pt2 = mapToItem(_image, control.width, control.height)
        imageRect = [pt1.x, pt1.y, pt2.x - pt1.x, pt2.y - pt1.y]
    }

    default property alias overlayData: _overlayContainer.data

    MouseArea {
        id: mouseArea
        enabled: control.visible && _image.status === Image.Ready
        anchors.fill: parent
        drag.target: control.imageDragEnable ? _image : null
        drag.axis: Drag.XAndYAxis
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons

        onEntered: {
            control.forceActiveFocus()
        }

        onPressed: function (mouse) {
            control.forceActiveFocus()
            if (mouse.button === Qt.MiddleButton || (mouse.button === Qt.LeftButton && (mouse.modifiers & Qt.ControlModifier))) {
                control.imageDragEnable = true
                mouseArea.cursorShape = Qt.ClosedHandCursor
            }
        }

        onReleased: function (mouse) {
            if (control.imageDragEnable) {
                control.imageDragEnable = false
                mouseArea.cursorShape = (mouse.modifiers & Qt.ControlModifier) ? Qt.OpenHandCursor : Qt.ArrowCursor
            }
        }

        onWheel: function (wheel) {
            scaleImageByWheel(wheel)
            updateImagePos()
        }
    }

    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Control) {
            if (mouseArea.containsPress) {
                mouseArea.cursorShape = Qt.ClosedHandCursor
            } else {
                mouseArea.cursorShape = Qt.OpenHandCursor
            }
        } else if (event.key === Qt.Key_Space) {
            fitInView()
        }
    }

    Keys.onReleased: function (event) {
        if (event.key === Qt.Key_Control && !mouseArea.containsPress) {
            mouseArea.cursorShape = Qt.ArrowCursor
        }
    }

    Image {
        id: _image
        smooth: false
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        transformOrigin: Item.TopLeft

        onXChanged: {
            updateImagePos()
            control.updateImageRect()
        }
        onYChanged: {
            updateImagePos()
            control.updateImageRect()
        }
        onScaleChanged: {
            control.updateImageRect()
        }

        onStatusChanged: {
            if (_image.status === Image.Ready) {
                if (control.isFitInView) {
                    fitInView()
                } else {
                    scaleInCenter(1.0)
                }
                control.updateImageRect()
            }
        }

        Item {
            id: _overlayContainer
            anchors.fill: parent
        }
    }

    onWidthChanged: {
        if (isFitInView) {
            fitInView()
        } else if (!_init && width && height) {
            scaleInCenter(1.0)
            _init = true
        }
        control.updateImageRect()
    }

    onHeightChanged: {
        if (isFitInView) {
            fitInView()
        } else if (!_init && width && height) {
            scaleInCenter(1.0)
            _init = true
        }
        control.updateImageRect()
    }

    function scaleInCenter(targetScale) {
        if (control.width === 0 || control.height === 0 || _image.sourceSize.height === 0 || _image.sourceSize.width === 0)
            return

        var scaleOrigin = mapToItem(_image, 0, 0)
        _image.scale = Math.min(Math.max(from, targetScale), to)
        var dx = (control.width - _image.sourceSize.width * _image.scale) / 2
        var dy = (control.height - _image.sourceSize.height * _image.scale) / 2
        var pos = mapFromItem(_image, scaleOrigin)

        _image.x -= pos.x
        _image.y -= pos.y
        _image.x -= scaledImagePos.x - dx
        _image.y -= scaledImagePos.y - dy
    }

    function scaleImageByWheel(wheel) {
        if (control.width === 0 || control.height === 0 || _image.sourceSize.height === 0 || _image.sourceSize.width === 0)
            return

        var scaleOrigin = mapToItem(_image, wheel.x, wheel.y)
        var step = (wheel.angleDelta.y / 120) * control.stepSize
        _image.scale = Math.min(Math.max(from, _image.scale + step), to)

        var pos = mapFromItem(_image, scaleOrigin)
        _image.x -= pos.x - wheel.x
        _image.y -= pos.y - wheel.y
    }

    function updateImagePos() {
        scaledImagePos = mapFromItem(_image, 0, 0)
    }

    function fitInView() {
        if (control.width === 0 || control.height === 0 || _image.sourceSize.height === 0 || _image.sourceSize.width === 0)
            return

        control.imageSourceScale = Math.min(control.height / _image.sourceSize.height, control.width / _image.sourceSize.width)
        var scaleOrigin = mapToItem(_image, 0, 0)
        _image.scale = control.imageSourceScale
        var dx = (control.width - _image.sourceSize.width * _image.scale) / 2
        var dy = (control.height - _image.sourceSize.height * _image.scale) / 2
        var pos = mapFromItem(_image, scaleOrigin)

        _image.x -= pos.x
        _image.y -= pos.y
        _image.x -= scaledImagePos.x - dx
        _image.y -= scaledImagePos.y - dy
    }
}

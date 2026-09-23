import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import quickui

Rectangle {
    id: control

    property var targetItem
    property color itemDisableColor: QuiColor.ItemDisabled
    property color toolbarBorderColor: QuiColor.WindowBackground
    property color toolbarColor: QuiColor.CardBackground
    property url zoomOutIconSource: "/icons/zoomout"
    property url zoomInIconSource: "/icons/zoomin"
    property url fitIconSource: "/icons/aspectratio"
    property bool hasValidTarget: targetItem !== null && targetItem !== undefined && (targetItem.status === undefined || targetItem.status === Image.Ready)

    signal fitRequested()
    signal zoomChanged(real value)

    color: "transparent"
    height: 40
    implicitWidth: toolbar.width + 24

    Rectangle {
        id: toolbar
        anchors.centerIn: parent
        border.color: control.toolbarBorderColor
        border.width: 2
        color: control.enabled ? control.toolbarColor : control.itemDisableColor
        height: 36
        implicitWidth: layout.implicitWidth + 12
        width: implicitWidth
        radius: 3

        RowLayout {
            id: layout
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            enabled: control.hasValidTarget

            Label {
                id: sizeLabel
                Layout.leftMargin: 5
                Layout.preferredWidth: 64
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font: QuiFont.Caption
                color: QuiColor.FontPrimary
                text: {
                    if (control.targetItem && control.targetItem.sourceSize && control.targetItem.sourceSize.width > 0) {
                        return control.targetItem.sourceSize.width + "x" + control.targetItem.sourceSize.height
                    }
                    return ""
                }

                MouseArea {
                    id: sizeMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                }

                QuiToolTip {
                    delay: 500
                    text: qsTr("图像大小 (宽x高)")
                    visible: sizeMouseArea.containsMouse
                }
            }

            QuiToolButton {
                id: zoomOutBtn
                implicitWidth: 32
                implicitHeight: 32
                icon.source: control.zoomOutIconSource
                icon.width: 18
                icon.height: 18
                disableColor: control.itemDisableColor
                onClicked: {
                    slider.decrease()
                    applyScale(slider.value)
                }
            }

            QuiSlider {
                id: slider
                implicitWidth: 100
                implicitHeight: 12
                from: 0.1
                to: 32.0
                stepSize: {
                    if (value < 2) return 0.1
                    if (value < 10) return 1.0
                    return 2.0
                }

                value: {
                    if (!control.targetItem) return 1.0
                    if (control.targetItem.image && control.targetItem.image.scale !== undefined) {
                        return control.targetItem.image.scale
                    }
                    if (control.targetItem.scale !== undefined) {
                        return control.targetItem.scale
                    }
                    return 1.0
                }

                onMoved: {
                    applyScale(slider.value)
                }
            }

            QuiToolButton {
                id: zoomInBtn
                implicitWidth: 32
                implicitHeight: 32
                icon.source: control.zoomInIconSource
                icon.width: 18
                icon.height: 18
                disableColor: control.itemDisableColor
                onClicked: {
                    slider.increase()
                    applyScale(slider.value)
                }
            }

            QuiToolButton {
                id: fitBtn
                implicitWidth: 32
                implicitHeight: 32
                icon.source: control.fitIconSource
                icon.width: 18
                icon.height: 18
                disableColor: control.itemDisableColor
                onClicked: {
                    if (control.targetItem && typeof control.targetItem.fitInView === "function") {
                        control.targetItem.fitInView()
                    }
                    control.fitRequested()
                }

                QuiToolTip {
                    delay: 500
                    text: qsTr("适应窗口大小")
                    visible: fitBtn.hovered
                }
            }

            Label {
                id: percentLabel
                Layout.preferredWidth: 48
                Layout.rightMargin: 5
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font: QuiFont.Caption
                color: QuiColor.FontPrimary
                text: (slider.value * 100).toFixed(2) + "%"

                MouseArea {
                    id: percentMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                }

                QuiToolTip {
                    delay: 500
                    text: qsTr("缩放比例")
                    visible: percentMouseArea.containsMouse
                }
            }
        }
    }

    function applyScale(scaleVal) {
        if (control.targetItem) {
            if (typeof control.targetItem.scaleInCenter === "function") {
                control.targetItem.scaleInCenter(scaleVal)
            } else if (control.targetItem.image) {
                control.targetItem.image.scale = scaleVal
            } else {
                control.targetItem.scale = scaleVal
            }
        }
        control.zoomChanged(scaleVal)
    }
}

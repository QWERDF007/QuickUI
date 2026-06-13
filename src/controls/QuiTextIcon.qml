import QtQuick
import quickui

Text {
    id: control

    property int iconSource: 0
    property color iconColor: QuiColor.FontPrimary
    property int iconSize: 16

    text: iconSource > 0 ? String.fromCharCode(iconSource) : ""
    color: iconColor
    font.family: Qt.platform.os === "windows" ? "Segoe Fluent Icons" : "Segoe UI Symbol"
    font.pixelSize: iconSize
    renderType: Text.NativeRendering
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}

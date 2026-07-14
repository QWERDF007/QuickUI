import QtQuick
import QtQuick.Templates as T

import quickui

T.Frame {
    id: control

    property alias border: frameBackground.border
    property alias color: frameBackground.color
    property alias radius: frameBackground.radius

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            contentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding)
    padding: 0

    background: Rectangle {
        id: frameBackground
        radius: 4
        border.color: QuiColor.Border
        color: QuiColor.Primary
    }
}

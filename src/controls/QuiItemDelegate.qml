import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Templates as T
import quickui

T.ItemDelegate {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding,
                            contentItem.contentWidth)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)
    padding: 0
    verticalPadding: 8
    horizontalPadding: 10
    icon.color: control.palette.text

    contentItem: QuiText {
        text: control.text
        font: control.font
        color: QuiColor.FontPrimary
    }

    background: Rectangle {
        implicitWidth: 100
        implicitHeight: 30
        color: control.highlighted ? (QuiColor.themeMode === QuiColor.Dark ? QuiColor.Hovered : Qt.rgba(0, 0, 0, 0.08)) : QuiColor.Hovered
        visible: control.down || control.highlighted || control.visualFocus || control.hovered
    }
}


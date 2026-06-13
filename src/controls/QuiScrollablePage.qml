import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

QuiPage {
    default property alias content: container.data
    Flickable{
        clip: true
        anchors.fill: parent
        ScrollBar.vertical: QuiScrollBar {
            snapMode: ScrollBar.SnapAlways
        }
        boundsBehavior: Flickable.StopAtBounds
        contentHeight: container.height
        ColumnLayout{
            id:container
            width: parent.width
        }
    }
}

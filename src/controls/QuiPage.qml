import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Window

import quickui

Page {
    property string url : ""
    property bool animationEnabled: true
    id: control
    StackView.onRemoved: destroy()
    padding: 5

    property bool pageShown: false

    visible: !animationEnabled || pageShown
    opacity: !animationEnabled || pageShown ? 1 : 0
    transform: Translate {
        y: !animationEnabled || pageShown ? 0 : 80
        Behavior on y {
            enabled: control.animationEnabled
            NumberAnimation {
                duration: 167
                easing.type: Easing.OutCubic
            }
        }
    }
    Behavior on opacity {
        enabled: control.animationEnabled
        NumberAnimation {
            duration: 83
        }
    }
    background: Item{}
    header: QuiLoader{
        sourceComponent: control.title === "" ? undefined : com_header
    }
    Component{
        id: com_header
        Item{
            implicitHeight: 40
            QuiText{
                id:text_title
                text: control.title
                font: QuiFont.Title
                anchors{
                    left: parent.left
                    leftMargin: 5
                }
            }
        }
    }
    Component.onCompleted: {
        if (animationEnabled) {
            pageShown = true
        }
    }
}

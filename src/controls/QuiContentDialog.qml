import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Window
import quickui

QuiPopup {
    id: control
    property string title: ""
    property string message: ""
    property string neutralText: "鍏抽棴"
    property string negativeText: "鍙栨秷"
    property string positiveText: "纭"
    property bool useNeutralButton: false
    property bool useNegativeButton: true
    property bool usePositiveButton: true
    property int messageTextFormart: Text.AutoText
    property var onNeutralClickListener // 鎸夐挳鐐瑰嚮鐩戝惉
    property var onNegativeClickListener
    property var onPositiveClickListener
    signal neutralClicked
    signal negativeClicked
    signal positiveClicked
    implicitWidth: 400
    implicitHeight: layout_content.height
    focus: true

    property var contentDelegate: Component { // 榛樿鍐呭浠ｇ悊涓烘秷鎭? 鍙噸杞?
        Flickable {
            id:sroll_message
            contentHeight: text_message.height
            contentWidth: width
            clip: true
            boundsBehavior:Flickable.StopAtBounds
            width: parent.width
            // height: message === "" ? 0 : Math.min(text_message.height,300)
            implicitHeight: message === "" ? 0 : Math.min(text_message.height,300)

            ScrollBar.vertical: QuiScrollBar {}
            QuiText { // 娑堟伅
                id: text_message
                font: QuiFont.Body
                wrapMode: Text.WrapAnywhere
                text: message
                width: parent.width
                topPadding: 4
                leftPadding: 20
                rightPadding: 20
                bottomPadding: 4
            }
        }
    }
    Item { // 鍐呭
        id:layout_content
        width: parent.width
        height: layout_column.childrenRect.height
        ColumnLayout{
            id:layout_column
            width: parent.width
            spacing: 0
            QuiText { // 鏍囬
                id:text_title
                Layout.bottomMargin: 10
                font: QuiFont.Title
                text:title
                topPadding: 20
                leftPadding: 20
                rightPadding: 20
                wrapMode: Text.WrapAnywhere
            }
            QuiLoader { // 鍔犺浇鍐呭
                sourceComponent: control.visible ? control.contentDelegate : undefined
                Layout.fillWidth: true
                onStatusChanged: {
                    if(status===Loader.Ready){
                        Layout.preferredHeight = item.implicitHeight
                    }else{
                        Layout.preferredHeight = 0
                    }
                }
            }
            RowLayout{ // 鎿嶄綔鎸夐挳甯冨眬
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                Layout.margins: 10
                spacing: 10
                Item {
                    Layout.fillWidth: true
                }
                QuiButton { // 鍏抽棴鎸夐挳
                    id:neutral_btn
                    visible: useNeutralButton
                    text: neutralText
                    onClicked: {
                        if(control.onNeutralClickListener){
                            control.onNeutralClickListener()
                        }else{
                            neutralClicked()
                            control.close()
                        }
                    }
                }
                QuiButton { // 鍙栨秷鎸夐挳
                    id: negative_btn
                    visible: useNegativeButton
                    text: negativeText
                    onClicked: {
                        if(control.onNegativeClickListener){
                            control.onNegativeClickListener()
                        }else{
                            negativeClicked()
                            control.close()
                        }
                    }
                }
                QuiButton { // 纭鎸夐挳
                    id:positive_btn
                    visible: usePositiveButton
                    text: positiveText
                    onClicked: {
                        if(control.onPositiveClickListener){
                            control.onPositiveClickListener()
                        }else{
                            positiveClicked()
                            control.close()
                        }
                    }
                }
            }
        }
    }
}

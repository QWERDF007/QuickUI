import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import quickui

Item {
    id: control

    property bool dropBtnAreaVisible: true
    property string imagePath: ""
    property string title: qsTr("拖放图像到此")
    property string separatorText: "- OR -"
    property string browseButtonText: qsTr("浏览图像文件")

    signal pathChanged(string path)
    signal imageDropped(string path)

    DropArea {
        id: dropArea
        anchors.fill: parent
        onDropped: function (drop) {
            if (drop.hasUrls && drop.urls.length > 0) {
                var url = drop.urls[0].toString()
                if (url.startsWith("file:///")) {
                    url = url.substring(8)
                }
                control.imagePath = url
                control.pathChanged(url)
                control.imageDropped(url)
            }
        }
    }

    Item {
        id: dropBtnArea
        visible: control.dropBtnAreaVisible
        implicitHeight: childrenRect.height
        implicitWidth: Math.max(dropImage.width, browseBtn.width)
        anchors.centerIn: parent

        Image {
            id: dropImage
            width: 80
            height: 80
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
            }
            source: "/icons/dropimage"
            fillMode: Image.PreserveAspectFit
        }

        QuiText {
            id: dropTip
            anchors {
                top: dropImage.bottom
                topMargin: 8
                horizontalCenter: parent.horizontalCenter
            }
            font: QuiFont.Body
            color: QuiColor.FontPrimary
            text: control.title
        }

        QuiText {
            id: separator
            anchors {
                top: dropTip.bottom
                topMargin: 4
                horizontalCenter: parent.horizontalCenter
            }
            font: QuiFont.Caption
            color: QuiColor.FontCaption
            text: control.separatorText
        }

        QuiButton {
            id: browseBtn
            anchors {
                top: separator.bottom
                topMargin: 8
                horizontalCenter: parent.horizontalCenter
            }
            text: control.browseButtonText
            onClicked: {
                fileDialog.open()
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: qsTr("选择图像")
        nameFilters: ["图像文件 (*.png *.jpg *.jpeg *.bmp *.webp *.tif *.tiff)", "所有文件 (*)"]
        onAccepted: {
            var url = fileDialog.selectedFile.toString()
            if (url.startsWith("file:///")) {
                url = url.substring(8)
            }
            control.imagePath = url
            control.pathChanged(url)
            control.imageDropped(url)
        }
    }
}

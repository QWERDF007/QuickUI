import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import quickui

QuiPopup {
    id: control
    closePolicy: Popup.CloseOnPressOutside
    width: 320
    height: 120
    maskOpacity: 0.2
    property alias description: desc.text
    property alias text: edit.text

    signal editTextChanged(string text)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            QuiText {
                id: desc
            }
            QuiTextField {
                id: edit
                Layout.fillWidth: true
            }
        }
        RowLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: 10
            Item {
                Layout.fillWidth: true
            }
            QuiButton {
                text: "鍙栨秷"
                onClicked: {
                    control.close()
                }
            }
            QuiButton {
                text: "纭"
                onClicked: {
                    control.close()
                    editTextChanged(edit.text)
                }
            }
        }
    }
}

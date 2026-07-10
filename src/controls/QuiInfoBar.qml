import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import quickui

Item {
    id: control
    visible: false
    width: 0
    height: 0

    property var root
    property int layoutY: 75
    property int maxWidth: 460
    property int defaultDuration: 3000

    readonly property string successType: "success"
    readonly property string infoType: "info"
    readonly property string warningType: "warning"
    readonly property string errorType: "error"

    property var _screenLayout: null

    function show(type, title, message, duration) {
        let normalizedType = normalizeType(type)
        let displayTitle = String(title || "")
        let displayMessage = String(message || "")
        let displayDuration = duration === undefined || duration === null ? defaultDuration : Number(duration)

        if (_screenLayout) {
            let last = _screenLayout.getLastItem()
            if (last && last.barType === normalizedType
                    && last.title === displayTitle
                    && last.message === displayMessage) {
                last.duration = displayDuration
                if (displayDuration > 0) {
                    last.restart()
                }
                return last
            }
        }

        ensureScreenLayout()
        return contentComponent.createObject(_screenLayout, {
                                                 "barType": normalizedType,
                                                 "title": displayTitle,
                                                 "message": displayMessage,
                                                 "duration": displayDuration
                                             })
    }

    function showSuccess(title, duration, message) {
        return show(successType, title, message || "", duration)
    }

    function showInfo(title, duration, message) {
        return show(infoType, title, message || "", duration)
    }

    function showWarning(title, duration, message) {
        return show(warningType, title, message || "", duration)
    }

    function showError(title, duration, message) {
        return show(errorType, title, message || "", duration)
    }

    function showCustom(itemComponent, duration) {
        ensureScreenLayout()
        return contentComponent.createObject(_screenLayout, {
                                                 "itemComponent": itemComponent,
                                                 "duration": duration === undefined ? defaultDuration : Number(duration)
                                             })
    }

    function clearAllInfo() {
        if (_screenLayout) {
            let layout = _screenLayout
            _screenLayout = null
            layout.destroy()
        }
        return true
    }

    function normalizeType(type) {
        let value = String(type || infoType).toLowerCase()
        if (value === successType || value === warningType || value === errorType) {
            return value
        }
        return infoType
    }

    function ensureScreenLayout() {
        if (_screenLayout) {
            return
        }

        let parentObject = root || Qt.application
        _screenLayout = screenLayoutComponent.createObject(parentObject)
        _screenLayout.y = layoutY
        _screenLayout.z = 100000
    }

    function backgroundColor(type) {
        switch (type) {
        case successType:
            return Qt.rgba(57 / 255, 61 / 255, 27 / 255, 1)
        case warningType:
            return Qt.rgba(67 / 255, 53 / 255, 25 / 255, 1)
        case errorType:
            return Qt.rgba(68 / 255, 39 / 255, 38 / 255, 1)
        default:
            return Qt.rgba(39 / 255, 39 / 255, 39 / 255, 1)
        }
    }

    function borderColor(type) {
        switch (type) {
        case successType:
            return Qt.rgba(86 / 255, 94 / 255, 39 / 255, 1)
        case warningType:
            return Qt.rgba(92 / 255, 73 / 255, 35 / 255, 1)
        case errorType:
            return Qt.rgba(95 / 255, 48 / 255, 47 / 255, 1)
        default:
            return Qt.rgba(65 / 255, 65 / 255, 65 / 255, 1)
        }
    }

    function iconColor(type) {
        switch (type) {
        case successType:
            return Qt.rgba(108 / 255, 203 / 255, 95 / 255, 1)
        case warningType:
            return Qt.rgba(252 / 255, 225 / 255, 0, 1)
        case errorType:
            return Qt.rgba(255 / 255, 153 / 255, 164 / 255, 1)
        default:
            return QuiColor.Highlight
        }
    }

    function iconSource(type) {
        switch (type) {
        case successType:
            return QuiFontIcon.CompletedSolid
        case warningType:
            return QuiFontIcon.StatusWarning
        case errorType:
            return QuiFontIcon.StatusErrorFull
        default:
            return QuiFontIcon.InfoSolid
        }
    }

    Component {
        id: screenLayoutComponent

        Column {
            parent: Overlay.overlay
            width: control.root ? control.root.width : 0
            spacing: 12

            move: Transition {
                NumberAnimation {
                    properties: "x,y"
                    easing.type: Easing.OutCubic
                    duration: 180
                }
            }

            onChildrenChanged: {
                if (children.length === 0) {
                    control._screenLayout = null
                    destroy()
                }
            }

            function getLastItem() {
                return children.length > 0 ? children[children.length - 1] : null
            }
        }
    }

    Component {
        id: contentComponent

        Item {
            id: content

            property int duration: control.defaultDuration
            property Component itemComponent
            property string barType: control.infoType
            property string title: ""
            property string message: ""

            width: parent ? parent.width : 0
            height: loader.height
            opacity: loader.item ? 1 : 0
            scale: loader.item ? 1 : 0.96

            Behavior on opacity {
                NumberAnimation {
                    easing.type: Easing.OutCubic
                    duration: 160
                }
            }

            Behavior on scale {
                NumberAnimation {
                    easing.type: Easing.OutCubic
                    duration: 160
                }
            }

            Timer {
                id: closeTimer
                interval: Math.max(0, content.duration)
                running: content.duration > 0
                repeat: false
                onTriggered: content.close()
            }

            Component {
                id: infoBarComponent

                Rectangle {
                    id: bar

                    readonly property var owner: content
                    readonly property bool persistent: owner.duration <= 0
                    readonly property int contentWidth: Math.min(textColumn.implicitWidth, control.maxWidth)

                    width: Math.min((control.root ? control.root.width - 40 : row.implicitWidth + 48),
                                    row.implicitWidth + (persistent ? 28 : 46))
                    height: Math.max(44, row.implicitHeight + 20)
                    radius: 4
                    color: control.backgroundColor(owner.barType)
                    border.width: 1
                    border.color: control.borderColor(owner.barType)

                    QuiShadow {
                        color: "#000000"
                        elevation: 6
                        radius: bar.radius
                    }

                    Row {
                        id: row
                        anchors.centerIn: parent
                        spacing: 10

                        QuiTextIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            iconSource: control.iconSource(owner.barType)
                            iconSize: 20
                            iconColor: control.iconColor(owner.barType)
                        }

                        Column {
                            id: textColumn
                            width: Math.min(Math.max(titleText.implicitWidth, detailText.implicitWidth),
                                            control.maxWidth)
                            spacing: 5
                            anchors.verticalCenter: parent.verticalCenter

                            QuiText {
                                id: titleText
                                width: parent.width
                                text: owner.title
                                wrapMode: Text.WordWrap
                                color: QuiColor.FontPrimary
                            }

                            QuiText {
                                id: detailText
                                width: parent.width
                                text: owner.message
                                visible: text.length > 0
                                wrapMode: Text.WordWrap
                                color: QuiColor.FontDark
                            }
                        }

                        QuiTextIconButton {
                            visible: bar.persistent
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24
                            height: 24
                            iconSize: 10
                            iconSource: QuiFontIcon.ChromeClose
                            normalColor: QuiColor.Transparent
                            hoverColor: Qt.rgba(1, 1, 1, 0.08)
                            pressedColor: Qt.rgba(1, 1, 1, 0.14)
                            iconColor: QuiColor.FontDark
                            text: "关闭"
                            onClicked: owner.close()
                        }
                    }
                }
            }

            Loader {
                id: loader
                asynchronous: true
                sourceComponent: content.itemComponent ? content.itemComponent : infoBarComponent
                x: Math.max(0, (parent.width - width) / 2)
            }

            function close() {
                destroy()
            }

            function restart() {
                closeTimer.restart()
            }
        }
    }
}

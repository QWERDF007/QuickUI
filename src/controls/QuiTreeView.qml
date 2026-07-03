import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import quickui

Rectangle {
    id: control

    property alias model: tree_view.model
    property alias view: tree_view
    property alias rows: tree_view.rows
    property alias contentY: tree_view.contentY
    property string displayRole: "display"
    property string colorRole: ""
    property int iconSource: -1
    property bool showLine: true
    property bool checkable: false
    property int cellHeight: 30
    property int depthPadding: 15
    property int checkedRevision: 0
    property color lineColor: QuiColor.Border
    property color selectedBorderColor: QuiColor.Highlight
    property color selectedColor: Utils.withOpacity(QuiColor.Highlight, 0.18)
    property color hoveredColor: Utils.withOpacity(QuiColor.FontPrimary, 0.06)
    property color alternateColor: Utils.withOpacity(QuiColor.FontPrimary, 0.025)
    property var checkedResolver: function(row, rowData) {
        return false
    }
    property var partiallyCheckedResolver: function(row, rowData) {
        return false
    }
    readonly property alias current: d.current
    readonly property alias currentRow: d.currentRow

    signal itemClicked(int row, var rowData)
    signal itemDoubleClicked(int row, var rowData)
    signal itemCheckToggled(int row, var rowData, bool checked)

    color: QuiColor.Primary
    radius: 4
    border.color: QuiColor.Border
    clip: true

    QtObject {
        id: d
        property bool destroying: false
        property var current: null
        property int currentRow: -1
    }

    function forceLayout() {
        if (!d.destroying) {
            tree_view.forceLayout()
        }
    }

    function resetPosition() {
        tree_view.contentX = 0
        tree_view.contentY = 0
    }

    function count() {
        return tree_view.rows
    }

    function collapse(row) {
        tree_view.collapse(row)
    }

    function expand(row) {
        tree_view.expand(row)
    }

    function toggleExpanded(row) {
        tree_view.toggleExpanded(row)
    }

    function allExpand() {
        tree_view.expandRecursively(-1, -1)
    }

    function allCollapse() {
        tree_view.collapseRecursively(-1)
    }

    function modelValue(rowData, role, fallbackValue) {
        if (rowData === undefined || rowData === null) {
            return fallbackValue
        }
        if (role && rowData[role] !== undefined && rowData[role] !== null) {
            return rowData[role]
        }
        if (rowData.display !== undefined && rowData.display !== null) {
            return rowData.display
        }
        if (rowData.modelData !== undefined && rowData.modelData !== null) {
            return rowData.modelData
        }
        return fallbackValue
    }

    function displayText(rowData) {
        let value = modelValue(rowData, displayRole, "")
        return value === undefined || value === null ? "" : String(value)
    }

    function displayColor(rowData) {
        if (!colorRole || colorRole.length === 0) {
            return ""
        }
        let value = modelValue(rowData, colorRole, "")
        return value === undefined || value === null ? "" : String(value)
    }

    function isRowChecked(row, rowData) {
        checkedRevision
        if (!checkedResolver || typeof checkedResolver !== "function") {
            return false
        }
        return checkedResolver(row, rowData) === true
    }

    function isRowPartiallyChecked(row, rowData) {
        checkedRevision
        if (!partiallyCheckedResolver || typeof partiallyCheckedResolver !== "function") {
            return false
        }
        return partiallyCheckedResolver(row, rowData) === true
    }

    function rowCheckState(row, rowData) {
        if (isRowPartiallyChecked(row, rowData)) {
            return Qt.PartiallyChecked
        }
        return isRowChecked(row, rowData) ? Qt.Checked : Qt.Unchecked
    }

    Component.onDestruction: {
        d.destroying = true
        tree_view.model = null
        tree_view.delegate = null
    }

    TreeView {
        id: tree_view

        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        columnWidthProvider: function(column) {
            return Math.max(1, tree_view.width)
        }
        rowHeightProvider: function(row) {
            return control.cellHeight
        }

        ScrollBar.horizontal: QuiScrollBar {}
        ScrollBar.vertical: QuiScrollBar {}

        onWidthChanged: Qt.callLater(control.forceLayout)
        onHeightChanged: Qt.callLater(control.forceLayout)
        onRowsChanged: Qt.callLater(control.forceLayout)

        delegate: Item {
            id: tree_item

            required property int row
            required property int column
            required property var model
            required property bool isTreeNode
            required property bool expanded
            required property bool hasChildren
            required property int depth

            implicitWidth: tree_view.width
            implicitHeight: control.cellHeight
            readonly property int leftMargin: 6
            readonly property int rightMargin: 6
            readonly property int spacing: 4
            readonly property int indicatorWidth: 20
            readonly property real contentIndent: depth * control.depthPadding

            MouseArea {
                id: row_mouse

                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                onClicked: {
                    d.current = tree_item.model
                    d.currentRow = tree_item.row
                    control.itemClicked(tree_item.row, tree_item.model)
                }
                onDoubleClicked: {
                    if (tree_item.hasChildren) {
                        tree_view.toggleExpanded(tree_item.row)
                    }
                    control.itemDoubleClicked(tree_item.row, tree_item.model)
                }
            }

            Rectangle {
                anchors.fill: parent
                color: {
                    if (d.currentRow === tree_item.row) {
                        return control.selectedColor
                    }
                    if (row_mouse.containsMouse || row_mouse.pressed) {
                        return control.hoveredColor
                    }
                    return tree_item.row % 2 === 0 ? "transparent" : control.alternateColor
                }

                Rectangle {
                    width: 2
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    color: control.selectedBorderColor
                    visible: d.currentRow === tree_item.row
                }
            }

            Item {
                id: indicator

                readonly property real indicatorIndent: tree_item.leftMargin + tree_item.contentIndent

                x: indicatorIndent
                y: (tree_item.height - height) / 2
                width: tree_item.indicatorWidth
                height: control.cellHeight
                visible: tree_item.isTreeNode

                QuiTextIcon {
                    anchors.centerIn: parent
                    iconSource: QuiFontIcon.ChevronRight
                    iconSize: 14
                    iconColor: tree_item.hasChildren ? QuiColor.FontPrimary : "transparent"
                    rotation: tree_item.expanded ? 90 : 0
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: tree_item.hasChildren
                    acceptedButtons: Qt.LeftButton
                    onClicked: function(mouse) {
                        tree_view.toggleExpanded(tree_item.row)
                        mouse.accepted = true
                    }
                }
            }

            RowLayout {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: tree_item.leftMargin + tree_item.contentIndent
                                    + (tree_item.isTreeNode ? tree_item.indicatorWidth + tree_item.spacing : 0)
                anchors.rightMargin: tree_item.rightMargin
                spacing: 6
                z: 1

                QuiCheckBox {
                    id: check_box

                    Layout.preferredWidth: 18
                    Layout.preferredHeight: 18
                    Layout.alignment: Qt.AlignVCenter
                    visible: control.checkable
                    size: 18
                    padding: 0
                    horizontalPadding: 0
                    verticalPadding: 0
                    animationEnabled: false
                    checkState: control.rowCheckState(tree_item.row, tree_item.model)
                    onClicked: control.itemCheckToggled(tree_item.row, tree_item.model, checkState === Qt.Checked)
                }

                QuiTextIcon {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    Layout.alignment: Qt.AlignVCenter
                    visible: control.iconSource >= 0
                    iconSource: control.iconSource
                    iconSize: 15
                    iconColor: QuiColor.FontDark
                }

                Rectangle {
                    Layout.preferredWidth: 12
                    Layout.preferredHeight: 12
                    Layout.alignment: Qt.AlignVCenter
                    visible: control.displayColor(tree_item.model).length > 0
                    radius: 2
                    color: control.displayColor(tree_item.model)
                    border.color: QuiColor.Border
                }

                QuiText {
                    id: item_text

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: control.displayText(tree_item.model)
                    color: QuiColor.FontPrimary
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight

                    MouseArea {
                        id: hover_handler
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        hoverEnabled: true
                    }

                    QuiToolTip {
                        text: item_text.text
                        delay: 500
                        visible: item_text.truncated && hover_handler.containsMouse
                    }
                }
            }

            Item {
                anchors.fill: parent
                visible: control.showLine && tree_item.depth > 0
                z: -1

                Rectangle {
                    width: 1
                    height: parent.height
                    x: tree_item.leftMargin + Math.max(0, tree_item.depth - 1) * control.depthPadding + 10
                    color: control.lineColor
                }

                Rectangle {
                    height: 1
                    width: Math.max(0, control.depthPadding - 6)
                    x: tree_item.leftMargin + Math.max(0, tree_item.depth - 1) * control.depthPadding + 10
                    anchors.verticalCenter: parent.verticalCenter
                    color: control.lineColor
                }
            }
        }
    }
}

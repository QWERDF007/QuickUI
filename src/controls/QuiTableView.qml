import QtQuick
import QtQuick.Controls

import quickui

Rectangle {
    id: control

    property alias model: table_view.model
    property alias delegate: table_view.delegate
    property alias view: table_view
    property alias bodyItem: body_overlay
    property alias bodyOverlay: body_overlay
    property alias horizontalHeader: header_horizontal
    property alias verticalHeader: header_vertical
    property alias rows: table_view.rows
    property alias columns: table_view.columns
    property alias contentX: table_view.contentX
    property alias contentY: table_view.contentY
    property alias contentWidth: table_view.contentWidth
    property alias contentHeight: table_view.contentHeight
    property alias interactive: table_view.interactive
    property alias boundsBehavior: table_view.boundsBehavior
    property alias columnSpacing: table_view.columnSpacing
    property alias rowSpacing: table_view.rowSpacing
    property alias headerModel: header_horizontal.model
    property alias headerTextRole: header_horizontal.textRole

    property var columnSource: []
    property var columnWidthProvider: undefined
    property var rowHeightProvider: undefined
    property Component headerDelegate: default_header_delegate
    property Component verticalHeaderDelegate: default_vertical_header_delegate
    property bool horizontalHeaderVisible: true
    property bool horizonalHeaderVisible: true
    property bool verticalHeaderVisible: false
    property bool resizableColumns: true
    property bool fitColumnsToWidth: false
    property int startRowIndex: 1
    property real defaultColumnWidth: 100
    property real minimumColumnWidth: 40
    property real maximumColumnWidth: 65535
    property real rowHeight: 32
    property real headerHeight: 32
    property color headerColor: QuiColor.Background
    property color headerTextColor: QuiColor.FontPrimary
    property color borderColor: QuiColor.Border
    property bool showGridLines: false

    readonly property real frozenWidth: frozenColumnsWidth()

    signal layoutRequested()

    color: QuiColor.Primary
    border.color: borderColor
    border.width: showGridLines ? 1 : 0
    clip: true

    QtObject {
        id: d
        property var columnWidths: ({})
        property int columnWidthRevision: 0
        property bool destroying: false
    }

    function forceLayout() {
        if (d.destroying) {
            return
        }
        table_view.forceLayout()
        header_horizontal.forceLayout()
        header_vertical.forceLayout()
        layoutRequested()
    }

    function resetPosition() {
        table_view.contentX = 0
        table_view.contentY = 0
    }

    function columnOptions(column) {
        if (columnSource && column >= 0 && column < columnSource.length && columnSource[column]) {
            return columnSource[column]
        }
        return {}
    }

    function columnWidth(column) {
        d.columnWidthRevision
        if (d.destroying) {
            return defaultColumnWidth
        }

        if (fitColumnsToWidth) {
            return fittedColumnWidth(column)
        }

        return baseColumnWidth(column)
    }

    function baseColumnWidth(column) {
        if (d.destroying) {
            return defaultColumnWidth
        }
        if (d.columnWidths[column] !== undefined) {
            return clampColumnWidth(column, d.columnWidths[column])
        }

        let options = columnOptions(column)
        if (options.width > 0) {
            return clampColumnWidth(column, options.width)
        }

        if (columnWidthProvider) {
            let width = columnWidthProvider(column)
            if (width > 0) {
                return clampColumnWidth(column, width)
            }
        }
        return clampColumnWidth(column, defaultColumnWidth)
    }

    function clampColumnWidth(column, width) {
        return Math.min(Math.max(width, columnMinimumWidth(column)), columnMaximumWidth(column))
    }

    function columnStretchEnabled(column) {
        return columnOptions(column).stretch !== false
    }

    function columnStretchFactor(column) {
        let factor = columnOptions(column).stretchFactor
        return factor > 0 ? factor : 1
    }

    function availableColumnsWidth() {
        let count = table_view.columns
        if (count <= 0) {
            return 0
        }
        let spacing = Math.max(0, count - 1) * table_view.columnSpacing
        return Math.max(0, table_view.width - spacing)
    }

    function fittedColumnWidth(column) {
        let count = table_view.columns
        if (column < 0 || column >= count) {
            return defaultColumnWidth
        }
        if (count <= 0) {
            return defaultColumnWidth
        }

        let available = availableColumnsWidth()
        if (available <= 0) {
            return 1
        }

        let widths = []
        let minimums = []
        let totalWidth = 0
        let totalMinimum = 0
        let stretchFactorTotal = 0
        let shrinkCapacityTotal = 0

        for (let i = 0; i < count; ++i) {
            let width = baseColumnWidth(i)
            let minimum = columnMinimumWidth(i)
            widths.push(width)
            minimums.push(minimum)
            totalWidth += width
            totalMinimum += minimum
            if (columnStretchEnabled(i)) {
                stretchFactorTotal += columnStretchFactor(i)
            }
            shrinkCapacityTotal += Math.max(0, width - minimum)
        }

        if (Math.abs(totalWidth - available) < 0.5) {
            return widths[column]
        }

        if (totalMinimum > available) {
            let scaledMinimum = minimums[column] * available / totalMinimum
            return Math.max(1, scaledMinimum)
        }

        if (totalWidth < available) {
            if (!columnStretchEnabled(column) || stretchFactorTotal <= 0) {
                return widths[column]
            }
            let extra = available - totalWidth
            return widths[column] + extra * columnStretchFactor(column) / stretchFactorTotal
        }

        if (shrinkCapacityTotal <= 0) {
            return widths[column]
        }

        let deficit = totalWidth - available
        let capacity = Math.max(0, widths[column] - minimums[column])
        return widths[column] - Math.min(capacity, deficit * capacity / shrinkCapacityTotal)
    }

    function currentRowHeight(row) {
        if (d.destroying) {
            return rowHeight
        }
        if (rowHeightProvider) {
            let height = rowHeightProvider(row)
            if (height > 0) {
                return height
            }
        }
        return rowHeight
    }

    function columnMinimumWidth(column) {
        let options = columnOptions(column)
        return options.minimumWidth > 0 ? options.minimumWidth : minimumColumnWidth
    }

    function columnMaximumWidth(column) {
        let options = columnOptions(column)
        return options.maximumWidth > 0 ? options.maximumWidth : maximumColumnWidth
    }

    function isColumnResizable(column) {
        let options = columnOptions(column)
        return resizableColumns && options.resizable !== false
    }

    function setColumnWidth(column, width) {
        let minimumWidth = columnMinimumWidth(column)
        let maximumWidth = fitColumnsToWidth ? columnResizeMaximumWidth(column) : columnMaximumWidth(column)
        let adjustedWidth = Math.min(Math.max(width, minimumWidth), maximumWidth)
        let widths = Object.assign({}, d.columnWidths)
        widths[column] = adjustedWidth
        d.columnWidths = widths
        d.columnWidthRevision += 1
        Qt.callLater(forceLayout)
    }

    function columnResizeMaximumWidth(column) {
        let maximumWidth = columnMaximumWidth(column)
        let count = table_view.columns
        if (count <= 0) {
            return maximumWidth
        }

        let available = availableColumnsWidth()
        for (let i = 0; i < count; ++i) {
            if (i === column) {
                continue
            }
            available -= columnMinimumWidth(i)
        }

        return Math.max(columnMinimumWidth(column), Math.min(maximumWidth, available))
    }

    function isFrozenColumn(column) {
        return columnOptions(column).frozen === true
    }

    function frozenColumnIndexes() {
        d.columnWidthRevision
        if (d.destroying) {
            return []
        }
        let count = table_view.columns
        let result = []
        for (let column = 0; column < count; ++column) {
            if (isFrozenColumn(column)) {
                result.push(column)
            }
        }
        return result
    }

    function frozenColumnsWidth() {
        if (d.destroying) {
            return 0
        }
        let width = 0
        let columns = frozenColumnIndexes()
        for (let i = 0; i < columns.length; ++i) {
            width += columnWidth(columns[i])
        }
        return width
    }

    function frozenColumnX(column) {
        let x = 0
        let columns = frozenColumnIndexes()
        for (let i = 0; i < columns.length; ++i) {
            if (columns[i] === column) {
                return x
            }
            x += columnWidth(columns[i])
        }
        return x
    }

    function columnOffset(column) {
        if (d.destroying) {
            return 0
        }
        let x = 0
        for (let i = 0; i < column; ++i) {
            x += columnWidth(i) + table_view.columnSpacing
        }
        return x
    }

    function columnVisualX(column) {
        if (d.destroying) {
            return 0
        }
        if (isFrozenColumn(column)) {
            return frozenColumnX(column)
        }
        return columnOffset(column) - table_view.contentX
    }

    Component.onDestruction: {
        d.destroying = true
        header_horizontal.syncView = null
        header_vertical.syncView = null
        table_view.model = null
    }

    function headerDisplayText(value, modelObject) {
        if (headerTextRole && value && typeof value === "object" && value[headerTextRole] !== undefined) {
            return String(value[headerTextRole])
        }
        if (headerTextRole && modelObject && typeof modelObject === "object" && modelObject[headerTextRole] !== undefined) {
            return String(modelObject[headerTextRole])
        }
        if (value === undefined || value === null) {
            return ""
        }
        return String(value)
    }

    Component {
        id: default_header_delegate

        Rectangle {
            property int sourceColumn: typeof column === "undefined" ? index : column

            implicitWidth: control.columnWidth(sourceColumn)
            implicitHeight: control.headerHeight
            color: control.headerColor
            border.color: control.borderColor
            border.width: control.showGridLines ? 1 : 0

            QuiText {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                text: {
                    let value = undefined
                    if (typeof modelData !== "undefined") {
                        value = modelData
                    } else if (typeof display !== "undefined") {
                        value = display
                    }
                    return control.headerDisplayText(value, model)
                }
                color: control.headerTextColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }
    }

    Component {
        id: default_vertical_header_delegate

        Rectangle {
            property int sourceRow: typeof row === "undefined" ? index : row

            implicitWidth: Math.max(30, row_text.implicitWidth + 16)
            implicitHeight: control.currentRowHeight(sourceRow)
            color: control.headerColor
            border.color: control.borderColor
            border.width: control.showGridLines ? 1 : 0

            QuiText {
                id: row_text
                anchors.centerIn: parent
                text: sourceRow + control.startRowIndex
                color: control.headerTextColor
            }
        }
    }

    Rectangle {
        id: header_corner
        visible: header_horizontal.visible && header_vertical.visible
        x: 0
        y: 0
        width: header_vertical.width
        height: header_horizontal.height
        color: control.headerColor
        border.color: control.borderColor
        border.width: control.showGridLines ? 1 : 0
    }

    HorizontalHeaderView {
        id: header_horizontal
        visible: control.horizontalHeaderVisible && control.horizonalHeaderVisible
        height: visible ? control.headerHeight : 0
        anchors.left: parent.left
        anchors.leftMargin: header_vertical.visible ? header_vertical.width : 0
        anchors.right: parent.right
        anchors.top: parent.top
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        columnSpacing: table_view.columnSpacing
        syncView: d.destroying ? null : table_view
        delegate: control.headerDelegate

        onContentXChanged: {
            if (!d.destroying) {
                Qt.callLater(control.forceLayout)
            }
        }
    }

    VerticalHeaderView {
        id: header_vertical
        visible: control.verticalHeaderVisible
        width: visible ? Math.max(1, contentWidth) : 0
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: header_horizontal.visible ? header_horizontal.height : 0
        anchors.bottom: parent.bottom
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        rowSpacing: table_view.rowSpacing
        syncView: d.destroying ? null : table_view
        delegate: control.verticalHeaderDelegate

        onContentYChanged: {
            if (!d.destroying) {
                Qt.callLater(control.forceLayout)
            }
        }
    }

    TableView {
        id: table_view
        anchors.left: parent.left
        anchors.leftMargin: header_vertical.visible ? header_vertical.width : 0
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: header_horizontal.visible ? header_horizontal.height : 0
        anchors.bottom: parent.bottom
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        columnWidthProvider: function(column) {
            return control.columnWidth(column)
        }
        rowHeightProvider: function(row) {
            return control.currentRowHeight(row)
        }

        ScrollBar.horizontal: QuiScrollBar {}
        ScrollBar.vertical: QuiScrollBar {}

        onWidthChanged: {
            if (!d.destroying) {
                Qt.callLater(control.forceLayout)
            }
        }
        onHeightChanged: {
            if (!d.destroying) {
                Qt.callLater(control.forceLayout)
            }
        }
        onRowsChanged: {
            if (!d.destroying) {
                Qt.callLater(control.forceLayout)
            }
        }
        onColumnsChanged: {
            if (!d.destroying) {
                Qt.callLater(control.forceLayout)
            }
        }
    }

    Item {
        id: frozen_layer
        anchors.left: table_view.left
        anchors.top: header_horizontal.visible ? header_horizontal.top : table_view.top
        anchors.bottom: table_view.bottom
        width: control.frozenWidth
        visible: width > 0
        clip: true
        z: 10

        Repeater {
            model: d.destroying ? [] : control.frozenColumnIndexes()

            Item {
                id: frozen_column_item
                property int sourceColumn: modelData

                x: control.frozenColumnX(sourceColumn)
                width: control.columnWidth(sourceColumn)
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                clip: true

                HorizontalHeaderView {
                    id: frozen_header
                    visible: header_horizontal.visible
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: header_horizontal.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: false
                    columnSpacing: table_view.columnSpacing
                    syncView: d.destroying ? null : frozen_table
                    delegate: control.headerDelegate
                }

                TableView {
                    id: frozen_table
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: header_horizontal.visible ? header_horizontal.height : 0
                    anchors.bottom: parent.bottom
                    clip: true
                    interactive: false
                    boundsBehavior: Flickable.StopAtBounds
                    syncView: d.destroying ? null : table_view
                    syncDirection: Qt.Vertical
                    model: d.destroying ? null : table_view.model
                    delegate: d.destroying ? null : table_view.delegate
                    columnSpacing: table_view.columnSpacing
                    rowSpacing: table_view.rowSpacing
                    contentX: control.columnOffset(sourceColumn)
                    columnWidthProvider: d.destroying ? undefined : table_view.columnWidthProvider
                    rowHeightProvider: d.destroying ? undefined : table_view.rowHeightProvider
                }

                Rectangle {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    width: 1
                    color: control.borderColor
                }

                Connections {
                    target: control
                    function onLayoutRequested() {
                        if (!d.destroying) {
                            frozen_table.forceLayout()
                            frozen_header.forceLayout()
                        }
                    }
                }
            }
        }
    }

    Item {
        id: body_overlay
        anchors.left: table_view.left
        anchors.right: table_view.right
        anchors.top: table_view.top
        anchors.bottom: table_view.bottom
        z: 20
    }

    Item {
        id: resize_layer
        anchors.left: table_view.left
        anchors.right: table_view.right
        anchors.top: header_horizontal.top
        height: header_horizontal.height
        visible: header_horizontal.visible && control.resizableColumns
        z: 30

        Repeater {
            model: d.destroying ? 0 : table_view.columns

            MouseArea {
                id: resize_handle
                property int sourceColumn: index
                property real pressX: 0
                property real pressWidth: 0

                x: control.columnVisualX(sourceColumn) + control.columnWidth(sourceColumn) - width / 2
                y: 0
                width: 8
                height: parent.height
                visible: {
                    if (!control.isColumnResizable(sourceColumn)) {
                        return false
                    }
                    if (!control.isFrozenColumn(sourceColumn) && x < control.frozenWidth - width / 2) {
                        return false
                    }
                    return x >= -width / 2 && x <= parent.width - width / 2
                }
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.SplitHCursor
                preventStealing: true

                onPressed: function(mouse) {
                    pressX = mapToItem(control, mouse.x, mouse.y).x
                    pressWidth = control.columnWidth(sourceColumn)
                    mouse.accepted = true
                }

                onPositionChanged: function(mouse) {
                    if (!pressed) {
                        return
                    }
                    let currentX = mapToItem(control, mouse.x, mouse.y).x
                    control.setColumnWidth(sourceColumn, pressWidth + currentX - pressX)
                    mouse.accepted = true
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import Qt.labs.qmlmodels

import quickui

Rectangle {
    id: control

    /* ==================== 视图 API ==================== */
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
    /* 覆盖层使用稳定的视口几何，调用方无需访问内部 TableView/Header。 */
    readonly property real viewportX: table_view.x
    readonly property real viewportY: table_view.y
    readonly property real viewportWidth: table_view.width
    readonly property real viewportHeight: table_view.height
    readonly property real verticalHeaderWidth: header_vertical.width
    readonly property real frameX: x
    readonly property real frameY: y
    readonly property real frameWidth: width
    readonly property real frameHeight: height
    /* ==================== 几何与样式 ==================== */
    property var columnSource: []
    property var columnWidthProvider: undefined
    property var rowHeightProvider: undefined
    property Component verticalHeaderDelegate: default_vertical_header_delegate
    property bool horizontalHeaderVisible: true
    property bool horizonalHeaderVisible: true
    property bool verticalHeaderVisible: false
    property bool resizableColumns: true
    property bool resizableRows: true
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
    property bool zebraEnabled: true
    property color zebraColor: Qt.lighter(QuiColor.Primary, 1.3)
    property color hoverColor: Qt.rgba(1, 1, 1, 0.06)
    property color selectedColor: Qt.rgba(0, 150, 136, 0.35)
    property color selectedBorderColor: QuiColor.Highlight
    property bool hoverEnabled: true
    property bool rowSelectionEnabled: true
    /* ==================== 数据 API ==================== */
    property var dataSource: undefined
    /**
     * @brief 可选的直接模型。
     *
     * 设置后跳过 QVariantMap 行缓存，TableView 直接消费 QAbstractItemModel。
     */
    property var externalModel: null
    property Component externalCellDelegate: null
    property var externalCellOptionsProvider: null
    property var externalCellClickHandler: null
    readonly property alias sourceModel: table_source_model
    readonly property var current: d.current

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
        property var rowHeights: ({})
        property bool destroying: false
        property var current
        property int rowHoverIndex: -1
        property var editDelegate
        property var editPosition

        function uuid() {
            return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
                let r = Math.random() * 16 | 0
                let v = c === 'x' ? r : (r & 0x3 | 0x8)
                return v.toString(16)
            })
        }

        function ensureKey(row) {
            if (row && typeof row === "object" && !row._key) {
                row._key = d.uuid()
            }
            return row
        }

        function getEditDelegate(column) {
            let options = control.columnOptions(column)
            if (options.editDelegate) {
                return options.editDelegate
            }
            if (options.editMultiline === true) {
                return com_edit_multiline
            }
            return com_edit
        }
    }

    /* ==================== 内部模型 ==================== */
    QuiTableModel {
        id: table_source_model
    }

    QuiTableModel {
        id: header_column_model
        /* 表头视图始终持有同一个模型对象，列变化只触发模型数据重置。 */
        columnSource: control.columnSource
        rows: control.columnSource.length > 0 ? [{}] : []
    }

    QuiTableSortProxyModel {
        id: table_sort_model
        /* TableView 始终绑定该代理，数据源变化只在代理内部完成。 */
        model: control.externalModel ? control.externalModel : table_source_model
    }

    TableModel {
        id: header_row_model
        columns: [TableModelColumn { display: "rowIndex" }]
    }

    /* ==================== 数据连接 ==================== */
    onDataSourceChanged: {
        if (d.destroying) {
            return
        }
        let rows = dataSource === undefined || dataSource === null ? [] : dataSource
        for (let i = 0; i < rows.length; ++i) {
            d.ensureKey(rows[i])
        }
        table_source_model.rows = rows
        syncModel()
    }
    onColumnSourceChanged: {
        if (d.destroying) {
            return
        }
        table_source_model.columnSource = control.columnSource
        Qt.callLater(control.forceLayout)
    }
    onExternalModelChanged: {
        if (d.destroying)
            return
        Qt.callLater(control.forceLayout)
    }
    onStartRowIndexChanged: updateRowIndex()

    function syncModel() {
        if (d.destroying) {
            return
        }
        updateRowIndex()
        Qt.callLater(control.forceLayout)
    }

    function updateRowIndex() {
        let rows = []
        for (let i = 0; i < table_view.rows; ++i) {
            rows.push({ rowIndex: i + control.startRowIndex })
        }
        header_row_model.rows = rows
    }

    /* ==================== 布局 ==================== */
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
            return baseColumnWidth(column)
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
            if (columnStretchEnabled(i)) {
                totalMinimum += minimum
                stretchFactorTotal += columnStretchFactor(i)
                shrinkCapacityTotal += Math.max(0, width - minimum)
            } else {
                totalMinimum += width
            }
        }

        if (Math.abs(totalWidth - available) < 0.5) {
            return widths[column]
        }

        if (totalMinimum > available) {
            /*
             * 视口小于所有最小宽度时仍保留显式调整过的列宽，
             * 让表格滚动而不是把用户设置恢复为最小值。
             */
            return d.columnWidths[column] !== undefined
                   ? widths[column] : (columnStretchEnabled(column) ? minimums[column] : widths[column])
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
        let capacity = columnStretchEnabled(column)
                       ? Math.max(0, widths[column] - minimums[column]) : 0
        return widths[column] - Math.min(capacity, deficit * capacity / shrinkCapacityTotal)
    }

    function currentRowHeight(row) {
        if (d.destroying) {
            return rowHeight
        }
        if (d.rowHeights[row] > 0) {
            return d.rowHeights[row]
        }
        if (rowHeightProvider) {
            let height = rowHeightProvider(row)
            if (height > 0) {
                return height
            }
        }
        return rowHeight
    }

    function setRowHeight(row, height) {
        let adjustedHeight = Math.max(16, height)
        d.rowHeights[row] = adjustedHeight
        Qt.callLater(control.forceLayout)
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
        let maximumWidth = fitColumnsToWidth && columnStretchEnabled(column)
                           ? columnResizeMaximumWidth(column) : columnMaximumWidth(column)
        let adjustedWidth = Math.min(Math.max(width, minimumWidth), maximumWidth)
        let widths = Object.assign({}, d.columnWidths)
        widths[column] = adjustedWidth
        d.columnWidths = widths
        d.columnWidthRevision += 1
        Qt.callLater(control.forceLayout)
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

        /* 其他列已经占满视口时，允许当前列扩展到可滚动区域。 */
        if (available < columnMinimumWidth(column)) {
            return maximumWidth
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
        /* 冻结列属于列结构，不能跟随数据模型的瞬时列数增减。 */
        let count = control.columnSource ? control.columnSource.length : 0
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

    function frozenColumnVisualX(column) {
        if (d.destroying) {
            return 0
        }
        let width = columnWidth(column)
        let minimumX = 0
        let maximumX = table_view.width - width
        for (let i = 0; i < column; ++i) {
            if (isFrozenColumn(i)) {
                minimumX += columnWidth(i)
            }
        }
        let columnCount = control.columnSource ? control.columnSource.length : 0
        for (let i = column + 1; i < columnCount; ++i) {
            if (isFrozenColumn(i)) {
                maximumX -= columnWidth(i)
            }
        }
        maximumX = Math.max(minimumX, maximumX)
        let naturalX = columnOffset(column) - table_view.contentX
        return Math.min(Math.max(naturalX, minimumX), maximumX)
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
            return frozenColumnVisualX(column)
        }
        return columnOffset(column) - table_view.contentX
    }

    Component.onDestruction: {
        d.destroying = true
        header_horizontal.syncView = null
        header_vertical.syncView = null
        table_view.model = null
    }

    /* ==================== 数据操作 ==================== */
    function closeEditor() {
        d.editPosition = undefined
        d.editDelegate = undefined
    }

    function customItem(comId, options = {}) {
        let o = {}
        o.comId = comId
        o.options = options
        return o
    }

    function sort(callback) {
        if (callback) {
            table_sort_model.setComparator(callback)
        } else {
            table_sort_model.setComparator(undefined)
        }
    }

    function filter(callback) {
        if (callback) {
            table_sort_model.setFilter(callback)
        } else {
            table_sort_model.setFilter(undefined)
        }
    }

    function setFieldFilter(field, keyword) {
        table_sort_model.setFieldFilter(field, keyword === undefined || keyword === null ? "" : String(keyword))
    }

    function setFieldFilters(filters) {
        table_sort_model.fieldFilters = filters || ({})
    }

    function clearFieldFilter(field) {
        table_sort_model.clearFieldFilter(field)
    }

    function clearFieldFilters() {
        table_sort_model.clearFieldFilters()
    }

    function setRow(rowIndex, obj) {
        let old = getRow(rowIndex)
        let map = obj
        if (obj && typeof obj === "object") {
            map = Object.assign({}, obj)
            if (map._key === undefined && old) {
                map._key = old._key
            }
            d.ensureKey(map)
        }
        table_sort_model.setRow(rowIndex, map)
    }

    function getRow(rowIndex) {
        return table_sort_model.getRow(rowIndex)
    }

    function rowData(rowIndex) {
        return getRow(rowIndex)
    }

    function removeRow(rowIndex, rows = 1) {
        table_sort_model.removeRow(rowIndex, rows)
    }

    function insertRow(rowIndex, obj) {
        let map = obj
        if (obj && typeof obj === "object") {
            map = Object.assign({}, obj)
            d.ensureKey(map)
        }
        table_sort_model.insertRow(rowIndex, map)
    }

    function appendRow(obj) {
        insertRow(table_source_model.rowCount, obj)
    }

    /**
     * @brief 生成直接模型单元格的委托数据。
     * @param rowIndex 行下标。
     * @param columnIndex 列下标。
     * @param modelData 当前单元格的模型角色对象。
     * @return 委托组件和其参数。
     */
    function externalCellDisplay(rowIndex, columnIndex, modelData) {
        if (!externalCellDelegate)
            return ({})
        let options = {}
        if (externalCellOptionsProvider && typeof externalCellOptionsProvider === "function")
            options = externalCellOptionsProvider(rowIndex, columnIndex, modelData) || ({})
        return { comId: externalCellDelegate, options: options }
    }

    function applyLoaderOptions(loader) {
        if (!loader || !loader.item || loader.item.options === undefined)
            return
        loader.item.options = loader.options || ({})
    }

    function currentIndex() {
        let index = -1
        if (!d.current) {
            return index
        }
        for (let i = 0; i < table_source_model.rowCount; ++i) {
            let sourceItem = table_source_model.getRow(i)
            if (sourceItem && sourceItem._key === d.current._key) {
                index = i
                break
            }
        }
        return index
    }

    function setCurrent(rowIndex) {
        let map = getRow(rowIndex)
        if (map) {
            d.current = map
        }
    }

    /* ==================== 默认表头委托 ==================== */
    Component {
        id: com_header_text

        QuiText {
            text: display === undefined || display === null ? "" : String(display)
            color: control.headerTextColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    Component {
        id: default_header_delegate

        Rectangle {
            property int sourceColumn: typeof column === "undefined" ? index : column
            property var _model: model
            property var currentTableView: TableView.view

            readonly property bool isMainHeader: currentTableView === header_horizontal
            readonly property bool isHidden: !isMainHeader && currentTableView
                                             && currentTableView.dataIndex !== undefined
                                             && columnMap
                                             && currentTableView.dataIndex !== columnMap.dataIndex

            implicitWidth: isHidden ? Number.MIN_VALUE : control.columnWidth(sourceColumn)
            implicitHeight: control.headerHeight
            visible: !isHidden
            color: control.headerColor
            border.color: control.borderColor
            border.width: control.showGridLines ? 1 : 0

            property var columnMap: (_model && _model.columnModel
                                     && typeof _model.columnModel.title !== "undefined")
                                    ? _model.columnModel : null
            property var titleValue: columnMap ? columnMap.title : undefined

            QuiLoader {
                id: header_loader
                anchors.fill: parent
                property var display: titleValue
                property var options: (typeof display === "object" && display && display.options)
                                      ? display.options : ({})
                onLoaded: control.applyLoaderOptions(header_loader)
                onOptionsChanged: control.applyLoaderOptions(header_loader)
                sourceComponent: (typeof display === "object" && display && display.comId)
                                 ? display.comId : com_header_text
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
                text: {
                    if (typeof model !== "undefined" && model && typeof model.display !== "undefined") {
                        return String(model.display)
                    }
                    return String(sourceRow + control.startRowIndex)
                }
                color: control.headerTextColor
            }

            MouseArea {
                property point clickPos: "0,0"
                width: parent.width
                height: 6
                anchors.bottom: parent.bottom
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.SplitVCursor
                preventStealing: true
                visible: control.resizableRows && control.verticalHeaderVisible
                onPressed: function(mouse) {
                    clickPos = Qt.point(mouse.x, mouse.y)
                    mouse.accepted = true
                }
                onPositionChanged: function(mouse) {
                    if (!pressed) {
                        return
                    }
                    control.setRowHeight(sourceRow, control.currentRowHeight(sourceRow) + mouse.y - clickPos.y)
                    mouse.accepted = true
                }
            }
        }
    }

    /* ==================== 数据表体委托 ==================== */
    Component {
        id: com_text

        QuiText {
            id: item_text
            text: display === undefined || display === null ? "" : String(display)
            elide: Text.ElideRight
            wrapMode: Text.WrapAnywhere
            anchors.fill: parent
            anchors.leftMargin: 11
            anchors.rightMargin: 11
            anchors.topMargin: 6
            anchors.bottomMargin: 6
            verticalAlignment: Text.AlignVCenter
            MouseArea {
                acceptedButtons: Qt.NoButton
                id: hover_handler
                hoverEnabled: true
                anchors.fill: parent
            }
            QuiToolTip {
                text: item_text.text
                delay: 500
                visible: item_text.contentWidth < item_text.implicitWidth
                         && item_text.contentHeight < item_text.implicitHeight
                         && hover_handler.containsMouse
            }
        }
    }

    Component {
        id: com_edit

        QuiTextField {
            id: text_box
            text: String(display)
            readOnly: true === control.columnOptions(column).readOnly
            Component.onCompleted: {
                forceActiveFocus()
                selectAll()
            }
            onAccepted: {
                if (!readOnly) {
                    editTextChaged(text_box.text)
                }
                control.closeEditor()
            }
        }
    }

    Component {
        id: com_edit_multiline

        Item {
            anchors.fill: parent
            Flickable {
                id: item_scroll
                clip: true
                anchors.fill: parent
                ScrollBar.vertical: multiline_text_scroll_bar
                boundsBehavior: Flickable.StopAtBounds
                TextArea.flickable: QuiTextArea {
                    id: text_box
                    text: String(display)
                    readOnly: true === control.columnOptions(column).readOnly
                    verticalAlignment: TextEdit.AlignVCenter
                    rightPadding: 34
                    Component.onCompleted: {
                        forceActiveFocus()
                        selectAll()
                    }
                    Keys.onReturnPressed: function(event) {
                        event.accepted = true
                        if (event.modifiers & Qt.ControlModifier) {
                            text_box.insert(text_box.cursorPosition, "\n")
                            return
                        }
                        if (!readOnly) {
                            editTextChaged(text_box.text)
                        }
                        control.closeEditor()
                    }
                }
            }
            QuiTextIconButton {
                iconSource: QuiFontIcon.ChromeClose
                iconSize: 10
                width: 20
                height: 20
                padding: 0
                verticalPadding: 0
                horizontalPadding: 0
                visible: !text_box.readOnly && text_box.text !== ""
                anchors {
                    verticalCenter: parent.verticalCenter
                    right: parent.right
                    rightMargin: 15
                }
                onClicked: {
                    text_box.text = ""
                }
            }
            QuiScrollBar {
                id: multiline_text_scroll_bar
                anchors {
                    right: parent.right
                    rightMargin: 5
                    top: parent.top
                    bottom: parent.bottom
                    topMargin: 3
                    bottomMargin: 3
                }
            }
        }
    }

    Component {
        id: com_table_delegate

        MouseArea {
            id: item_table_mouse
            property var _model: typeof model === "undefined" || model === null ? null : model
            property var currentTableView: TableView.view
            property var rowModel: control.externalModel ? null : (_model ? _model.rowModel : null)
            property var columnModel: control.externalModel
                                       ? control.columnOptions(column)
                                       : (_model ? _model.columnModel : null)
            property var cellValue: control.externalModel
                                    ? (control.externalCellDisplay(row, column, _model) || ({}))
                                    : (rowModel && columnModel ? rowModel[columnModel.dataIndex] : undefined)
            readonly property bool isObject: typeof cellValue === "object" && cellValue !== null
            readonly property var options: isObject && cellValue.options
                                           && typeof cellValue.options === "object"
                                           ? cellValue.options : ({})
            readonly property bool isRowSelected: !!(
                control.rowSelectionEnabled && rowModel && d.current && rowModel._key === d.current._key)
            readonly property bool isFrozenCell: !!(columnModel && columnModel.frozen === true)
            readonly property bool isMainTable: TableView.view === table_view
            readonly property bool isHidden: isMainTable
                                             ? isFrozenCell
                                             : !!(currentTableView && currentTableView.dataIndex !== undefined
                                                  && columnModel
                                                  && currentTableView.dataIndex !== columnModel.dataIndex)
            readonly property bool editVisible: !!(
                d.editPosition && rowModel && d.editPosition._key === rowModel._key
                && d.editPosition.column === column)

            implicitWidth: isHidden ? Number.MIN_VALUE : TableView.view.width
            visible: !isHidden
            hoverEnabled: control.hoverEnabled
            onEntered: d.rowHoverIndex = row
            onExited: {
                if (d.rowHoverIndex === row) {
                    d.rowHoverIndex = -1
                }
            }
            onCanceled: d.rowHoverIndex = -1
            onPressed: control.closeEditor()
            onDoubleClicked: {
                if (control.externalModel || isObject || !rowModel || !columnModel) {
                    return
                }
                loader_edit.display = cellValue
                d.editDelegate = d.getEditDelegate(column)
                d.editPosition = { _key: rowModel._key, row: row, column: column }
            }
            onClicked: function(event) {
                if (control.externalModel && typeof control.externalCellClickHandler === "function") {
                    control.externalCellClickHandler(row, column, item_table_mouse.options)
                    event.accepted = true
                    return
                }
                if (rowModel && control.rowSelectionEnabled) {
                    d.current = rowModel
                }
                control.closeEditor()
                event.accepted = true
            }
            TableView.onPooled: {
                if (TableView.view === table_view && editVisible) {
                    control.closeEditor()
                }
            }

            Rectangle {
                anchors.fill: parent
                color: {
                    if (item_table_mouse.isRowSelected) {
                        return control.selectedColor
                    }
                    if (control.hoverEnabled && d.rowHoverIndex === row) {
                        return control.hoverColor
                    }
                    if (row % 2 !== 0) {
                        return control.color
                    }
                    return control.zebraEnabled ? control.zebraColor : control.color
                }
                border.color: control.borderColor
                border.width: control.showGridLines ? 1 : 0
            }

            QuiLoader {
                id: item_table_loader
                anchors.fill: parent
                property var tableView: control
                property var model: item_table_mouse._model
                property var display: item_table_mouse.cellValue
                property var rowModel: item_table_mouse.rowModel
                property var columnModel: item_table_mouse.columnModel
                property int row: typeof item_table_mouse.row === "number" ? item_table_mouse.row : 0
                property int column: typeof item_table_mouse.column === "number" ? item_table_mouse.column : 0
                property var options: item_table_mouse.options
                onLoaded: control.applyLoaderOptions(item_table_loader)
                onOptionsChanged: control.applyLoaderOptions(item_table_loader)
                sourceComponent: item_table_mouse.isObject && display && display.comId
                                 ? display.comId : com_text
            }

            Item {
                anchors.fill: parent
                visible: item_table_mouse.isRowSelected
                Rectangle {
                    width: 1
                    height: parent.height
                    anchors.left: parent.left
                    color: control.selectedBorderColor
                    visible: column === 0 && (!item_table_mouse.isMainTable || !item_table_mouse.isFrozenCell)
                }
                Rectangle {
                    width: 1
                    height: parent.height
                    anchors.right: parent.right
                    color: control.selectedBorderColor
                    visible: column === control.columns - 1 && (!item_table_mouse.isMainTable || !item_table_mouse.isFrozenCell)
                }
                Rectangle {
                    width: parent.width
                    height: 1
                    anchors.top: parent.top
                    color: control.selectedBorderColor
                }
                Rectangle {
                    width: parent.width
                    height: 1
                    anchors.bottom: parent.bottom
                    color: control.selectedBorderColor
                }
            }

            QuiLoader {
                id: loader_edit
                property var tableView: control
                property var display
                property int column: d.editPosition ? d.editPosition.column : 0
                property int row: d.editPosition ? d.editPosition.row : 0
                anchors.fill: parent
                anchors.margins: 1
                z: 999
                signal editTextChaged(string text)
                sourceComponent: {
                    if (!item_table_mouse.editVisible) {
                        return undefined
                    }
                    if (item_table_mouse.isMainTable && item_table_mouse.isFrozenCell) {
                        return undefined
                    }
                    return d.editDelegate
                }
                onEditTextChaged: function(text) {
                    let obj = control.getRow(row)
                    let columnModel = control.columnSource[column]
                    if (obj && columnModel) {
                        obj[columnModel.dataIndex] = text
                        control.setRow(row, obj)
                    }
                }
            }
        }
    }

    /* ==================== 外观 ==================== */
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

    TableView {
        id: header_horizontal
        visible: control.horizontalHeaderVisible && control.horizonalHeaderVisible
        height: visible ? Math.max(1, contentHeight) : 0
        anchors {
            left: header_vertical.right
            right: parent.right
            top: parent.top
        }
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        columnSpacing: table_view.columnSpacing
        syncDirection: Qt.Horizontal
        syncView: d.destroying ? null : table_view
        model: header_column_model
        delegate: default_header_delegate

        onContentXChanged: {
            if (!d.destroying) {
                Qt.callLater(control.forceLayout)
            }
        }
    }

    TableView {
        id: header_vertical
        visible: control.verticalHeaderVisible
        implicitWidth: visible ? Math.max(1, contentWidth) : 0
        implicitHeight: syncView ? syncView.height : 0
        anchors {
            top: table_view.top
            left: parent.left
        }
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        syncDirection: Qt.Vertical
        syncView: d.destroying ? null : table_view
        model: d.destroying ? null : header_row_model
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
        model: d.destroying ? null : table_sort_model
        delegate: d.destroying ? null : com_table_delegate

        onRowsChanged: {
            if (d.destroying) {
                return
            }
            control.closeEditor()
            control.updateRowIndex()
            Qt.callLater(control.forceLayout)
        }
        onColumnsChanged: {
            if (!d.destroying) {
                Qt.callLater(control.forceLayout)
            }
        }
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
    }

    Item {
        id: frozen_layer
        anchors.left: table_view.left
        anchors.right: table_view.right
        anchors.top: header_horizontal.visible ? header_horizontal.top : table_view.top
        anchors.bottom: table_view.bottom
        visible: control.frozenColumnIndexes().length > 0
        clip: true
        z: 10

        Repeater {
            model: d.destroying ? [] : control.frozenColumnIndexes()

            Item {
                id: frozen_column_item
                property int sourceColumn: modelData

                x: control.frozenColumnVisualX(sourceColumn)
                width: control.columnWidth(sourceColumn)
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                clip: true

                TableView {
                    id: frozen_header
                    property string dataIndex: String(control.columnOptions(sourceColumn).dataIndex)
                    visible: header_horizontal.visible
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: header_horizontal.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: false
                    contentWidth: width
                    model: header_column_model
                    delegate: default_header_delegate
                }

                TableView {
                    id: frozen_table
                    property string dataIndex: String(control.columnOptions(sourceColumn).dataIndex)
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
                    model: d.destroying ? null : table_sort_model
                    delegate: d.destroying ? null : table_view.delegate
                    contentWidth: width
                    rowSpacing: table_view.rowSpacing
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

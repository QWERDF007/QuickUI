import QtQuick
import QtTest

import quickui

Item {
    width: 640
    height: 480

    QuiTableView {
        id: dataTable
        width: 300
        height: 200
        columnSource: [
            { title: "姓名", dataIndex: "name", width: 80, minimumWidth: 60 },
            { title: "年龄", dataIndex: "age", width: 60, minimumWidth: 60 }
        ]
        dataSource: [
            { name: "alice", age: 30, _key: "k1" },
            { name: "bob", age: 20, _key: "k2" },
            { name: "carol", age: 40, _key: "k3" }
        ]
    }

    QuiTableModel {
        id: rawModel
        columnSource: [ { dataIndex: "name" }, { dataIndex: "age" } ]
        rows: [ { name: "a", age: 1 }, { name: "b", age: 2 }, { name: "c", age: 3 } ]
    }

    TableView {
        id: rawView
        y: 440
        width: 300
        height: 200
        model: rawModel
        columnWidthProvider: function(c) { return 80 }
        rowHeightProvider: function(r) { return 40 }
        delegate: Text { text: "x" }
    }

    QuiTableView {
        id: appStyleTable
        y: 440
        width: 300
        height: 200
        dataSource: []
        columnSource: [
            { title: "ID", dataIndex: "task_id", width: 80, minimumWidth: 80 },
            { title: "模型", dataIndex: "model_name", width: 180, minimumWidth: 120 },
            { title: "类型", dataIndex: "task_type", width: 140, minimumWidth: 100 }
        ]
        Component.onCompleted: {
            appStyleTable.dataSource = [
                { task_id: 1, model_name: "m1", task_type: "t1", _key: "a1" },
                { task_id: 2, model_name: "m2", task_type: "t2", _key: "a2" }
            ]
        }
    }

    TestCase {
        name: "QuiTableViewTest"
        when: windowShown

        function test_appStyleUsage() {
            compare(appStyleTable.rows, 2)
            compare(appStyleTable.columns, 3)
            compare(appStyleTable.getRow(0).task_id, 1)
        }

        function test_headerModels() {
            wait(50)
            compare(dataTable.horizontalHeader.columns, 2)
            compare(dataTable.verticalHeader.rows, 3)
            compare(dataTable.horizontalHeader.model.columns[0].display, "name")
            compare(dataTable.horizontalHeader.model.columns[1].display, "age")
            compare(dataTable.horizontalHeader.model.rows[0].name.title, "姓名")
            compare(dataTable.horizontalHeader.model.rows[0].age.title, "年龄")
        }

        function test_dataSourcePipeline() {
            compare(dataTable.rows, 3)
            compare(dataTable.columns, 2)
            compare(dataTable.sourceModel.rowCount, 3)
            compare(dataTable.getRow(0).name, "alice")
            compare(dataTable.getRow(1).name, "bob")
        }

        function test_rowOperations() {
            dataTable.setRow(1, { name: "bobby", age: 21 })
            compare(dataTable.getRow(1).name, "bobby")
            dataTable.appendRow({ name: "dave", age: 25 })
            compare(dataTable.sourceModel.rowCount, 4)
            wait(50)
            compare(dataTable.rows, 4)
            dataTable.removeRow(3)
            compare(dataTable.sourceModel.rowCount, 3)
            wait(50)
            compare(dataTable.rows, 3)
        }

        function test_customItem() {
            var item = dataTable.customItem(null, { checked: true })
            compare(item.comId, null)
            compare(item.options.checked, true)
        }

        function test_filterAndSort() {
            dataTable.filter(function(index) { return index !== 1 })
            compare(dataTable.view.model.rowCount(), 2)
            wait(50)
            compare(dataTable.rows, 2)
            compare(dataTable.getRow(0).name, "alice")
            compare(dataTable.getRow(1).name, "carol")
            dataTable.filter(undefined)
            wait(50)
            compare(dataTable.rows, 3)

            dataTable.sort(function(l, r) { return l < r })
            compare(dataTable.getRow(0).name, "carol")
            compare(dataTable.getRow(1).name, "bob")
            compare(dataTable.getRow(2).name, "alice")
            dataTable.sort(undefined)
            wait(50)
            compare(dataTable.rows, 3)
        }

        function test_keyPreservedOnUpdate() {
            dataTable.sort(undefined)
            dataTable.setRow(0, { name: "alicia", age: 31 })
            compare(dataTable.getRow(0)._key, "k1")
        }

        function test_currentIndex() {
            compare(dataTable.currentIndex(), -1)
            dataTable.setCurrent(1)
            compare(dataTable.currentIndex(), 1)
            compare(dataTable.current._key, "k2")
        }

        function test_rawModel() {
            compare(rawView.rows, 3)
        }
    }
}

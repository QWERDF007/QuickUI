import QtQuick
import QtTest
import quickui

Item {
    id: root

    Component {
        id: comboBoxComponent
        QuiComboBox {
            editable: true
            model: ["Alpha", "Beta"]
        }
    }

    TestCase {
        name: "QuiComboBoxTest"
        when: windowShown

        function test_commitSignal() {
            const comboBox = createTemporaryObject(comboBoxComponent, root)
            verify(comboBox !== null)

            const committed = []
            comboBox.commit.connect(function(text) {
                committed.push(text)
            })

            comboBox.editText = "Manual"
            const event = { accepted: false }
            comboBox.content.handleCommit(event)

            compare(committed.length, 1)
            compare(committed[0], "Manual")
            verify(event.accepted)
        }
    }
}


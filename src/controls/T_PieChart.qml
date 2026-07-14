import QtQuick
import QtQuick.Layouts

import quickui

QuiScrollablePage {
    id: control

    title: qsTr("Pie Chart")

    readonly property var sampleChartData: ({
        labels: [
            "Red",
            "Blue",
            "Yellow"
        ],
        datasets: [{
            label: "My First Dataset",
            data: [300, 50, 100],
            backgroundColor: [
                "rgb(255, 99, 132)",
                "rgb(54, 162, 235)",
                "rgb(255, 205, 86)"
            ],
            hoverOffset: 4
        }]
    })

    readonly property var sampleChartOptions: ({
        maintainAspectRatio: false,
        legend: {
            display: false
        },
        tooltips: {
            mode: "index",
            intersect: false
        }
    })

    QuiFrame {
        Layout.fillWidth: true
        Layout.preferredWidth: 500
        Layout.preferredHeight: 370
        padding: 10
        Layout.topMargin: 20

        QuiChart {
            anchors.fill: parent
            chartType: "doughnut"
            chartData: control.sampleChartData
            chartOptions: control.sampleChartOptions
        }
    }

    QuiFrame {
        Layout.fillWidth: true
        Layout.preferredWidth: 500
        Layout.preferredHeight: 370
        padding: 10
        Layout.topMargin: 20

        QuiChart {
            anchors.fill: parent
            chartType: "pie"
            chartData: control.sampleChartData
            chartOptions: control.sampleChartOptions
        }
    }
}

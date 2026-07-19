import QtQuick

import quickui

Canvas {
    id: control

    // FluentUI-compatible chart interface.
    property string chartType: "pie"
    property var chartData: ({ labels: [], datasets: [] })
    property var chartOptions: ({})
    property real chartAnimationProgress: 0.1
    property int animationEasingType: Easing.InOutExpo
    property real animationDuration: 300
    property alias animationRunning: chartAnimator.running
    property int hoveredIndex: -1
    property real tooltipX: 0
    property real tooltipY: 0

    signal animationFinished()

    function chartDataset() {
        var datasets = control.chartData && control.chartData.datasets ? control.chartData.datasets : []
        return datasets.length > 0 && datasets[0] ? datasets[0] : ({})
    }

    function valueAt(index) {
        var values = chartDataset().data || []
        if (index < 0 || index >= values.length)
            return 0
        var value = Number(values[index])
        return isFinite(value) && value > 0 ? value : 0
    }

    function colorAt(index) {
        var colors = chartDataset().backgroundColor || []
        if (index >= 0 && index < colors.length && colors[index])
            return colors[index]
        return control.defaultColors[index % control.defaultColors.length]
    }

    function tooltipAt(index) {
        var tooltips = chartDataset().tooltips || []
        return index >= 0 && index < tooltips.length ? String(tooltips[index]) : ""
    }

    function totalValue() {
        var values = chartDataset().data || []
        var total = 0
        for (var i = 0; i < values.length; ++i)
            total += control.valueAt(i)
        return total
    }

    function sliceCount() {
        var labels = control.chartData && control.chartData.labels ? control.chartData.labels : []
        var values = chartDataset().data || []
        return Math.min(labels.length, values.length)
    }

    function titleText() {
        var title = control.chartOptions && control.chartOptions.title
                       ? control.chartOptions.title
                       : ({})
        return title.display && title.text ? String(title.text) : ""
    }

    function titleHeight() {
        return control.titleText().length > 0 ? 26 : 0
    }

    function chartRotation() {
        var value = control.chartOptions ? Number(control.chartOptions.rotation) : NaN
        return isFinite(value) ? value : -Math.PI / 2
    }

    function cutoutPercentage() {
        if (control.chartType !== "doughnut")
            return 0
        var value = control.chartOptions ? Number(control.chartOptions.cutoutPercentage) : NaN
        return isFinite(value) ? Math.max(0, Math.min(95, value)) : 50
    }

    function plotGeometry() {
        var top = control.titleHeight()
        var plotHeight = Math.max(0, control.height - top)
        var radius = Math.max(0, Math.min(control.width, plotHeight) / 2 - 8)
        return {
            centerX: control.width / 2,
            centerY: top + plotHeight / 2,
            radius: radius
        }
    }

    function hitTest(x, y) {
        var geometry = control.plotGeometry()
        var dx = x - geometry.centerX
        var dy = y - geometry.centerY
        var distance = Math.sqrt(dx * dx + dy * dy)
        var innerRadius = geometry.radius * control.cutoutPercentage() / 100
        if (geometry.radius <= 0 || distance > geometry.radius + 8 || distance < innerRadius)
            return -1

        var total = control.totalValue()
        if (total <= 0)
            return -1

        var angle = Math.atan2(dy, dx) - control.chartRotation()
        while (angle < 0)
            angle += Math.PI * 2
        while (angle >= Math.PI * 2)
            angle -= Math.PI * 2

        var accumulated = 0
        for (var i = 0; i < control.sliceCount(); ++i) {
            accumulated += control.valueAt(i) / total * Math.PI * 2
            if (angle <= accumulated)
                return i
        }
        return control.sliceCount() - 1
    }

    function animateToNewData() {
        control.chartAnimationProgress = 0.1
        chartAnimator.restart()
    }

    readonly property var defaultColors: [
        "#4CC9F0",
        "#4895EF",
        "#4361EE",
        "#3F37C9",
        "#7209B7",
        "#B5179E",
        "#F72585",
        "#F8961E",
        "#90BE6D",
        "#43AA8B"
    ]

    onChartDataChanged: {
        control.hoveredIndex = -1
        control.animateToNewData()
        control.requestPaint()
    }
    onChartOptionsChanged: control.requestPaint()
    onChartAnimationProgressChanged: control.requestPaint()
    onHoveredIndexChanged: control.requestPaint()
    onWidthChanged: control.requestPaint()
    onHeightChanged: control.requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        var geometry = control.plotGeometry()
        var total = control.totalValue()
        if (geometry.radius <= 0)
            return

        if (total <= 0) {
            ctx.beginPath()
            ctx.arc(geometry.centerX, geometry.centerY, geometry.radius, 0, Math.PI * 2)
            ctx.fillStyle = QuiColor.Background
            ctx.fill()
            ctx.strokeStyle = QuiColor.Border
            ctx.lineWidth = 1
            ctx.stroke()
            return
        }

        var progress = Math.max(0.1, Math.min(1, control.chartAnimationProgress))
        var startAngle = control.chartRotation()
        var innerRadius = geometry.radius * control.cutoutPercentage() / 100
        var hoverOffset = Number(chartDataset().hoverOffset)
        if (!isFinite(hoverOffset))
            hoverOffset = 4

        for (var i = 0; i < control.sliceCount(); ++i) {
            var sliceAngle = control.valueAt(i) / total * Math.PI * 2 * progress
            var endAngle = startAngle + sliceAngle
            var drawCenterX = geometry.centerX
            var drawCenterY = geometry.centerY
            var drawRadius = geometry.radius

            if (i === control.hoveredIndex) {
                var middleAngle = (startAngle + endAngle) / 2
                drawCenterX += Math.cos(middleAngle) * hoverOffset
                drawCenterY += Math.sin(middleAngle) * hoverOffset
            }

            ctx.beginPath()
            ctx.moveTo(drawCenterX + Math.cos(startAngle) * innerRadius, drawCenterY + Math.sin(startAngle) * innerRadius)
            ctx.arc(drawCenterX, drawCenterY, drawRadius, startAngle, endAngle)
            if (innerRadius > 0)
                ctx.arc(drawCenterX, drawCenterY, innerRadius, endAngle, startAngle, true)
            else
                ctx.lineTo(drawCenterX, drawCenterY)
            ctx.closePath()
            ctx.fillStyle = control.colorAt(i)
            ctx.fill()
            ctx.strokeStyle = QuiColor.Primary
            ctx.lineWidth = 1.5
            ctx.stroke()
            startAngle = endAngle
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onPositionChanged: function(mouse) {
            var nextIndex = control.hitTest(mouse.x, mouse.y)
            if (nextIndex !== control.hoveredIndex)
                control.hoveredIndex = nextIndex
            control.tooltipX = mouse.x
            control.tooltipY = mouse.y
        }
        onExited: control.hoveredIndex = -1
    }

    QuiText {
        id: chartTitle
        visible: control.titleText().length > 0
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 26
        text: control.titleText()
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: QuiColor.FontPrimary
    }

    QuiText {
        anchors.centerIn: parent
        visible: control.totalValue() <= 0
        text: qsTr("暂无数据")
        color: QuiColor.FontDark
    }

    QuiToolTip {
        visible: control.hoveredIndex >= 0
                 && control.tooltipAt(control.hoveredIndex).length > 0
        z: 10
        width: 178
        delay: 0
        x: Math.max(4, Math.min(control.width - width - 4, control.tooltipX + 8))
        y: Math.max(4, Math.min(control.height - height - 4, control.tooltipY + 8))
        text: control.tooltipAt(control.hoveredIndex)
    }

    PropertyAnimation {
        id: chartAnimator
        target: control
        property: "chartAnimationProgress"
        from: 0.1
        to: 1
        duration: control.animationDuration
        easing.type: control.animationEasingType
        onFinished: control.animationFinished()
    }
}

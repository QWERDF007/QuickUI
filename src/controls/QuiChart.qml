import QtQuick

import "../JS/Chart.js" as Chart
import quickui

/*
 * A QML adapter for the Chart.js QML build.
 *
 * QuiChart deliberately keeps the Chart.js data/configuration contract instead
 * of knowing anything about a particular domain.  Any chart type registered by
 * Chart.js (line, bar, pie, doughnut, radar, ...) can therefore be selected by
 * changing chartType and supplying the corresponding chartData/chartOptions.
 */
Canvas {
    id: control

    // Chart.js configuration surface.
    property string chartType: "pie"
    property var chartData: ({ labels: [], datasets: [] })
    property var chartOptions: ({})

    // The QML animation drives Chart.js' draw(easing) method.  Chart.js' own
    // animation scheduler is disabled by chartOptionsForChart() below because
    // it cannot schedule frames for a QML Canvas.
    property real chartAnimationProgress: 0.1
    property int animationEasingType: Easing.InOutExpo
    property real animationDuration: 300
    property alias animationRunning: chartAnimator.running

    // Interaction is kept at the adapter level so chart-specific event
    // handling remains in Chart.js options (onClick/onHover/etc.).
    property bool interactive: true

    // Empty-state rendering is generic and can be disabled or replaced by a
    // consumer that wants to provide its own placeholder.
    property bool showEmptyState: true
    property string emptyText: qsTr("暂无数据")

    readonly property var chartInstance: d.jsChart
    readonly property bool chartReady: d.jsChart !== null && !d.recreatePending

    signal animationFinished()
    signal chartCreated(var chart)
    signal chartUpdated()
    signal chartDestroyed()
    signal chartError(string message)

    QtObject {
        id: d

        property var jsChart: null
        property var memorizedContext: null
        property var memorizedData: null
        property var memorizedOptions: null
        property string memorizedType: ""
        property bool recreatePending: true
        property bool updatePending: true
        property string lastError: ""
    }

    function copyObject(source) {
        var result = ({})
        if (!source || typeof source !== "object")
            return result

        for (var key in source)
            result[key] = source[key]
        return result
    }

    function chartDataForChart() {
        if (control.chartData && typeof control.chartData === "object")
            return control.chartData
        return ({ labels: [], datasets: [] })
    }

    function chartOptionsForChart() {
        var options = control.copyObject(control.chartOptions)
        var animation = control.copyObject(options.animation)

        // The QML PropertyAnimation below is the single frame scheduler.  A
        // zero Chart.js duration keeps update() synchronous and prevents an
        // inaccessible browser animation loop from competing with it.
        animation.duration = 0
        options.animation = animation
        return options
    }

    function hasData() {
        var data = control.chartData
        var datasets = data && data.datasets ? data.datasets : []
        for (var i = 0; i < datasets.length; ++i) {
            var values = datasets[i] && datasets[i].data ? datasets[i].data : []
            if (values.length > 0)
                return true
        }
        return false
    }

    function reportError(error) {
        var message = String(error)
        if (message === d.lastError)
            return
        d.lastError = message
        control.chartError(message)
    }

    function clearError() {
        d.lastError = ""
    }

    function destroyChart() {
        var chart = d.jsChart
        d.jsChart = null
        d.memorizedContext = null
        d.memorizedData = null
        d.memorizedOptions = null
        d.memorizedType = ""
        d.recreatePending = true
        d.updatePending = false
        event.handler = undefined

        if (!chart)
            return

        try {
            chart.destroy()
        } catch (error) {
            reportError(error)
        }
        control.chartDestroyed()
    }

    function createChart(context) {
        // A context can change when the Canvas is recreated, so release all
        // resources associated with the previous Chart.js instance first.
        control.destroyChart()

        var chart = null
        try {
            chart = Chart.build(context, {
                type: control.chartType || "line",
                data: control.chartDataForChart(),
                options: control.chartOptionsForChart()
            })

            if (!chart || !chart.ctx)
                throw new Error("Chart.js could not acquire the Canvas 2D context")

            d.jsChart = chart
            d.jsChart.bindEvents(function(newHandler) {
                event.handler = newHandler
            })

            d.memorizedContext = context
            d.memorizedData = control.chartData
            d.memorizedOptions = control.chartOptions
            d.memorizedType = control.chartType
            d.recreatePending = false
            d.updatePending = false
            clearError()
            control.chartCreated(chart)
        } catch (error) {
            // Chart.build may have created an instance before reporting an
            // invalid configuration.  Destroy it when possible so a failed
            // chart does not remain in Chart.instances.
            if (chart) {
                try {
                    chart.destroy()
                } catch (ignored) {
                }
            }
            d.jsChart = null
            d.memorizedContext = context
            d.recreatePending = false
            d.updatePending = false
            reportError(error)
        }
    }

    function applyPendingUpdate() {
        if (!d.jsChart || !d.updatePending)
            return

        try {
            d.jsChart.config.data = control.chartDataForChart()
            d.jsChart.config.options = control.chartOptionsForChart()
            d.jsChart.update({ duration: 0 })

            d.memorizedData = control.chartData
            d.memorizedOptions = control.chartOptions
            d.updatePending = false
            clearError()
            control.chartUpdated()
        } catch (error) {
            d.updatePending = false
            reportError(error)
        }
    }

    // Public API for callers that mutate arrays/objects in place.  Normal QML
    // property changes call this automatically; explicit updateChart() covers
    // data models that keep the same QVariantMap instance.
    function updateChart() {
        d.updatePending = true
        control.animateToNewData()
    }

    // Public API for changing chart type or replacing the rendering context.
    function rebuildChart() {
        d.recreatePending = true
        d.updatePending = false
        control.animateToNewData()
    }

    function animateToNewData() {
        control.chartAnimationProgress = 0.1
        chartAnimator.restart()
        control.requestPaint()
    }

    onChartDataChanged: control.updateChart()
    onChartOptionsChanged: control.updateChart()
    onChartTypeChanged: control.rebuildChart()
    onChartAnimationProgressChanged: control.requestPaint()
    onWidthChanged: {
        if (d.jsChart) {
            try {
                d.jsChart.resize()
            } catch (error) {
                reportError(error)
            }
        }
        control.requestPaint()
    }
    onHeightChanged: {
        if (d.jsChart) {
            try {
                d.jsChart.resize()
            } catch (error) {
                reportError(error)
            }
        }
        control.requestPaint()
    }

    onPaint: {
        var context = control.getContext("2d")
        if (!context)
            return

        if (d.recreatePending || !d.jsChart || d.memorizedContext !== context)
            control.createChart(context)

        if (!d.jsChart)
            return

        control.applyPendingUpdate()

        try {
            var progress = Math.max(0, Math.min(1, Number(control.chartAnimationProgress)))
            d.jsChart.draw(isFinite(progress) ? progress : 1)
            clearError()
        } catch (error) {
            reportError(error)
        }
    }

    MouseArea {
        id: event
        anchors.fill: control
        enabled: control.interactive
        hoverEnabled: control.interactive
        acceptedButtons: Qt.AllButtons

        property var handler: undefined
        property QtObject mouseEvent: QtObject {
            // Chart.js treats this as a QML/local-coordinate event and
            // therefore bypasses the browser/DOM bounding-rect path.  The
            // `native` identifier is reserved by QML, so the adapter exposes
            // an explicitly named flag and Chart.js accepts both forms.
            property bool nativeEvent: true
            property int left: 0
            property int top: 0
            // Preserve the fractional coordinates supplied by QML.  Arc hit
            // testing is angular, so truncating these values can move a
            // pointer across a slice boundary on scaled/high-DPI layouts.
            property real x: 0
            property real y: 0
            property real clientX: 0
            property real clientY: 0
            property string type: ""
            property var target: control
        }

        function submitEvent(mouse, type) {
            mouseEvent.type = type
            mouseEvent.clientX = mouse ? mouse.x : 0
            mouseEvent.clientY = mouse ? mouse.y : 0
            mouseEvent.x = mouse ? mouse.x : 0
            mouseEvent.y = mouse ? mouse.y : 0
            mouseEvent.left = 0
            mouseEvent.top = 0
            mouseEvent.target = control

            if (handler)
                handler(mouseEvent)
            control.requestPaint()
        }

        onClicked: function(mouse) { submitEvent(mouse, "click") }
        onPositionChanged: function(mouse) { submitEvent(mouse, "mousemove") }
        onExited: submitEvent(null, "mouseout")
        onEntered: submitEvent(null, "mouseenter")
        onPressed: function(mouse) { submitEvent(mouse, "mousedown") }
        onReleased: function(mouse) { submitEvent(mouse, "mouseup") }
    }

    QuiText {
        anchors.centerIn: parent
        visible: control.showEmptyState && control.emptyText.length > 0 && !control.hasData()
        text: control.emptyText
        color: QuiColor.FontDark
    }

    PropertyAnimation {
        id: chartAnimator
        target: control
        property: "chartAnimationProgress"
        alwaysRunToEnd: true
        from: 0.1
        to: 1
        duration: control.animationDuration
        easing.type: control.animationEasingType
        onFinished: control.animationFinished()
    }

    Component.onDestruction: control.destroyChart()
}

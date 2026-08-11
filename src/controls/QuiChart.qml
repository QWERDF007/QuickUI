import QtQuick

import "../JS/Chart.js" as Chart
import quickui

/**
 * @brief Chart.js QML 构建的通用适配器。
 *
 * QuiChart 保持 Chart.js 的数据和配置契约，不绑定具体业务领域；调用方
 * 只需修改 chartType 并提供对应的 chartData/chartOptions 即可使用已注册图表。
 */
Canvas {
    id: control

    /** Chart.js 配置入口。 */
    property string chartType: "pie"
    property var chartData: ({ labels: [], datasets: [] })
    property var chartOptions: ({})

    /**
     * QML 动画负责驱动 Chart.js 的 draw(easing)，Chart.js 自身动画调度在
     * chartOptionsForChart() 中关闭，因为它无法为 QML Canvas 调度帧。
     */
    property real chartAnimationProgress: 0.1
    property int animationEasingType: Easing.InOutExpo
    property real animationDuration: 300
    property alias animationRunning: chartAnimator.running

    /** 交互保留在适配器层，具体图表事件仍由 Chart.js 配置处理。 */
    property bool interactive: true

    /** 空状态绘制是通用行为，调用方可以关闭或替换占位内容。 */
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

    function copyValue(source) {
        if (source === null || source === undefined || typeof source !== "object")
            return source

        if (Array.isArray(source)) {
            var array = []
            for (var index = 0; index < source.length; ++index)
                array.push(copyValue(source[index]))
            return array
        }

        var result = ({})
        for (var key in source)
            result[key] = copyValue(source[key])
        return result
    }

    function copyObject(source) {
        var result = copyValue(source)
        return result && typeof result === "object" && !Array.isArray(result) ? result : ({})
    }

    function chartDataForChart() {
        if (control.chartData && typeof control.chartData === "object")
            return copyValue(control.chartData)
        return ({ labels: [], datasets: [] })
    }

    function chartOptionsForChart() {
        var options = control.copyObject(control.chartOptions)
        var animation = control.copyObject(options.animation)

        /**
         * QML PropertyAnimation 是唯一的帧调度器。Chart.js 时长设为零可让
         * update() 同步执行，避免不可控的浏览器动画循环产生竞争。
         */
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
        /** Canvas 重建后上下文可能变化，因此先释放旧 Chart.js 实例的资源。 */
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
            control.syncChartSize()
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
            /**
             * Chart.build 可能在报告配置无效前已经创建实例；尽可能销毁它，
             * 避免失败图表残留在 Chart.instances 中。
             */
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
            /**
             * Chart.js 的 updateConfig() 读取 chart.options 而不是 config.options，
             * 两处同时赋值才能使坐标轴变化真正重建。
             */
            d.jsChart.config.options = d.jsChart.options = control.chartOptionsForChart()
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

    /**
     * Chart.js 保存自身的宽高状态。QML Canvas 的上下文可能报告过期的后备
     * 存储尺寸，导致图表被绘制到一像素高区域，因此始终使用当前 Item 几何。
     */
    function syncChartSize() {
        var chart = d.jsChart
        if (!chart)
            return

        var w = Math.max(0, Math.floor(control.width))
        var h = Math.max(0, Math.floor(control.height))
        if (chart.width === w && chart.height === h)
            return

        chart.width = w
        chart.height = h
        try {
            if (chart.canvas) {
                chart.canvas.width = w
                chart.canvas.height = h
            }
        } catch (error) {
            reportError(error)
        }

        try {
            chart.update({duration: 0})
            clearError()
        } catch (error) {
            reportError(error)
        }
        control.requestPaint()
    }

    /**
     * @brief 处理原地修改数组/对象的数据更新。
     *
     * 普通 QML 属性变化会自动触发该函数，保持同一 QVariantMap 实例的模型
     * 可显式调用 updateChart()。
     */
    function updateChart() {
        d.updatePending = true
        control.animateToNewData()
    }

    /** @brief 修改图表类型或替换绘制上下文。 */
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
        control.syncChartSize()
        control.requestPaint()
    }
    onHeightChanged: {
        control.syncChartSize()
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

        control.syncChartSize()

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
            /**
             * Chart.js 将该事件视为 QML 本地坐标事件，因此不经过浏览器 DOM
             * 边界路径；native 标识被 QML 保留，适配器使用显式命名的标记。
             */
            property bool nativeEvent: true
            property int left: 0
            property int top: 0
            /**
             * 保留 QML 提供的小数坐标。圆弧命中检测依赖角度，截断坐标可能在
             * 缩放或高 DPI 布局中把指针移到相邻切片。
             */
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

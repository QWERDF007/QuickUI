pragma Singleton

import QtQuick

QtObject {
    function clamp(value, minimum, maximum) {
        return Math.min(Math.max(value, minimum), maximum)
    }

    function withOpacity(color, opacity) {
        const c = typeof color === "string" ? Qt.color(color) : color
        return Qt.rgba(c.r, c.g, c.b, clamp(opacity, 0.0, 1.0))
    }
}

////filepath: f:\MyProject\CloudStorageHub\ui\qtquick\Component\TtScrollBar.qml
import QtQuick
import QtQuick.Controls

ScrollBar {
    id: scrollBar
    
    // 基础属性 - 使用非常鲜明的颜色
    property color backgroundColor: "#FF0000" // 亮红色
    property color handleColor: "#00FF00"     // 亮绿色
    
    // 滚动条尺寸 - 加大使其更明显
    implicitWidth: orientation === Qt.Vertical ? 20 : implicitWidth
    implicitHeight: orientation === Qt.Horizontal ? 20 : implicitHeight
    
    // 始终显示且完全不透明
    policy: ScrollBar.AlwaysOn
    opacity: 1.0
    
    // Z值提高，确保不被其他元素覆盖
    z: 10000
    
    // 自定义背景 - 使用鲜明的颜色
    background: Rectangle {
        color: scrollBar.backgroundColor
        border.color: "black"
        border.width: 2
    }
    
    // 自定义滑块 - 使用鲜明的颜色
    contentItem: Rectangle {
        implicitWidth: 16
        implicitHeight: 16
        color: scrollBar.handleColor
        border.color: "black"
        border.width: 2
    }
}
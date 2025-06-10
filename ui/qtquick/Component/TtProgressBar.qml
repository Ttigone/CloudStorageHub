// 创建与DownloadPanel一致的进度条组件
import QtQuick
import QtQuick.Controls

Rectangle {
    id: progressBar
    
    // 公开属性
    property real progress: 0.0
    property string status: ""
    property bool animated: true
    property bool showGloss: true
    property bool showShimmer: false
    property int animationDuration: 300
    
    // 样式属性
    property color backgroundColor: "#F3F4F6"
    
    // 默认样式
    color: backgroundColor
    
    Rectangle {
        id: progressRect
        width: parent.width * Math.max(0, Math.min(1, progressBar.progress))
        height: parent.height
        radius: parent.radius
        
        // 与DownloadPanel完全一致的颜色逻辑
        color: {
            const progress = progressBar.progress || 0
            if (progress >= 1.0)
                return "#10B981"  // 完成 - 绿色
            if (progressBar.status === "暂停")
                return "#F59E0B"  // 暂停 - 橙色
            if (progressBar.status === "错误")
                return "#EF4444"  // 错误 - 红色
            return "#3B82F6"      // 下载中 - 蓝色
        }
        
        Behavior on width {
            enabled: progressBar.animated
            NumberAnimation {
                duration: progressBar.animationDuration
                easing.type: Easing.OutCubic
            }
        }
        
        Behavior on color {
            enabled: progressBar.animated
            ColorAnimation {
                duration: 200
            }
        }
        
        // 光泽效果
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            visible: progressBar.showGloss
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#60FFFFFF" }
                GradientStop { position: 0.5; color: "#30FFFFFF" }
                GradientStop { position: 1.0; color: "#10FFFFFF" }
            }
        }
        
        // 闪光效果 - 只在活跃下载时显示
        Rectangle {
            width: 20
            height: parent.height
            radius: parent.radius
            visible: {
                return progressBar.showShimmer && 
                       progressBar.progress > 0 && 
                       progressBar.progress < 1 && 
                       progressBar.status !== "暂停" && 
                       progressBar.status !== "错误"
            }
            
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: "#60FFFFFF" }
                GradientStop { position: 1.0; color: "transparent" }
            }
            
            SequentialAnimation on x {
                running: parent.visible
                loops: Animation.Infinite
                
                NumberAnimation {
                    from: -20
                    to: progressRect.width + 20
                    duration: 2000
                    easing.type: Easing.InOutQuad
                }
                
                PauseAnimation { duration: 1000 }
            }
        }
    }
}
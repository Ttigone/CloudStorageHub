////filepath: f:\MyProject\CloudStorageHub\ui\qtquick\Component\DownloadHistoryView.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: historyView
    clip: true
    
    property var model: null
    
    signal retryDownload(var item)
    signal removeFromHistory(string jobId)
    
    ListView {
        id: listView
        model: historyView.model
        spacing: 8
        
        delegate: Rectangle {
            width: listView.width
            height: 72
            radius: 8
            color: "#FFFFFF"
            border.color: "#E5E7EB"
            border.width: 1
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16
                
                // 文件图标
                Rectangle {
                    width: 40
                    height: 40
                    radius: 6
                    color: {
                        if (model.status === "已完成") return "#DCFCE7"
                        if (model.status === "错误") return "#FEE2E2"
                        return "#F3F4F6"
                    }
                    
                    Text {
                        anchors.centerIn: parent
                        text: {
                            if (model.status === "已完成") return "✓"
                            if (model.status === "错误") return "✗"
                            return "📄"
                        }
                        font.pixelSize: 18
                        color: {
                            if (model.status === "已完成") return "#16A34A"
                            if (model.status === "错误") return "#DC2626"
                            return "#6B7280"
                        }
                    }
                }
                
                // 文件信息
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    
                    Text {
                        text: model.name || "未知文件"
                        font.pixelSize: 15
                        font.weight: Font.Medium
                        color: "#1F2937"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        
                        Text {
                            text: model.status || "未知状态"
                            font.pixelSize: 13
                            color: {
                                if (model.status === "已完成") return "#16A34A"
                                if (model.status === "错误") return "#DC2626"
                                return "#6B7280"
                            }
                        }
                        
                        Text {
                            text: model.size || "未知大小"
                            font.pixelSize: 13
                            color: "#6B7280"
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Text {
                            text: formatCompletedTime(model.completedTime)
                            font.pixelSize: 12
                            color: "#9CA3AF"
                        }
                    }
                }
                
                // 操作按钮
                RowLayout {
                    spacing: 8
                    
                    Button {
                        width: 32
                        height: 32
                        flat: true
                        visible: model.status === "错误"
                        
                        background: Rectangle {
                            color: parent.hovered ? "#EFF6FF" : "transparent"
                            radius: 16
                        }
                        
                        contentItem: Text {
                            text: "↻"
                            font.pixelSize: 14
                            color: "#3B82F6"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        onClicked: historyView.retryDownload(model)
                        
                        ToolTip.visible: hovered
                        ToolTip.text: "重新下载"
                    }
                    
                    Button {
                        width: 32
                        height: 32
                        flat: true
                        
                        background: Rectangle {
                            color: parent.hovered ? "#FEE2E2" : "transparent"
                            radius: 16
                        }
                        
                        contentItem: Text {
                            text: "🗑"
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        onClicked: historyView.removeFromHistory(model.jobId)
                        
                        ToolTip.visible: hovered
                        ToolTip.text: "从历史记录中删除"
                    }
                }
            }
        }
        
        // 空状态
        Label {
            anchors.centerIn: parent
            text: "暂无历史记录"
            color: "#9CA3AF"
            font.pixelSize: 16
            visible: listView.count === 0
        }
    }
    
    function formatCompletedTime(timestamp) {
        if (!timestamp) return ""
        
        const time = new Date(timestamp)
        return time.toLocaleString()
    }
}
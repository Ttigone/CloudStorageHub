import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../Component"

ScrollView {
    id: transferHistoryView
    clip: true

    property var model: null
    property string transferType: "download" // "upload" | "download"
    property color accentColor: "#27AE60"

    signal transferRetried(string jobId)
    signal historyItemRemoved(string jobId)
    signal fileLocationOpened(string localPath)

    ListView {
        id: listView
        model: transferHistoryView.model
        spacing: 8

        delegate: Rectangle {
            width: listView.width
            height: 80
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
                    width: 48
                    height: 48
                    radius: 8
                    color: getFileTypeColor(model.name || model.fileName || "")

                    Text {
                        anchors.centerIn: parent
                        text: getFileTypeIcon(model.name
                                              || model.fileName || "")
                        font.pixelSize: 20
                        color: "#FFFFFF"
                    }

                    // 状态指示器
                    Rectangle {
                        visible: model.status === "已完成"
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -3
                        anchors.rightMargin: -3
                        width: 16
                        height: 16
                        radius: 8
                        color: "#10B981"
                        border.color: "#FFFFFF"
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: "✓"
                            font.pixelSize: 8
                            font.bold: true
                            color: "white"
                        }
                    }

                    Rectangle {
                        visible: model.status === "错误" || model.status === "失败"
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -3
                        anchors.rightMargin: -3
                        width: 16
                        height: 16
                        radius: 8
                        color: "#EF4444"
                        border.color: "#FFFFFF"
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: 8
                            font.bold: true
                            color: "white"
                        }
                    }
                }

                // 文件信息
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: model.name || model.fileName || "未知文件"
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: "#1F2937"
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        Text {
                            text: formatFileSize(model.size)
                            font.pixelSize: 12
                            color: "#6B7280"
                        }

                        Text {
                            text: model.status || "未知"
                            font.pixelSize: 12
                            color: getStatusColor(model.status).text
                            font.weight: Font.Medium
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            text: formatCompletedTime(model.completedTime
                                                      || model.endTime)
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
                        visible: transferHistoryView.transferType === "download"
                                 && model.status === "已完成"

                        background: Rectangle {
                            radius: 16
                            color: parent.pressed ? "#DBEAFE" : "#EFF6FF"
                            border.color: "#3B82F6"
                            border.width: 1
                        }

                        contentItem: Text {
                            text: "📁"
                            font.pixelSize: 14
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            // 打开的文件不存在时, 显示对话框, 是否删除当前记录
                            console.log("打开文件位置: " + model.localPath)
                            fileLocationOpened(model.localPath)
                        }
                        TtToolTip {
                            text: "打开文件位置"
                            arrowPosition: "auto"
                        }
                    }

                    Button {
                        width: 32
                        height: 32
                        visible: model.status === "错误" || model.status === "失败"

                        background: Rectangle {
                            radius: 16
                            color: parent.pressed ? "#DCFCE7" : "#F0FDF4"
                            border.color: "#22C55E"
                            border.width: 1
                        }

                        contentItem: Text {
                            text: "↻"
                            font.pixelSize: 14
                            color: "#16A34A"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            transferRetried(model.jobId)
                        }

                        TtToolTip {
                            text: "重新" + (transferHistoryView.transferType
                                          === "upload" ? "上传" : "下载")
                        }
                    }

                    Button {
                        width: 32
                        height: 32

                        background: Rectangle {
                            radius: 16
                            color: parent.pressed ? "#FEE2E2" : "#FFF1F1"
                            border.color: "#EF4444"
                            border.width: 1
                        }

                        contentItem: Text {
                            text: "🗑"
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            historyItemRemoved(model.jobId)
                        }

                        TtToolTip {
                            text: "从历史记录中删除"
                        }
                    }
                }
            }
        }

        // 空状态
        Label {
            anchors.centerIn: parent
            text: "暂无" + (transferHistoryView.transferType === "upload" ? "上传" : "下载") + "历史记录"
            color: "#9CA3AF"
            font.pixelSize: 16
            visible: listView.count === 0
        }
    }

    // 工具函数
    function formatFileSize(bytes) {
        if (!bytes || bytes === "未知大小")
            return "未知大小"

        const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
        if (bytes === 0)
            return '0 B'

        const i = Math.floor(Math.log(bytes) / Math.log(1024))
        return Math.round(bytes / Math.pow(1024,
                                           i) * 100) / 100 + ' ' + sizes[i]
    }

    function formatCompletedTime(timestamp) {
        if (!timestamp)
            return ""

        const time = new Date(timestamp)
        const now = new Date()
        const diffDays = Math.floor((now - time) / (1000 * 60 * 60 * 24))

        if (diffDays === 0) {
            return "今天 " + time.toLocaleTimeString().substring(0, 5)
        } else if (diffDays === 1) {
            return "昨天 " + time.toLocaleTimeString().substring(0, 5)
        } else if (diffDays < 7) {
            return diffDays + "天前"
        } else {
            return time.toLocaleDateString()
        }
    }

    function getFileTypeColor(fileName) {
        const ext = fileName.split('.').pop().toLowerCase()
        switch (ext) {
        case 'jpg':
        case 'jpeg':
        case 'png':
        case 'gif':
        case 'bmp':
            return "#E74C3C"
        case 'pdf':
            return "#E74C3C"
        case 'doc':
        case 'docx':
            return "#3498DB"
        case 'xls':
        case 'xlsx':
            return "#27AE60"
        case 'ppt':
        case 'pptx':
            return "#F39C12"
        case 'zip':
        case 'rar':
        case '7z':
            return "#9B59B6"
        case 'mp3':
        case 'wav':
        case 'mp4':
        case 'avi':
            return "#1ABC9C"
        default:
            return "#95A5A6"
        }
    }

    function getFileTypeIcon(fileName) {
        const ext = fileName.split('.').pop().toLowerCase()
        switch (ext) {
        case 'jpg':
        case 'jpeg':
        case 'png':
        case 'gif':
        case 'bmp':
            return "🖼"
        case 'pdf':
            return "📄"
        case 'doc':
        case 'docx':
            return "📝"
        case 'xls':
        case 'xlsx':
            return "📊"
        case 'ppt':
        case 'pptx':
            return "📊"
        case 'zip':
        case 'rar':
        case '7z':
            return "📦"
        case 'mp3':
        case 'wav':
            return "🎵"
        case 'mp4':
        case 'avi':
            return "🎬"
        default:
            return "📄"
        }
    }

    function getStatusColor(status) {
        switch (status) {
        case "已完成":
            return {
                "text": "#059669"
            }
        case "错误":
        case "失败":
            return {
                "text": "#DC2626"
            }
        case "取消":
            return {
                "text": "#D97706"
            }
        default:
            return {
                "text": "#6B7280"
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import QtQuick.Dialogs

import "./Component"
import QWindowKit

Window {
    id: downloadWindow
    title: "下载管理器"
    width: 600
    height: 500
    // color: darkStyle.windowBackgroundColor
    minimumWidth: 480
    minimumHeight: 340
    property var downloadModel: null
    property var historyModel: null
    property int currentTab: 0

    FileDialog {
        id: fileLocationDialog
        title: "选择文件位置"
        fileMode: FileDialog.OpenFile
        onAccepted: {
            console.log("选择的文件:", selectedFile)
            Qt.openUrlExternally(selectedFile)
        }
        onRejected: {
            console.log("取消选择文件")
        }
    }
    function getFileTypeColor(fileName) {
        const ext = fileName ? fileName.split('.').pop().toLowerCase() : ''

        switch (ext) {
        case 'jpg':
        case 'jpeg':
        case 'png':
        case 'gif':
        case 'bmp':
        case 'webp':
            return {
                "light": "#60A5FA",
                "dark": "#2563EB"
            } // 蓝色
        case 'mp4':
        case 'avi':
        case 'mov':
        case 'wmv':
        case 'flv':
        case 'mkv':
            return {
                "light": "#F472B6",
                "dark": "#DB2777"
            } // 粉色
        case 'mp3':
        case 'wav':
        case 'flac':
        case 'm4a':
        case 'aac':
            return {
                "light": "#818CF8",
                "dark": "#4F46E5"
            } // 紫色
        case 'pdf':
            return {
                "light": "#F87171",
                "dark": "#DC2626"
            } // 红色
        case 'doc':
        case 'docx':
        case 'txt':
        case 'rtf':
            return {
                "light": "#34D399",
                "dark": "#059669"
            } // 绿色
        case 'xls':
        case 'xlsx':
        case 'csv':
            return {
                "light": "#A3E635",
                "dark": "#65A30D"
            } // 黄绿色
        case 'zip':
        case 'rar':
        case '7z':
        case 'tar':
        case 'gz':
            return {
                "light": "#FBBF24",
                "dark": "#D97706"
            } // 橙黄色
        default:
            return {
                "light": "#9CA3AF",
                "dark": "#4B5563"
            } // 灰色
        }
    }
    function formatISODateTime(timestamp) {
        if (!timestamp)
            return "未知时间"

        const date = new Date(timestamp)
        const now = new Date()
        const diffMs = now.getTime() - date.getTime()
        const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24))

        // 格式化为ISO标准时间格式
        const year = date.getFullYear()
        const month = String(date.getMonth() + 1).padStart(2, '0')
        const day = String(date.getDate()).padStart(2, '0')
        const hours = String(date.getHours()).padStart(2, '0')
        const minutes = String(date.getMinutes()).padStart(2, '0')
        const seconds = String(date.getSeconds()).padStart(2, '0')

        if (diffDays === 0) {
            // 今天：显示"今天 HH:mm:ss"
            return `今天 ${hours}:${minutes}:${seconds}`
        } else if (diffDays === 1) {
            // 昨天：显示"昨天 HH:mm:ss"
            return `昨天 ${hours}:${minutes}:${seconds}`
        } else if (diffDays < 7) {
            // 一周内：显示"N天前 HH:mm:ss"
            return `${diffDays}天前 ${hours}:${minutes}:${seconds}`
        } else {
            // 超过一周：显示完整ISO格式"YYYY-MM-DD HH:mm:ss"
            return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`
        }
    }

    // 简化时间显示的调用
    function getFormattedCompletedTime(completedTime) {
        return formatISODateTime(completedTime)
    }
    function openFileLocation(localPath, fileName) {
        console.log("打开文件位置:", localPath, fileName)

        if (!localPath || localPath === "") {
            showMessage("文件路径不存在: " + fileName)
            fileLocationDialog.currentFolder = "file:///C:/" // 设置默认目录
            fileLocationDialog.open()
            return
        }

        // 检查文件是否存在
        if (ManagerGlobal && ManagerGlobal.fileExists) {
            if (!ManagerGlobal.fileExists(localPath)) {
                showMessage("文件不存在: " + fileName)
                // 打开文件所在目录
                var folderPath = localPath.substring(0,
                                                     localPath.lastIndexOf('/'))
                if (folderPath) {
                    Qt.openUrlExternally("file:///" + folderPath.replace(/\\/g,
                                                                         '/'))
                    showMessage("已打开文件夹: " + folderPath)
                }
                return
            }
        }

        // 调用后端方法打开文件位置
        if (ManagerGlobal && ManagerGlobal.openFileLocation) {
            ManagerGlobal.openFileLocation(localPath)
            showMessage("已打开文件位置: " + fileName)
        } else {
            // 备用方案：尝试使用Qt.openUrlExternally
            var folderPath = localPath.substring(0, localPath.lastIndexOf('/'))
            if (folderPath) {
                Qt.openUrlExternally("file:///" + folderPath)
                showMessage("已打开文件夹: " + folderPath)
            } else {
                console.warn("openFileLocation 方法不可用")
                showMessage("无法打开文件位置")
            }
        }
    }

    // 改进showMessage函数，添加临时消息显示
    function showMessage(message) {
        console.log("消息:", message)

        // 在状态栏显示临时消息
        if (statusMessage) {
            statusMessage.text = message
            statusMessage.visible = true
            statusMessageTimer.restart()
        }
    }

    // 根据文件类型获取图标
    function getFileTypeIcon(fileName) {
        const ext = fileName ? fileName.split('.').pop().toLowerCase() : ''

        switch (ext) {
        case 'jpg':
        case 'jpeg':
        case 'png':
        case 'gif':
        case 'bmp':
        case 'webp':
            return "🖼️"
        case 'mp4':
        case 'avi':
        case 'mov':
        case 'wmv':
        case 'flv':
        case 'mkv':
            return "🎬"
        case 'mp3':
        case 'wav':
        case 'flac':
        case 'm4a':
        case 'aac':
            return "🎵"
        case 'pdf':
            return "📕"
        case 'doc':
        case 'docx':
        case 'txt':
        case 'rtf':
            return "📝"
        case 'xls':
        case 'xlsx':
        case 'csv':
            return "📊"
        case 'zip':
        case 'rar':
        case '7z':
        case 'tar':
        case 'gz':
            return "📦"
        default:
            return "📄"
        }
    }

    // 获取状态颜色
    function getStatusColor(status) {
        switch (status) {
        case "已完成":
        case "完成":
            return {
                "background": "#DCFCE7",
                "border": "#BBF7D0",
                "text": "#059669"
            }
        case "下载中":
        case "连接中...":
        case "准备下载":
            return {
                "background": "#DBEAFE",
                "border": "#BFDBFE",
                "text": "#1D4ED8"
            }
        case "暂停":
            return {
                "background": "#FEF3C7",
                "border": "#FDE68A",
                "text": "#D97706"
            }
        case "错误":
        case "超时":
            return {
                "background": "#FEE2E2",
                "border": "#FECACA",
                "text": "#DC2626"
            }
        default:
            return {
                "background": "#F3F4F6",
                "border": "#E5E7EB",
                "text": "#6B7280"
            }
        }
    }

    // 格式化文件大小
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

    // 获取下载时间信息
    function getDownloadTimeInfo(startTime, progress) {
        if (!startTime)
            return ""

        const now = new Date().getTime()
        const elapsed = Math.floor((now - startTime) / 1000)

        if (progress >= 1) {
            return "已完成"
        } else if (progress > 0) {
            const estimated = Math.floor(elapsed / progress) - elapsed
            if (estimated > 60) {
                return `剩余 ${Math.floor(estimated / 60)}分钟`
            } else {
                return `剩余 ${estimated}秒`
            }
        } else {
            return `已用时 ${elapsed}秒`
        }
    }
    // 删除正在下载的项目
    function removeDownloadItem(index, jobId, fileName) {
        console.log("开始删除下载项目:", index, jobId, fileName)
        if (!downloadModel) {
            console.warn("downloadModel 不存在")
            return
        }
        // 检查索引有效性
        if (index < 0 || index >= downloadModel.count) {
            console.warn("索引超出范围:", index, "总数:", downloadModel.count)
            return
        }
        const item = downloadModel.get(index)
        if (!item) {
            console.warn("无法获取项目:", index)
            return
        }
        const progress = item.progress || 0
        const status = item.status || ""

        // 如果正在下载，先取消下载
        if (progress < 1.0 && status !== "错误" && status !== "已完成") {
            console.log("取消正在进行的下载:", jobId)
            // 调用后端取消下载
            if (ManagerGlobal && ManagerGlobal.cancelDownload) {
                ManagerGlobal.cancelDownload(jobId)
            } else {
                console.warn("ManagerGlobal.cancelDownload 不可用")
            }
        }

        // 如果是已完成的下载，移到历史记录
        if (progress >= 1.0 && historyModel) {
            console.log("将已完成项目移到历史记录:", fileName)
            if (!historyModel) {
                historyModel = Qt.createQmlObject(
                            'import QtQuick; ListModel {}', downloadWindow)
            }
            // 这里会将其加入到的历史模型
            historyModel.append({
                                    "name": item.name,
                                    "size": item.size,
                                    "progress": item.progress,
                                    "jobId": item.jobId,
                                    "status": "已完成",
                                    "speed": item.speed || "0 KB/s",
                                    "startTime": item.startTime,
                                    "lastUpdateTime": item.lastUpdateTime,
                                    "completedTime": new Date().getTime(),
                                    "bucketName": item.bucketName,
                                    "key": item.key,
                                    "localPath"// "localPath": item.localPath || "" // 添加本地路径
                                    : ManagerGlobal.getDownloadFullPath(
                                          item.jobId) || item.localPath
                                      || "" // 获取完整路径
                                })
        }

        // 从下载模型中移除
        try {
            downloadModel.remove(index)
            console.log("成功从下载列表移除:", fileName)
            showMessage("已删除: " + fileName)
        } catch (error) {
            console.error("删除项目时出错:", error)
        }
    }
    // 点击删除历史记录项目
    function removeHistoryItem(index, jobId, fileName) {
        console.log("开始删除历史记录:", index, jobId, fileName)

        if (!historyModel) {
            console.warn("historyModel 不存在")
            return
        }

        // 检查索引有效性
        if (index < 0 || index >= historyModel.count) {
            console.warn("历史记录索引超出范围:", index, "总数:", historyModel.count)
            return
        }

        const item = historyModel.get(index)
        if (!item) {
            console.warn("无法获取历史记录项目:", index)
            return
        }

        // 从历史记录模型中移除
        try {
            historyModel.remove(index)
            console.log("成功从历史记录移除:", fileName)

            // 如果有本地文件，询问是否删除（可选功能）
            // askDeleteLocalFile(fileName, item.localPath)

            // 显示成功消息
            showMessage("已删除历史记录: " + fileName)
        } catch (error) {
            console.error("删除历史记录时出错:", error)
        }
    }

    // 批量删除已完成的下载（优化现有函数）
    function clearCompletedDownloads() {
        if (!downloadModel) {
            console.warn("downloadModel 不存在")
            return
        }

        let clearedCount = 0

        // 从后往前遍历避免索引问题
        for (var i = downloadModel.count - 1; i >= 0; i--) {
            const item = downloadModel.get(i)
            if (item && (item.progress >= 1.0 || item.status === "已完成")) {

                // 移到历史记录
                if (historyModel) {
                    historyModel.append({
                                            "name": item.name,
                                            "size": item.size,
                                            "progress": item.progress,
                                            "jobId": item.jobId,
                                            "status": "已完成",
                                            "speed": item.speed || "0 KB/s",
                                            "startTime": item.startTime,
                                            "lastUpdateTime": item.lastUpdateTime,
                                            "completedTime": new Date().getTime(
                                                                 ),
                                            "bucketName": item.bucketName,
                                            "key": item.key
                                        })
                }
                // 从下载列表移除
                downloadModel.remove(i)
                clearedCount++
            }
        }

        console.log("清理完成，移除了", clearedCount, "个已完成的下载")

        if (clearedCount > 0) {
            showMessage(`已清理 ${clearedCount} 个已完成的下载`)
        } else {
            showMessage("没有已完成的下载需要清理")
        }
    }

    // 询问删除本地文件
    function askDeleteLocalFile(fileName, localPath) {
        // 这里可以添加确认对话框
        console.log("询问是否删除本地文件:", fileName, localPath)
        // 例如：deleteFileDialog.show(fileName, localPath)
    }
    Component.onCompleted: {
        windowAgent.setup(downloadWindow)
        windowAgent.setWindowAttribute("dark-mode", true)
        // 确保历史记录模型存在
        if (!historyModel) {
            historyModel = Qt.createQmlObject('import QtQuick; ListModel {}',
                                              downloadWindow)
            console.log("初始化历史记录模型")
        }
    }
    WindowAgent {
        id: windowAgent
    }
    Item {
        anchors.fill: parent
        // TitleBar 区域
        Rectangle {
            id: titleBar
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: 48 // 高度没有填充满
            radius: 12
            color: "#FFFFFF"
            z: 100
            Component.onCompleted: {
                windowAgent.setTitleBar(titleBar)
            }
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: "#FAFBFC"
                }
                GradientStop {
                    position: 1.0
                    color: "#F8FAFC"
                }
            }
            // 简化的拖动指示条
            Rectangle {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 6
                width: 48
                height: 4
                radius: 2
                color: "#3B82F6"
                opacity: 0.8
            }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 20
                spacing: 16
                // 应用图标 - 固定宽度
                Rectangle {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    radius: 6

                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: "#4F46E5"
                        }
                        GradientStop {
                            position: 1.0
                            color: "#3B82F6"
                        }
                    }

                    Item {
                        anchors.centerIn: parent
                        width: 28
                        height: 28

                        Text {
                            anchors.centerIn: parent
                            text: "⬇"
                            font.pixelSize: 20
                            font.weight: Font.Medium
                            color: "white"
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        border.color: "#331122"
                        border.width: 1
                        opacity: 0.2
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
                // 操作按钮组
                RowLayout {
                    Layout.preferredWidth: 240
                    spacing: 8
                    // 关键修复：禁用父级的标题栏拖动事件
                    Rectangle {
                        width: 1
                        height: 24
                        color: "#E2E8F0"
                    }
                    Button {
                        id: clearButton
                        text: "清空完成"
                        flat: true
                        background: Rectangle {
                            radius: 8
                            color: parent.hovered ? "#FEF3C7" : "transparent"
                            border.color: parent.hovered ? "#FCD34D" : "transparent"
                            border.width: 1
                        }
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: "#475569"
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Component.onCompleted: {
                            // 允许点击
                            windowAgent.setHitTestVisible(clearButton, true)
                        }

                        onClicked: downloadWindow.clearCompletedDownloads()
                    }

                    Button {
                        id: pauseAllButton
                        text: "全部暂停"
                        flat: true

                        background: Rectangle {
                            radius: 8
                            color: parent.hovered ? "#FEF3C7" : "transparent"
                            border.color: parent.hovered ? "#FCD34D" : "transparent"
                            border.width: 1
                        }

                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: "#92400E"
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Component.onCompleted: {
                            // 允许点击
                            windowAgent.setHitTestVisible(pauseAllButton, true)
                        }
                        onClicked: {
                            console.log("test pause")
                            downloadWindow.pauseAllDownloads()
                        }
                    }

                    Button {
                        id: settingButton
                        width: 40
                        height: 40
                        flat: true

                        background: Rectangle {
                            radius: 8
                            color: parent.hovered ? "#F1F5F9" : "transparent"
                            border.color: parent.hovered ? "#CBD5E1" : "transparent"
                            border.width: 1
                        }

                        contentItem: Text {
                            text: "⚙"
                            font.pixelSize: 16
                            color: "#64748B"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        Component.onCompleted: {
                            // 允许点击
                            windowAgent.setHitTestVisible(settingButton, true)
                        }

                        onClicked: settingsMenu.popup()

                        // Menu {
                        TtMenu {
                            id: settingsMenu

                            MenuItem {
                                text: "下载设置"
                                onTriggered: console.log("下载设置")
                            }
                            MenuItem {
                                text: "清理设置"
                                onTriggered: console.log("清理设置")
                            }
                            MenuSeparator {}
                            MenuItem {
                                text: "关于"
                                onTriggered: console.log("关于")
                            }
                        }
                    }
                    RowLayout {
                        Layout.preferredWidth: 46
                        spacing: 8
                        Button {
                            id: closeButton
                            Layout.preferredWidth: 46
                            Layout.preferredHeight: 32
                            flat: true

                            background: Rectangle {
                                color: {
                                    if (!closeButton.enabled) {
                                        return "#CCCCCC"
                                    }
                                    if (closeButton.pressed) {
                                        return "#DC143C"
                                    }
                                    if (closeButton.hovered) {
                                        return "#E81123"
                                    }
                                    return "transparent"
                                }
                                radius: 4
                                border.color: closeButton.hovered ? "#DC2626" : "#E2E8F0"
                                border.width: closeButton.hovered ? 1 : 0
                            }

                            // 使用文字图标代替SVG图片
                            contentItem: Text {
                                text: "×" // 关闭符号
                                font.pixelSize: 18
                                font.weight: Font.Bold
                                color: closeButton.hovered ? "white" : "#475569"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: {
                                console.log("关闭按钮被点击")
                                downloadWindow.close()
                            }

                            Component.onCompleted: windowAgent.setSystemButton(
                                                       WindowAgent.Close,
                                                       closeButton)
                        }
                    }
                }
            }
        }
        // 分隔线
        Rectangle {
            id: separator
            anchors {
                top: titleBar.bottom
                left: parent.left
                right: parent.right
            }
            Layout.fillWidth: true
            height: 1
            color: "#F1F5F9"
        }
        // 内容区域 - 注意它从标题栏下方开始
        // 标签页导航
        Rectangle {
            id: tabNavigation
            anchors {
                top: separator.bottom
                left: parent.left
                right: parent.right
            }
            height: 42
            color: "#FAFBFC"
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 4

                // 正在下载标签
                Rectangle {
                    Layout.preferredWidth: 160
                    Layout.fillHeight: true
                    radius: 8
                    color: downloadWindow.currentTab === 0 ? "#FFFFFF" : "transparent"

                    layer.enabled: downloadWindow.currentTab === 0
                    layer.effect: DropShadow {
                        radius: 4
                        samples: 8
                        color: "#10000000"
                        verticalOffset: 2
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            console.log("切换到正在下载标签")
                            downloadWindow.currentTab = 0
                        }
                        cursorShape: Qt.PointingHandCursor
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 12

                        Text {
                            text: "⬇"
                            font.pixelSize: 18
                            color: downloadWindow.currentTab === 0 ? "#3B82F6" : "#64748B"
                        }

                        Text {
                            text: "正在下载"
                            font.pixelSize: 15
                            font.weight: downloadWindow.currentTab
                                         === 0 ? Font.DemiBold : Font.Medium
                            color: downloadWindow.currentTab === 0 ? "#1E293B" : "#64748B"
                        }

                        Rectangle {
                            width: 24
                            height: 18
                            radius: 9
                            color: "#EF4444"
                            visible: getActiveDownloadCount() > 0

                            Text {
                                anchors.centerIn: parent
                                text: getActiveDownloadCount()
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                color: "white"
                            }
                        }
                    }
                }

                // 历史记录 标签
                Rectangle {
                    Layout.preferredWidth: 160
                    Layout.fillHeight: true
                    radius: 8
                    color: downloadWindow.currentTab === 1 ? "#FFFFFF" : "transparent"

                    layer.enabled: downloadWindow.currentTab === 1
                    layer.effect: DropShadow {
                        radius: 4
                        samples: 8
                        color: "#10000000"
                        verticalOffset: 2
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: downloadWindow.currentTab = 1
                        cursorShape: Qt.PointingHandCursor
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 12

                        Text {
                            text: "📋"
                            font.pixelSize: 18
                            color: downloadWindow.currentTab === 1 ? "#3B82F6" : "#64748B"
                        }

                        Text {
                            text: "历史记录"
                            font.pixelSize: 15
                            font.weight: downloadWindow.currentTab
                                         === 1 ? Font.DemiBold : Font.Medium
                            color: downloadWindow.currentTab === 1 ? "#1E293B" : "#64748B"
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                // 搜索框
                Rectangle {
                    Layout.preferredWidth: 200
                    height: 36
                    radius: 18
                    color: "#FFFFFF"
                    border.color: searchField.activeFocus ? "#3B82F6" : "#E2E8F0"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Text {
                            text: "🔍"
                            font.pixelSize: 14
                            color: "#94A3B8"
                        }

                        TextField {
                            id: searchField
                            Layout.fillWidth: true
                            placeholderText: "搜索下载任务..."
                            font.pixelSize: 13
                            color: "#1E293B"
                            background: Rectangle {
                                color: "transparent"
                            }
                            selectByMouse: true
                        }
                    }
                }
            }
        }

        // 内容区域 - 保持不变
        StackLayout {
            anchors {
                top: tabNavigation.bottom
                left: parent.left
                right: parent.right
                bottom: statusBar.top
            }
            currentIndex: downloadWindow.currentTab

            // 正在下载页面
            Rectangle {
                color: "#F8FAFC"

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 16
                    clip: true

                    ListView {
                        id: downloadListView
                        model: downloadWindow.downloadModel
                        spacing: 16
                        topMargin: 8
                        bottomMargin: 8
                        leftMargin: 4
                        rightMargin: 4
                        boundsBehavior: Flickable.DragAndOvershootBounds
                        delegate: Rectangle {
                            width: downloadListView.width - 8 // 减去左右边距，避免超出
                            height: 72
                            radius: 12
                            color: downloadDelegateMouseArea.containsMouse ? "#FFFFFF" : "#FEFEFE"
                            border.color: downloadDelegateMouseArea.containsMouse ? "#3B82F6" : "#E2E8F0"
                            border.width: downloadDelegateMouseArea.containsMouse ? 2 : 1

                            // 添加渐变背景
                            gradient: Gradient {
                                GradientStop {
                                    position: 0.0
                                    color: downloadDelegateMouseArea.containsMouse ? "#FEFEFE" : "#FBFCFD"
                                }
                                GradientStop {
                                    position: 1.0
                                    color: downloadDelegateMouseArea.containsMouse ? "#F8FAFC" : "#F1F5F9"
                                }
                            }

                            layer.enabled: downloadDelegateMouseArea.containsMouse
                            layer.effect: DropShadow {
                                radius: 12
                                samples: 24
                                color: "#15000000"
                                verticalOffset: 4
                                horizontalOffset: 0
                            }

                            MouseArea {
                                id: downloadDelegateMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                            }
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12
                                Rectangle {
                                    Layout.preferredWidth: 48
                                    Layout.preferredHeight: 48
                                    radius: 24
                                    // gradient: Gradient {
                                    //     GradientStop {
                                    //         position: 0.0
                                    //         color: getFileTypeColor(
                                    //                    model.name).light
                                    //     }
                                    //     GradientStop {
                                    //         position: 1.0
                                    //         color: getFileTypeColor(
                                    //                    model.name).dark
                                    //     }
                                    // }
                                    // 统一的蓝色渐变，与DownloadPanel一致
                                    gradient: Gradient {
                                        GradientStop {
                                            position: 0.0
                                            color: "#4F46E5"
                                        }
                                        GradientStop {
                                            position: 1.0
                                            color: "#3B82F6"
                                        }
                                    }
                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: 1
                                        radius: parent.radius - 1
                                        color: "transparent"
                                        border.color: "#FFFFFF"
                                        border.width: 2
                                        opacity: 0.8
                                    }
                                    // // 文件类型图标
                                    // Text {
                                    //     anchors.centerIn: parent
                                    //     text: getFileTypeIcon(model.name)
                                    //     font.pixelSize: 20
                                    //     font.weight: Font.Medium
                                    // }
                                    // 内部图标
                                    Item {
                                        anchors.centerIn: parent
                                        width: 28
                                        height: 28

                                        Text {
                                            anchors.centerIn: parent
                                            text: {
                                                if (!model)
                                                    return "⬇"
                                                const progress = model.progress
                                                               || 0
                                                if (progress >= 1.0)
                                                    return "✓" // 完成显示勾
                                                if (model.status === "暂停")
                                                    return "⏸" // 暂停显示暂停符号
                                                if (model.status === "错误")
                                                    return "✗" // 错误显示叉
                                                return "⬇" // 下载中显示箭头
                                            }
                                            font.pixelSize: 20
                                            font.weight: Font.Medium
                                            color: "white"
                                        }
                                    }

                                    // 圆形进度指示器
                                    Canvas {
                                        id: progressCanvas
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        property real progressValue: model.progress
                                                                     || 0

                                        onProgressValueChanged: requestPaint()

                                        onPaint: {
                                            var ctx = getContext("2d")
                                            ctx.clearRect(0, 0, width, height)

                                            var centerX = width / 2
                                            var centerY = height / 2
                                            var radius = Math.min(
                                                        width, height) / 2 - 2
                                            var progress = progressValue

                                            if (progress > 0 && progress < 1) {
                                                // 绘制进度弧
                                                ctx.beginPath()
                                                ctx.arc(centerX, centerY,
                                                        radius, -Math.PI / 2,
                                                        -Math.PI / 2 + 2 * Math.PI * progress)
                                                ctx.lineWidth = 2
                                                ctx.strokeStyle = "#FFFFFF"
                                                ctx.lineCap = "round"
                                                ctx.stroke()
                                            }
                                        }
                                    }
                                }

                                // 文件信息区域 - 紧凑布局
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 200 // 设置最小宽度避免挤压
                                    spacing: 4

                                    // 文件名行
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            text: model.name || "未知文件"
                                            font.pixelSize: 14
                                            font.weight: Font.DemiBold
                                            color: "#1E293B"
                                            elide: Text.ElideMiddle
                                            Layout.fillWidth: true
                                            Layout.minimumWidth: 100 // 设置最小宽度
                                        }

                                        // 状态标签 - 紧凑设计
                                        Rectangle {
                                            Layout.preferredHeight: 20
                                            Layout.preferredWidth: fileStatusText.implicitWidth + 12
                                            Layout.maximumWidth: 80 // 限制最大宽度
                                            radius: 10
                                            color: getStatusColor(
                                                       model.status).background
                                            border.color: getStatusColor(
                                                              model.status).border
                                            border.width: 1

                                            Text {
                                                // BUG
                                                id: fileStatusText
                                                anchors.centerIn: parent
                                                text: {
                                                    const progress = model.progress
                                                                   || 0
                                                    if (progress >= 1.0)
                                                        return "已完成"
                                                    if (progress > 0)
                                                        return Math.round(
                                                                    progress * 100) + "%"
                                                    return model.status || "准备中"
                                                }
                                                font.pixelSize: 10
                                                font.weight: Font.Bold
                                                color: getStatusColor(
                                                           model.status).text
                                            }
                                        }
                                    }

                                    // 详细信息行 - 简化
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 16

                                        // 文件大小 - 简化图标
                                        Text {
                                            text: "📦 " + formatFileSize(
                                                      model.size)
                                            font.pixelSize: 12
                                            color: "#64748B"
                                            Layout.maximumWidth: 120 // 限制最大宽度
                                            elide: Text.ElideRight
                                        }

                                        // 下载速度
                                        Text {
                                            text: "⚡ " + (model.speed
                                                          || "0 KB/s")
                                            font.pixelSize: 12
                                            color: "#10B981"
                                            visible: (model.progress || 0) > 0
                                                     && (model.progress
                                                         || 0) < 1
                                            Layout.maximumWidth: 100
                                            elide: Text.ElideRight
                                        }

                                        Item {
                                            Layout.fillWidth: true
                                            Layout.minimumWidth: 10 // 最小间隔
                                        }
                                    }
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 6
                                        radius: 3
                                        color: "#F1F5F9"

                                        Rectangle {
                                            id: progressBarRect
                                            width: parent.width * Math.max(
                                                       0, Math.min(
                                                           1,
                                                           model ? (model.progress
                                                                    || 0) : 0))
                                            height: parent.height
                                            radius: parent.radius

                                            // 与DownloadPanel完全一致的颜色逻辑
                                            color: {
                                                if (!model)
                                                    return "#F1F5F9"
                                                const progress = model.progress
                                                               || 0
                                                if (progress >= 1.0)
                                                    return "#10B981" // 完成 - 绿色
                                                if (model.status === "暂停")
                                                    return "#F59E0B" // 暂停 - 橙色
                                                if (model.status === "错误")
                                                    return "#EF4444" // 错误 - 红色
                                                return "#3B82F6" // 下载中 - 蓝色
                                            }

                                            Behavior on width {
                                                NumberAnimation {
                                                    duration: 300
                                                    easing.type: Easing.OutCubic
                                                }
                                            }

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 200
                                                }
                                            }

                                            // 进度条光泽效果
                                            Rectangle {
                                                anchors.fill: parent
                                                radius: parent.radius
                                                gradient: Gradient {
                                                    GradientStop {
                                                        position: 0.0
                                                        color: "#60FFFFFF"
                                                    }
                                                    GradientStop {
                                                        position: 0.5
                                                        color: "#30FFFFFF"
                                                    }
                                                    GradientStop {
                                                        position: 1.0
                                                        color: "#10FFFFFF"
                                                    }
                                                }
                                            }

                                            // 修复后的光效动画
                                            Rectangle {
                                                id: shimmerRect
                                                width: 20
                                                height: parent ? parent.height : 0
                                                radius: parent ? parent.radius : 0

                                                property bool shouldAnimate: {
                                                    if (!model || !parent)
                                                        return false
                                                    const progress = model.progress
                                                                   || 0
                                                    return progress > 0
                                                            && progress < 1
                                                            && model.status !== "暂停"
                                                            && model.status !== "错误"
                                                }

                                                visible: shouldAnimate

                                                gradient: Gradient {
                                                    orientation: Gradient.Horizontal
                                                    GradientStop {
                                                        position: 0.0
                                                        color: "transparent"
                                                    }
                                                    GradientStop {
                                                        position: 0.5
                                                        color: "#60FFFFFF"
                                                    }
                                                    GradientStop {
                                                        position: 1.0
                                                        color: "transparent"
                                                    }
                                                }

                                                SequentialAnimation {
                                                    id: shimmerAnimation
                                                    running: shimmerRect.shouldAnimate
                                                             && progressBarRect
                                                    loops: Animation.Infinite

                                                    NumberAnimation {
                                                        target: shimmerRect
                                                        property: "x"
                                                        from: -20
                                                        to: progressBarRect ? (progressBarRect.width + 20) : 20
                                                        duration: 2000
                                                        easing.type: Easing.InOutQuad
                                                    }

                                                    PauseAnimation {
                                                        duration: 1000
                                                    }
                                                }

                                                Component.onDestruction: {
                                                    if (shimmerAnimation) {
                                                        shimmerAnimation.stop()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                RowLayout {
                                    spacing: 6
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.preferredWidth: 110

                                    // 修复暂停/继续按钮的可见性逻辑
                                    Button {
                                        id: pauseButton
                                        Layout.preferredWidth: 32
                                        Layout.preferredHeight: 32

                                        // 添加空值检查
                                        visible: {
                                            if (!model)
                                                return false // 添加这行
                                            const progress = model.progress || 0
                                            const status = model.status || ""
                                            // 显示条件：进度小于100% 且 不是错误状态
                                            return progress < 1.0
                                                    && status !== "错误"
                                                    && status !== "超时"
                                        }

                                        background: Rectangle {
                                            radius: 16
                                            color: {
                                                if (parent.pressed)
                                                    return "#FDE68A"
                                                if (parent.hovered)
                                                    return "#FEF3C7"
                                                return "#FFFBEB"
                                            }
                                            border.color: "#F59E0B"
                                            border.width: 1
                                        }

                                        contentItem: Text {
                                            text: {
                                                if (!model)
                                                    return "⏸" // 添加空值检查
                                                const status = model.status
                                                             || ""
                                                return status === "暂停" ? "▶" : "⏸"
                                            }
                                            font.pixelSize: 14
                                            font.weight: Font.Bold
                                            color: "#92400E"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        onClicked: {
                                            if (!model)
                                                return
                                            // 添加空值检查
                                            const status = model.status || ""
                                            const jobId = model.jobId || ""

                                            console.log("暂停/继续按钮点击:",
                                                        status, jobId)

                                            if (status === "暂停") {
                                                if (downloadWindow.resumeDownload) {
                                                    downloadWindow.resumeDownload(
                                                                jobId)
                                                } else {
                                                    console.warn("resumeDownload 方法不存在")
                                                }
                                            } else {
                                                if (downloadWindow.pauseDownload) {
                                                    downloadWindow.pauseDownload(
                                                                jobId)
                                                } else {
                                                    console.warn("pauseDownload 方法不存在")
                                                }
                                            }
                                        }

                                        ToolTip.visible: hovered
                                        ToolTip.text: {
                                            if (!model)
                                                return "" // 添加空值检查
                                            const status = model.status || ""
                                            return status === "暂停" ? "继续下载" : "暂停下载"
                                        }
                                        ToolTip.delay: 500
                                    }

                                    // 修复重试按钮的可见性逻辑
                                    Button {
                                        id: retryButton
                                        Layout.preferredWidth: 32
                                        Layout.preferredHeight: 32

                                        // 添加空值检查
                                        visible: {
                                            if (!model)
                                                return false // 添加这行
                                            const status = model.status || ""
                                            const needsRetry = model.needsRetry === true
                                            return needsRetry || status === "超时"
                                                    || status === "错误"
                                                    || status === "失败"
                                        }

                                        background: Rectangle {
                                            radius: 16
                                            color: {
                                                if (parent.pressed)
                                                    return "#BFDBFE"
                                                if (parent.hovered)
                                                    return "#DBEAFE"
                                                return "#EFF6FF"
                                            }
                                            border.color: "#3B82F6"
                                            border.width: 1
                                        }

                                        contentItem: Text {
                                            text: "↻"
                                            font.pixelSize: 16
                                            font.weight: Font.Bold
                                            color: "#1D4ED8"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        onClicked: {
                                            if (!model)
                                                return
                                            // 添加空值检查
                                            const jobId = model.jobId || ""
                                            console.log("重试按钮点击:", jobId)

                                            if (downloadWindow.retryDownload) {
                                                downloadWindow.retryDownload(
                                                            jobId)
                                            } else {
                                                console.warn("retryDownload 方法不存在")
                                            }
                                        }

                                        ToolTip.visible: hovered
                                        ToolTip.text: "重试下载"
                                        ToolTip.delay: 500
                                    }
                                    Button {
                                        // id: deleteButton
                                        Layout.preferredWidth: 32
                                        Layout.preferredHeight: 32
                                        visible: true

                                        background: Rectangle {
                                            radius: 16
                                            color: {
                                                if (parent.pressed)
                                                    return "#FCA5A5" // 更深的红色
                                                if (parent.hovered)
                                                    return "#FEE2E2" // 浅红色悬停
                                                return "#FEF2F2" // 默认非常浅的红色
                                            }
                                            border.color: {
                                                if (parent.pressed)
                                                    return "#DC2626"
                                                if (parent.hovered)
                                                    return "#EF4444"
                                                return "#F87171" // 默认边框颜色
                                            }
                                            border.width: 1

                                            // 添加内部高光效果
                                            Rectangle {
                                                anchors.fill: parent
                                                anchors.margins: 1
                                                radius: parent.radius - 1
                                                color: "transparent"
                                                border.color: "#FFFFFF"
                                                border.width: parent.parent.hovered ? 1 : 0
                                                opacity: 0.3
                                            }
                                        }

                                        contentItem: Text {
                                            text: "🗑️" // 使用垃圾桶Unicode图标
                                            font.pixelSize: 16
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter

                                            // 添加悬停时的动画效果
                                            scale: parent.hovered ? 1.1 : 1.0
                                            Behavior on scale {
                                                NumberAnimation {
                                                    duration: 150
                                                    easing.type: Easing.OutQuad
                                                }
                                            }
                                        }

                                        onClicked: {
                                            if (!model)
                                                return

                                            const jobId = model.jobId || ""
                                            const fileName = model.name
                                                           || "未知文件"

                                            console.log("删除按钮点击:",
                                                        jobId, fileName)

                                            // 调用删除函数
                                            downloadWindow.removeDownloadItem(
                                                        index, jobId, fileName)
                                        }

                                        ToolTip.visible: hovered
                                        ToolTip.text: {
                                            if (!model)
                                                return "删除"
                                            const progress = model.progress || 0
                                            return progress >= 1.0 ? "删除记录" : "取消下载"
                                        }
                                        ToolTip.delay: 500

                                        // 悬停时的微妙旋转效果
                                        rotation: hovered ? 5 : 0
                                        Behavior on rotation {
                                            NumberAnimation {
                                                duration: 200
                                                easing.type: Easing.OutBack
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            anchors.centerIn: parent
                            visible: downloadListView.count === 0

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 16

                                Rectangle {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 80
                                    height: 80
                                    radius: 40
                                    color: "#F1F5F9"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "📥"
                                        font.pixelSize: 32
                                    }
                                }

                                Text {
                                    text: "暂无正在下载的任务"
                                    color: "#64748B"
                                    font.pixelSize: 18
                                    font.weight: Font.Medium
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                Text {
                                    text: "开始下载文件后，任务将在这里显示"
                                    color: "#94A3B8"
                                    font.pixelSize: 14
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }
                    }
                }
            }
            // 历史记录页面
            Rectangle {
                color: "#F8FAFC"

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 16
                    clip: true
                    ListView {
                        id: historyListView
                        model: downloadWindow.historyModel
                        spacing: 8
                        delegate: Rectangle {
                            id: historyItem
                            width: historyListView.width - 8
                            height: 50
                            radius: 6

                            property bool isHovered: historyMouseArea.containsMouse
                                                     || openButton.hovered
                                                     || deleteButton.hovered
                            color: isHovered ? "#F8FAFC" : "#FFFFFF"
                            border.color: isHovered ? "#CBD5E1" : "#E5E7EB"
                            border.width: 1
                            // 悬停效果
                            MouseArea {
                                id: historyMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton

                                // 关键修复：确保鼠标事件不被拦截，可以传递给子项
                                propagateComposedEvents: true
                            }

                            // 主内容
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 10
                                // 图标
                                Rectangle {
                                    id: fileIconRect
                                    width: 32
                                    height: 32
                                    radius: 6

                                    // 使用更美观的渐变色
                                    gradient: Gradient {
                                        GradientStop {
                                            position: 0.0
                                            color: {
                                                // 使用相同的getFileTypeColor函数保持一致性
                                                const colors = getFileTypeColor(
                                                                 model.name)
                                                return colors.light || "#F3F4F6"
                                            }
                                        }
                                        GradientStop {
                                            position: 1.0
                                            color: {
                                                const colors = getFileTypeColor(
                                                                 model.name)
                                                return colors.dark || "#6B7280"
                                            }
                                        }
                                    }

                                    // 添加微妙的内部高光效果
                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: 1
                                        radius: parent.radius - 1
                                        color: "transparent"
                                        border.color: "#FFFFFF"
                                        border.width: 1
                                        opacity: 0.4
                                    }

                                    // 文件类型图标
                                    Text {
                                        id: fileTypeIcon
                                        anchors.centerIn: parent
                                        text: getFileTypeIcon(model.name)
                                        font.pixelSize: 16
                                        color: "#FFFFFF"

                                        // 添加文本阴影使图标更清晰
                                        layer.enabled: true
                                        layer.effect: DropShadow {
                                            horizontalOffset: 0
                                            verticalOffset: 1
                                            radius: 1
                                            samples: 3
                                            color: "#40000000"
                                        }
                                    }

                                    // 完成状态指示器
                                    Rectangle {
                                        visible: model
                                                 && (model.progress >= 1.0
                                                     || model.status === "已完成")
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: -2
                                        anchors.rightMargin: -2
                                        width: 12
                                        height: 12
                                        radius: 6
                                        color: "#10B981"
                                        border.color: "#FFFFFF"
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: "✓"
                                            font.pixelSize: 8
                                            font.weight: Font.Bold
                                            color: "white"
                                        }
                                    }

                                    // 可选：添加悬停效果
                                    states: [
                                        State {
                                            name: "hovered"
                                            when: historyMouseArea.containsMouse
                                            PropertyChanges {
                                                target: fileIconRect
                                                scale: 1.05
                                            }
                                        }
                                    ]

                                    transitions: Transition {
                                        NumberAnimation {
                                            properties: "scale"
                                            duration: 150
                                            easing.type: Easing.OutQuad
                                        }
                                    }
                                }

                                // 文件信息
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: model.name || "未知文件"
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                        color: "#1F2937"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: formatFileSize(
                                                  model.size) + " • " + formatISODateTime(
                                                  model.completedTime)
                                        font.pixelSize: 10
                                        color: "#6B7280"
                                    }
                                }
                                RowLayout {
                                    spacing: 8
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                    Button {
                                        id: openButton
                                        Layout.preferredWidth: 70
                                        Layout.preferredHeight: 28

                                        background: Rectangle {
                                            radius: 6
                                            color: parent.hovered ? "#EFF6FF" : "#F0F9FF"
                                            border.color: parent.hovered ? "#3B82F6" : "transparent" // 移除默认边框
                                            border.width: parent.hovered ? 1 : 0
                                            layer.enabled: true
                                            layer.effect: DropShadow {
                                                horizontalOffset: 0
                                                verticalOffset: 1
                                                radius: 3
                                                samples: 6
                                                color: "#20000000"
                                            }
                                        }

                                        contentItem: RowLayout {
                                            spacing: 2
                                            anchors.centerIn: parent
                                            width: parent.width - 10

                                            Text {
                                                text: "📂"
                                                font.pixelSize: 12
                                                color: "#1D4ED8"
                                            }

                                            Text {
                                                text: "打开"
                                                font.pixelSize: 10
                                                font.weight: Font.Medium
                                                color: "#1D4ED8"
                                                elide: Text.ElideRight // 防止文字溢出
                                            }
                                        }

                                        onClicked: {
                                            let fullPath = model.localPath || ""
                                            // 本地路径是空的
                                            console.log("点击打开按钮, 本地路径:",
                                                        fullPath, "文件名:",
                                                        model.name)
                                            if (fullPath) {
                                                openFileLocation(fullPath,
                                                                 model.name)
                                            } else {
                                                console.warn("文件路径不存在:",
                                                             model.name)
                                            }
                                        }
                                        TtToolTip {
                                            text: qsTr("打开文件位置")
                                            visible: parent.hovered
                                            delay: 500
                                            arrowPosition: "auto"
                                        }

                                        scale: hovered ? 1.05 : 1.0
                                        Behavior on scale {
                                            NumberAnimation {
                                                duration: 100
                                            }
                                        }
                                    }
                                    Button {
                                        id: deleteButton
                                        Layout.preferredWidth: 36
                                        Layout.preferredHeight: 28

                                        background: Rectangle {
                                            radius: 6
                                            color: parent.hovered ? "#FEE2E2" : "#FFF1F1"
                                            border.color: parent.hovered ? "#EF4444" : "transparent" // 移除默认边框
                                            border.width: parent.hovered ? 1 : 0

                                            // 现代化阴影效果
                                            layer.enabled: true
                                            layer.effect: DropShadow {
                                                horizontalOffset: 0
                                                verticalOffset: 1
                                                radius: 3
                                                samples: 6
                                                color: "#20000000"
                                            }
                                        }

                                        contentItem: Text {
                                            text: "🗑️"
                                            font.pixelSize: 13
                                            color: "#DC2626"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        onClicked: {
                                            removeHistoryItem(index,
                                                              model.jobId,
                                                              model.name)
                                        }

                                        ToolTip.visible: hovered
                                        ToolTip.text: "删除历史记录"
                                        ToolTip.delay: 500
                                        rotation: hovered ? 5 : 0
                                        Behavior on rotation {
                                            NumberAnimation {
                                                duration: 150
                                                easing.type: Easing.OutQuad
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        // 空历史记录的显示
                        Item {
                            anchors.centerIn: parent
                            visible: historyListView.count === 0

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 16

                                Rectangle {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 80
                                    height: 80
                                    radius: 40
                                    color: "#F1F5F9"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "📋"
                                        font.pixelSize: 32
                                    }
                                }

                                Text {
                                    text: "暂无历史记录"
                                    color: "#64748B"
                                    font.pixelSize: 18
                                    font.weight: Font.Medium
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                Text {
                                    text: "已完成的下载任务将在这里显示"
                                    color: "#94A3B8"
                                    font.pixelSize: 14
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }
                    }
                }
            }
        }

        // 底部状态栏
        Rectangle {
            id: statusBar
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 44
            color: "#FAFBFC"
            radius: 12

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: parent.radius
                color: parent.color
            }

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: "#E2E8F0"
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24

                Text {
                    text: {
                        if (downloadWindow.currentTab === 0) {
                            const active = getActiveDownloadCount()
                            const total = downloadWindow.downloadModel ? downloadWindow.downloadModel.count : 0
                            return active + " 个活跃，共 " + total + " 个任务"
                        } else {
                            const total = downloadWindow.historyModel ? downloadWindow.historyModel.count : 0
                            return "共 " + total + " 条历史记录"
                        }
                    }
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: "#64748B"
                }

                // 临时消息显示
                Text {
                    id: statusMessage
                    visible: false
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: "#10B981"

                    Timer {
                        id: statusMessageTimer
                        interval: 3000
                        onTriggered: statusMessage.visible = false
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: "CloudStorageHub"
                    font.pixelSize: 13
                    color: "#94A3B8"
                }
            }
        }
    }

    // 所有函数保持不变
    function getActiveDownloadCount() {
        if (!downloadModel)
            return 0
        var count = 0
        for (var i = 0; i < downloadModel.count; i++) {
            const item = downloadModel.get(i)
            if (item && item.progress < 1 && item.status !== "错误"
                    && item.status !== "已完成") {
                count++
            }
        }
        return count
    }

    function pauseDownload(jobId) {
        // 两次
        console.log("暂停下载:", jobId)
        ManagerGlobal.pauseDownload(jobId)
    }

    function resumeDownload(jobId) {
        console.log("继续下载:", jobId)
        ManagerGlobal.resumeDownload(jobId)
    }

    function cancelDownload(jobId) {
        console.log("取消下载:", jobId)
        ManagerGlobal.cancelDownload(jobId)
    }

    function pauseAllDownloads() {
        if (!downloadModel)
            return
        for (var i = 0; i < downloadModel.count; i++) {
            const item = downloadModel.get(i)
            if (item && item.progress < 1 && item.status !== "暂停"
                    && item.status !== "错误") {
                pauseDownload(item.jobId)
                downloadModel.setProperty(i, "status", "暂停")
            }
        }
    }
    function retryDownload(item) {
        console.log("重试下载:", item.name)
        if (downloadModel) {
            downloadModel.append({
                                     "name": item.name,
                                     "size": item.size,
                                     "jobId": item.jobId,
                                     "progress": 0,
                                     "status": "准备下载",
                                     "speed": "0 KB/s",
                                     "startTime": new Date().getTime(),
                                     "lastUpdateTime": new Date().getTime()
                                 })
        }
        ManagerGlobal.downloadFile(item.jobId, item.bucketName, item.key,
                                   item.name)
    }

    function removeFromHistory(jobId) {
        if (!historyModel)
            return
        for (var i = historyModel.count - 1; i >= 0; i--) {
            const item = historyModel.get(i)
            if (item && item.jobId === jobId) {
                historyModel.remove(i)
                break
            }
        }
    }
}


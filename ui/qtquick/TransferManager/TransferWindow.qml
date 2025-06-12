import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import QtQuick.Dialogs

import "../Component"
import QWindowKit

Window {
    id: transferWindow
    title: "传输管理器"
    width: 720
    height: 600
    minimumWidth: 560
    minimumHeight: 400

    // 模型属性 - 统一管理上传和下载
    property var uploadModel: null
    property var downloadModel: null

    // property var uploadHistoryModel: null
    // property var downloadHistoryModel: null
    // 🔥 新增：历史记录模型 - 从数据库加载
    property var downloadHistoryModel: Qt.createQmlObject(
                                           'import QtQuick; ListModel {}',
                                           transferWindow)
    property var uploadHistoryModel: Qt.createQmlObject(
                                         'import QtQuick; ListModel {}',
                                         transferWindow)

    property int currentTab: 0 // 0:上传中, 1:上传历史, 2:下载中, 3:下载历史

    // 活动任务计数
    property int activeUploads: 0
    property int activeDownloads: 0

    // type: "upload" | "download"
    signal transferPaused(string jobId, string type)
    signal transferResumed(string jobId, string type)
    signal transferCancelled(string jobId, string type)
    signal transferRetried(string jobId, string type)
    signal historyItemRemoved(string jobId, string type)

    // 在 TransferWindow.qml 或相关组件中
    Connections {
        target: ManagerGlobal

        function onDownloadProgressUpdated(jobId, progress) {
            console.log("下载进度更新:", jobId, progress)

            // 🔥 检查是否完成 (progress >= 1.0 表示完成)
            if (progress >= 1.0) {
                // 从当前下载任务中获取信息
                var taskInfo = getDownloadTaskInfo(jobId)
                if (taskInfo) {
                    ManagerGlobal.handleDownloadCompleted(jobId,
                                                          taskInfo.fileName,
                                                          taskInfo.bucketName,
                                                          taskInfo.objectKey,
                                                          taskInfo.localPath,
                                                          taskInfo.fileSize,
                                                          true // 成功完成
                                                          )
                }
            }
        }

        function onUploadProgressUpdated(jobId, progress) {
            console.log("上传进度更新:", jobId, progress)

            // 🔥 检查是否完成
            if (progress >= 1.0) {
                var taskInfo = getUploadTaskInfo(jobId)
                if (taskInfo) {
                    ManagerGlobal.handleUploadCompleted(jobId,
                                                        taskInfo.fileName,
                                                        taskInfo.bucketName,
                                                        taskInfo.remotePath,
                                                        taskInfo.localPath,
                                                        taskInfo.fileSize,
                                                        true // 成功完成
                                                        )
                }
            }
        }
    }

    // 辅助函数：从模型中获取任务信息
    function getDownloadTaskInfo(jobId) {
        if (!downloadModel)
            return null

        for (var i = 0; i < downloadModel.count; i++) {
            var item = downloadModel.get(i)
            if (item.jobId === jobId) {
                return {
                    "fileName": item.fileName || item.name,
                    "bucketName": item.bucketName,
                    "objectKey": item.objectKey || item.key,
                    "localPath": item.localPath,
                    "fileSize": item.fileSize || item.size
                }
            }
        }
        return null
    }

    function getUploadTaskInfo(jobId) {
        if (!uploadModel)
            return null

        for (var i = 0; i < uploadModel.count; i++) {
            var item = uploadModel.get(i)
            if (item.jobId === jobId) {
                return {
                    "fileName": item.fileName || item.name,
                    "bucketName": item.bucketName,
                    "remotePath": item.remotePath || item.key,
                    "localPath": item.localPath,
                    "fileSize": item.fileSize || item.size
                }
            }
        }
        return null
    }

    Component.onCompleted: {
        windowAgent.setup(transferWindow)
        windowAgent.setWindowAttribute("dark-mode", true)

        // 初始化模型（如果需要）
        if (!uploadModel) {
            uploadModel = Qt.createQmlObject('import QtQuick; ListModel {}',
                                             transferWindow)
        }
        if (!downloadModel) {
            downloadModel = Qt.createQmlObject('import QtQuick; ListModel {}',
                                               transferWindow)
        }
        // if (!uploadHistoryModel) {
        //     uploadHistoryModel = Qt.createQmlObject(
        //                 'import QtQuick; ListModel {}', transferWindow)
        // }
        // if (!downloadHistoryModel) {
        //     downloadHistoryModel = Qt.createQmlObject(
        //                 'import QtQuick; ListModel {}', transferWindow)
        // }
        // 🔥 加载历史记录
        loadDownloadHistory()
        loadUploadHistory()

        // 监听历史记录变化
        connectHistorySignals()

        connectTransferCompletionSignals()
    }

    WindowAgent {
        id: windowAgent
    }

    QtObject {
        id: darkStyle
        readonly property color windowBackgroundColor: "#1E1E1E"
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
            height: 50
            color: "#2C3E50"
            z: 100
            Component.onCompleted: windowAgent.setTitleBar(titleBar)

            Rectangle {
                id: dragIndicator
                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                    topMargin: 6
                }
                width: 48
                height: 4
                radius: 2
                color: "#3B82F6"
                opacity: 0.8

                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: "#60A5FA"
                    }
                    GradientStop {
                        position: 0.5
                        color: "#3B82F6"
                    }
                    GradientStop {
                        position: 1.0
                        color: "#60A5FA"
                    }
                }

                // 增强的呼吸效果
                SequentialAnimation {
                    running: true
                    loops: Animation.Infinite

                    NumberAnimation {
                        target: dragIndicator
                        property: "opacity"
                        from: 0.3 // 更低的起始透明度
                        to: 1.0
                        duration: 1500 // 更快的动画
                        easing.type: Easing.InOutQuad
                    }

                    NumberAnimation {
                        target: dragIndicator
                        property: "opacity"
                        from: 1.0
                        to: 0.3 // 更低的结束透明度
                        duration: 1500
                        easing.type: Easing.InOutQuad
                    }
                }

                // 添加宽度呼吸效果，让效果更明显
                SequentialAnimation {
                    running: true
                    loops: Animation.Infinite

                    NumberAnimation {
                        target: dragIndicator
                        property: "width"
                        from: 48
                        to: 56 // 稍微变宽
                        duration: 1500
                        easing.type: Easing.InOutQuad
                    }

                    NumberAnimation {
                        target: dragIndicator
                        property: "width"
                        from: 56
                        to: 48
                        duration: 1500
                        easing.type: Easing.InOutQuad
                    }
                }

                // 添加颜色脉动效果
                SequentialAnimation {
                    running: true
                    loops: Animation.Infinite

                    ColorAnimation {
                        target: dragIndicator
                        property: "color"
                        from: "#3B82F6"
                        to: "#60A5FA"
                        duration: 1500
                        easing.type: Easing.InOutQuad
                    }

                    ColorAnimation {
                        target: dragIndicator
                        property: "color"
                        from: "#60A5FA"
                        to: "#3B82F6"
                        duration: 1500
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                // 标题文本
                Text {
                    text: "传输管理器"
                    color: "#FFFFFF"
                    font.pixelSize: 18
                    font.bold: true
                }
                Item {
                    Layout.fillWidth: true
                }
                // // 刷新历史按钮
                // Button {
                //     text: "🔄"
                //     width: 32
                //     height: 32
                //     flat: true

                //     background: Rectangle {
                //         color: parent.hovered ? "#34495E" : "transparent"
                //         radius: 4
                //     }
                //     contentItem: Text {
                //         text: parent.text
                //         color: "#FFFFFF"
                //         font.pixelSize: 16
                //         horizontalAlignment: Text.AlignHCenter
                //         verticalAlignment: Text.AlignVCenter
                //     }

                //     onClicked: {
                //         console.log("刷新历史记录")
                //         refreshHistory()
                //     }

                //     ToolTip.visible: hovered
                //     ToolTip.text: "刷新历史记录"
                // }
                Button {
                    id: closeButton
                    text: "✕"
                    width: 32
                    height: 32
                    flat: true

                    background: Rectangle {
                        color: parent.hovered ? "#E74C3C" : "transparent"
                        radius: 4
                    }

                    contentItem: Text {
                        text: parent.text
                        color: "#FFFFFF"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: transferWindow.close()
                    Component.onCompleted: {
                        // 允许点击
                        windowAgent.setHitTestVisible(closeButton, true)
                    }
                }
            }
        }
        // 内容区域
        Rectangle {
            anchors {
                top: titleBar.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            color: "#F5F6FA"

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // 选项卡栏
                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    color: "#ECEFF1"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 0
                        spacing: 0

                        // 下载中
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: currentTab === 0 ? "#FFFFFF" : "transparent"

                            MouseArea {
                                anchors.fill: parent
                                onClicked: currentTab = 0
                            }

                            RowLayout {
                                anchors.centerIn: parent

                                Text {
                                    text: "下载中"
                                    color: currentTab === 0 ? "#2C3E50" : "#7F8C8D"
                                    font.weight: currentTab === 0 ? Font.Medium : Font.Normal
                                }

                                Rectangle {
                                    visible: activeDownloads > 0
                                    width: 20
                                    height: 16
                                    radius: 8
                                    color: "#E74C3C"

                                    Text {
                                        anchors.centerIn: parent
                                        text: activeDownloads.toString()
                                        color: "#FFFFFF"
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                    }
                                }
                            }
                        }

                        // 下载历史
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: currentTab === 1 ? "#FFFFFF" : "transparent"

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    currentTab = 1
                                    loadDownloadHistory() // 切换时刷新
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "下载历史"
                                color: currentTab === 1 ? "#2C3E50" : "#7F8C8D"
                                font.weight: currentTab === 1 ? Font.Medium : Font.Normal
                            }
                        }

                        // 上传中
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: currentTab === 2 ? "#FFFFFF" : "transparent"

                            MouseArea {
                                anchors.fill: parent
                                onClicked: currentTab = 2
                            }

                            RowLayout {
                                anchors.centerIn: parent

                                Text {
                                    text: "上传中"
                                    color: currentTab === 2 ? "#2C3E50" : "#7F8C8D"
                                    font.weight: currentTab === 2 ? Font.Medium : Font.Normal
                                }

                                Rectangle {
                                    visible: activeUploads > 0
                                    width: 20
                                    height: 16
                                    radius: 8
                                    color: "#3498DB"

                                    Text {
                                        anchors.centerIn: parent
                                        text: activeUploads.toString()
                                        color: "#FFFFFF"
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                    }
                                }
                            }
                        }

                        // 上传历史
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: currentTab === 3 ? "#FFFFFF" : "transparent"

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    currentTab = 3
                                    loadUploadHistory() // 切换时刷新
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "上传历史"
                                color: currentTab === 3 ? "#2C3E50" : "#7F8C8D"
                                font.weight: currentTab === 3 ? Font.Medium : Font.Normal
                            }
                        }
                    }
                }

                // 内容区域
                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: currentTab

                    // 0: 下载中
                    TransferListView {
                        model: transferWindow.downloadModel
                        transferType: "download"
                        showActiveOnly: true

                        onTransferPaused: function (jobId) {
                            transferWindow.transferPaused(jobId, "download")
                        }
                        onTransferResumed: function (jobId) {
                            transferWindow.transferResumed(jobId, "download")
                        }
                        onTransferCancelled: function (jobId) {
                            transferWindow.transferCancelled(jobId, "download")
                        }
                    }

                    // 1: 下载历史 - 🔥 使用历史记录视图
                    TransferHistoryView {
                        model: transferWindow.downloadHistoryModel
                        transferType: "download"

                        onTransferRetried: function (jobId) {
                            console.log("重试下载:", jobId)
                            retryDownloadFromHistory(jobId)
                        }
                        onHistoryItemRemoved: function (jobId) {
                            console.log("删除下载历史:", jobId)
                            removeDownloadHistory(jobId)
                        }
                        onFileLocationOpened: function (localPath) {
                            transferWindow.openFileLocation(localPath)
                        }
                    }

                    // 2: 上传中
                    TransferListView {
                        model: transferWindow.uploadModel
                        transferType: "upload"
                        showActiveOnly: true

                        onTransferPaused: function (jobId) {
                            transferWindow.transferPaused(jobId, "upload")
                        }
                        onTransferResumed: function (jobId) {
                            transferWindow.transferResumed(jobId, "upload")
                        }
                        onTransferCancelled: function (jobId) {
                            transferWindow.transferCancelled(jobId, "upload")
                        }
                    }

                    // 3: 上传历史 - 🔥 使用历史记录视图
                    TransferHistoryView {
                        model: transferWindow.uploadHistoryModel
                        transferType: "upload"

                        onTransferRetried: function (jobId) {
                            console.log("重试上传:", jobId)
                            retryUploadFromHistory(jobId)
                        }
                        onHistoryItemRemoved: function (jobId) {
                            console.log("删除上传历史:", jobId)
                            removeUploadHistory(jobId)
                        }
                        onFileLocationOpened: function (localPath) {
                            transferWindow.openFileLocation(localPath)
                        }
                    }
                }

                // 底部操作栏
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    color: "#ECEFF1"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8

                        Text {
                            text: {
                                switch (currentTab) {
                                case 0:
                                    return `活跃下载: ${activeDownloads}`
                                case 1:
                                    return `历史记录: ${downloadHistoryModel.count}`
                                case 2:
                                    return `活跃上传: ${activeUploads}`
                                case 3:
                                    return `历史记录: ${uploadHistoryModel.count}`
                                default:
                                    return ""
                                }
                            }
                            color: "#7F8C8D"
                            font.pixelSize: 12
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        // 🔥 清空历史按钮
                        Button {
                            visible: currentTab === 1 || currentTab === 3
                            text: "清空历史"
                            height: 24

                            background: Rectangle {
                                color: parent.hovered ? "#E74C3C" : "#BDC3C7"
                                radius: 4
                            }

                            contentItem: Text {
                                text: parent.text
                                color: "#FFFFFF"
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: clearHistory()
                        }
                    }
                }
            }
        }
    }

    // 🔥 历史记录相关函数
    function loadDownloadHistory() {
        console.log("加载下载历史记录")
        if (!ManagerGlobal || !ManagerGlobal.getHistoryManager) {
            console.warn("HistoryManager 不可用")
            return
        }

        var historyManager = ManagerGlobal.getHistoryManager()
        if (!historyManager) {
            console.warn("无法获取 HistoryManager 实例")
            return
        }

        try {
            var history = historyManager.getDownloadHistory(100)
            downloadHistoryModel.clear()

            for (var i = 0; i < history.length; i++) {
                var item = history[i]
                downloadHistoryModel.append({
                                                "jobId": item.jobId || "",
                                                "name": item.fileName || "未知文件",
                                                "fileName": item.fileName
                                                            || "未知文件",
                                                "size": formatFileSize(
                                                            item.fileSize)
                                                        || "未知大小",
                                                "fileSize": item.fileSize || 0,
                                                "bucketName": item.bucketName
                                                              || "",
                                                "objectKey": item.objectKey
                                                             || "",
                                                "localPath": item.localPath
                                                             || "",
                                                "status": item.status || "已完成",
                                                "startTime": item.startTime
                                                             || 0,
                                                "completedTime": item.completedTime
                                                                 || 0,
                                                "createdAt": item.createdAt
                                                             || ""
                                            })
            }

            console.log("加载下载历史完成，记录数:", downloadHistoryModel.count)
        } catch (error) {
            console.error("加载下载历史失败:", error)
        }
    }

    function loadUploadHistory() {
        console.log("加载上传历史记录")
        if (!ManagerGlobal || !ManagerGlobal.getHistoryManager) {
            return
        }

        var historyManager = ManagerGlobal.getHistoryManager()
        if (!historyManager) {
            return
        }

        try {
            var history = historyManager.getUploadHistory(100)
            uploadHistoryModel.clear()

            for (var i = 0; i < history.length; i++) {
                var item = history[i]
                uploadHistoryModel.append({
                                              "jobId": item.jobId || "",
                                              "name": item.fileName || "未知文件",
                                              "fileName": item.fileName
                                                          || "未知文件",
                                              "size": formatFileSize(
                                                          item.fileSize)
                                                      || "未知大小",
                                              "fileSize": item.fileSize || 0,
                                              "bucketName": item.bucketName
                                                            || "",
                                              "remotePath": item.remotePath
                                                            || "",
                                              "localPath": item.localPath || "",
                                              "status": item.status || "已完成",
                                              "startTime": item.startTime || 0,
                                              "completedTime": item.completedTime
                                                               || 0,
                                              "createdAt": item.createdAt || ""
                                          })
            }

            console.log("加载上传历史完成，记录数:", uploadHistoryModel.count)
        } catch (error) {
            console.error("加载上传历史失败:", error)
        }
    }

    function refreshHistory() {
        if (currentTab === 1) {
            loadDownloadHistory()
        } else if (currentTab === 3) {
            loadUploadHistory()
        }
    }

    function clearHistory() {
        if (!ManagerGlobal || !ManagerGlobal.getHistoryManager) {
            return
        }

        var historyManager = ManagerGlobal.getHistoryManager()
        if (!historyManager) {
            return
        }

        try {
            if (currentTab === 1) {
                historyManager.clearDownloadHistory()
                downloadHistoryModel.clear()
                console.log("清空下载历史成功")
            } else if (currentTab === 3) {
                historyManager.clearUploadHistory()
                uploadHistoryModel.clear()
                console.log("清空上传历史成功")
            }
        } catch (error) {
            console.error("清空历史失败:", error)
        }
    }

    function removeDownloadHistory(jobId) {
        if (!ManagerGlobal || !ManagerGlobal.getHistoryManager) {
            return
        }

        var historyManager = ManagerGlobal.getHistoryManager()
        if (historyManager && historyManager.removeDownloadRecord(jobId)) {
            // 从模型中移除
            for (var i = 0; i < downloadHistoryModel.count; i++) {
                if (downloadHistoryModel.get(i).jobId === jobId) {
                    downloadHistoryModel.remove(i)
                    break
                }
            }
            console.log("删除下载历史成功:", jobId)
        }
    }

    function removeUploadHistory(jobId) {
        if (!ManagerGlobal || !ManagerGlobal.getHistoryManager) {
            return
        }

        var historyManager = ManagerGlobal.getHistoryManager()
        if (historyManager && historyManager.removeUploadRecord(jobId)) {
            // 从模型中移除
            for (var i = 0; i < uploadHistoryModel.count; i++) {
                if (uploadHistoryModel.get(i).jobId === jobId) {
                    uploadHistoryModel.remove(i)
                    break
                }
            }
            console.log("删除上传历史成功:", jobId)
        }
    }

    function retryDownloadFromHistory(jobId) {
        // 从历史记录中找到对应项
        for (var i = 0; i < downloadHistoryModel.count; i++) {
            var item = downloadHistoryModel.get(i)
            if (item.jobId === jobId) {
                // 重新发起下载
                if (ManagerGlobal && ManagerGlobal.downloadFile) {
                    var newJobId = "download_" + Date.now()
                    ManagerGlobal.downloadFile(newJobId, item.bucketName,
                                               item.objectKey, item.localPath)
                    console.log("重新发起下载:", newJobId)
                }
                break
            }
        }
    }

    function retryUploadFromHistory(jobId) {
        // 从历史记录中找到对应项
        for (var i = 0; i < uploadHistoryModel.count; i++) {
            var item = uploadHistoryModel.get(i)
            if (item.jobId === jobId) {
                // 重新发起上传
                if (ManagerGlobal && ManagerGlobal.uploadFile) {
                    var newJobId = "upload_" + Date.now()
                    ManagerGlobal.uploadFile(newJobId, item.bucketName,
                                             item.remotePath, item.localPath)
                    console.log("重新发起上传:", newJobId)
                }
                break
            }
        }
    }

    function connectHistorySignals() {
        // 监听历史记录变化信号
        if (ManagerGlobal && ManagerGlobal.getHistoryManager) {
            var historyManager = ManagerGlobal.getHistoryManager()
            if (historyManager) {
                try {
                    historyManager.downloadHistoryChanged.connect(
                                loadDownloadHistory)
                    historyManager.uploadHistoryChanged.connect(
                                loadUploadHistory)
                    console.log("历史记录信号连接成功")
                } catch (error) {
                    console.warn("连接历史记录信号失败:", error)
                }
            }
        }
    }

    // function openFileLocation(localPath) {
    //     console.log("传输窗口：尝试打开文件位置:", localPath)

    //     if (!localPath || localPath === "") {
    //         console.warn("文件路径为空")
    //         return false
    //     }

    //     // 这里可以调用系统的文件管理器打开文件位置
    //     // 或者调用 ManagerGlobal 的相关方法
    //     var folderPath = localPath.substring(0, localPath.lastIndexOf('/'))
    //     if (folderPath) {
    //         console.log("文件夹路径:", folderPath)
    //         // TODO: 调用系统文件管理器
    //     } else {
    //         console.warn("无法确定文件夹路径")
    //     }
    // }

    // 工具函数
    function formatFileSize(bytes) {
        if (!bytes || bytes === 0)
            return "0 B"

        const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
        const i = Math.floor(Math.log(bytes) / Math.log(1024))
        return Math.round(bytes / Math.pow(1024,
                                           i) * 100) / 100 + ' ' + sizes[i]
    }

    function updateActiveUploads() {
        if (!uploadModel)
            return

        var count = 0
        for (var i = 0; i < uploadModel.count; i++) {
            var item = uploadModel.get(i)
            if (item && (item.status === "上传中" || item.status === "准备中")) {
                count++
            }
        }
        activeUploads = count
    }

    function updateActiveDownloads() {
        if (!downloadModel)
            return

        var count = 0
        for (var i = 0; i < downloadModel.count; i++) {
            var item = downloadModel.get(i)
            if (item && (item.status === "下载中" || item.status === "准备下载")) {
                count++
            }
        }
        activeDownloads = count
    }

    function pauseAllTransfers() {
        if (currentTab === 0 && uploadModel) {
            // 暂停所有上传
            for (var i = 0; i < uploadModel.count; i++) {
                var item = uploadModel.get(i)
                if (item && item.status === "上传中") {
                    transferPaused(item.jobId, "upload")
                }
            }
        } else if (currentTab === 2 && downloadModel) {
            // 暂停所有下载
            for (var i = 0; i < downloadModel.count; i++) {
                var item = downloadModel.get(i)
                if (item && item.status === "下载中") {
                    transferPaused(item.jobId, "download")
                }
            }
        }
    }

    function clearCompletedTransfers() {
        if (currentTab === 1 && uploadHistoryModel) {
            // 清理上传历史
            for (var i = uploadHistoryModel.count - 1; i >= 0; i--) {
                var item = uploadHistoryModel.get(i)
                if (item && item.status === "已完成") {
                    uploadHistoryModel.remove(i)
                }
            }
        } else if (currentTab === 3 && downloadHistoryModel) {
            // 清理下载历史
            for (var i = downloadHistoryModel.count - 1; i >= 0; i--) {
                var item = downloadHistoryModel.get(i)
                if (item && item.status === "已完成") {
                    downloadHistoryModel.remove(i)
                }
            }
        }
    }

    function openTransferSettings() {
        // 打开传输设置对话框
        console.log("打开传输设置")
    }

    // function openFileLocation(localPath, fileName) {
    function openFileLocation(localPath) {
        // console.log("打开文件位置:", localPath, fileName)
        console.log("传输窗口：尝试打开文件位置:", localPath)

        if (!localPath || localPath === "") {
            showMessage("文件路径不存在: " + fileName)
            fileLocationDialog.currentFolder = "file:///C:/" // 设置默认目录
            fileLocationDialog.open()
            return false
        }

        // 检查文件是否存在
        if (ManagerGlobal && ManagerGlobal.fileExists === "function") {
            if (!ManagerGlobal.fileExists(localPath)) {
                console.warn("文件不存在:", localPath)
                // showMessage("文件不存在: " + localPath)
                // 打开文件所在目录
                // var folderPath = localPath.substring(0,
                //                                      localPath.lastIndexOf('/'))
                // if (folderPath) {
                //     Qt.openUrlExternally("file:///" + folderPath.replace(/\\/g,
                //                                                          '/'))
                //     showMessage("已打开文件夹: " + folderPath)
                // }
                return false
            }
        } else {
            // 调用的都是这个方法
            var folderPath = localPath.substring(0, localPath.lastIndexOf('/'))
            if (folderPath) {
                Qt.openUrlExternally("file:///" + folderPath)
                // showMessage("已打开文件夹: " + folderPath)
            } else {
                console.warn("openFileLocation 方法不可用")
                // showMessage("无法打开文件位置")
            }
        }
    }

    // 定时更新活动任务计数
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            updateActiveUploads()
            updateActiveDownloads()
        }
    }

    function connectTransferCompletionSignals() {
        if (ManagerGlobal) {
            // 监听下载完成信号
            ManagerGlobal.downloadCompleted.connect(
                        function (jobId, fileName, bucketName, objectKey, localPath, fileSize, success) {
                            console.log("接收到下载完成信号:", jobId, fileName,
                                        "成功:", success)

                            if (success) {
                                // 🔥 实时刷新下载历史（如果当前在历史页面）
                                if (currentTab === 1) {
                                    Qt.callLater(loadDownloadHistory)
                                }
                            }
                        })

            // 监听上传完成信号
            ManagerGlobal.uploadCompleted.connect(
                        function (jobId, fileName, bucketName, remotePath, localPath, fileSize, success) {
                            console.log("接收到上传完成信号:", jobId, fileName,
                                        "成功:", success)

                            if (success) {
                                // 🔥 实时刷新上传历史（如果当前在历史页面）
                                if (currentTab === 3) {
                                    Qt.callLater(loadUploadHistory)
                                }
                            }
                        })

            console.log("✅ 传输完成信号连接成功")
        }
    }
}

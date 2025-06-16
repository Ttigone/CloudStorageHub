import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import QtQml.Models
import Qt.labs.qmlmodels
import QtQml
import Qt5Compat.GraphicalEffects

import "./Component"
import "./Component/notification"

// 后端的 model 以赋值形式填入, 始终都是值更新, 没办法捕获底层的 model 是否改变, 赋值给代理模型, 代理模型不知道是否改变
Item {
    id: rootItem
    anchors.fill: parent
    property var columnWidths: [300, 150, 150, 100] // 名称、大小、日期、操作按钮区
    property int currentPerPage: 20
    property ListModel downloadModel: ListModel {}
    property var paginationProxy: null
    // // 添加一个属性来存储当前面包屑路径
    property var breadcrumbPathData: []
    property var transferWindow: null

    signal uploadRequested
    // 内部发出下载信号
    signal downloadRequested(var selectedItems)
    // 搜索信号
    signal searchRequested(string query)
    signal folderSelected(string folderId)
    // 登出信号
    signal logoutRequested
    signal updateCurrentBucket(string bucketName)

    // 初始化完成：
    signal initializationCompleted

    // 暴露的属性和信号
    property var folderModel: [] // 文件夹模型数据
    property var fileModel: [] // 文件模型数据

    property int sortColumn: -1 // -1表示未排序，0,1,2,3对应不同列
    property bool sortAscending: true // true为升序，false为降序
    property string currentBucket: "" // 当前选中的存储桶

    property int currentRecordCount: updateRecordCount()
    property int currentPage: 1

    property ListModel uploadModel: ListModel {}
    property ListModel uploadHistoryModel: ListModel {}
    property var fileUploadDialog: null
    property var uploadPanel: null

    TtDesktopNotificationManager {
        id: notificationManager
        anchors.fill: parent
        z: 2000 // 确保在最顶层
        position: "topRight"
        maxNotifications: 4
        // 🔥 添加组件完成回调，确保初始化完成
        Component.onCompleted: {
            console.log("📢 通知管理器初始化完成")
        }
    }

    Connections {
        target: ManagerGlobal
        function onObjectsLoadingChanged() {
            if (ManagerGlobal.isObjectsLoading) {
                loadingOverlay.show("objects", "正在加载文件列表...")
            } else {
                loadingOverlay.hide()
            }
        }
        function onBucketsLoadingChanged() {
            if (ManagerGlobal.isBucketsLoading) {
                loadingOverlay.show("buckets", "正在加载存储桶...")
            } else {
                loadingOverlay.hide()
            }
        }
    }

    // 🔥 快捷通知方法
    // function showSuccessMessage(message, title, duration) {
    //     rootItem.notificationManager.showSuccess(title || "操作成功", message,
    //                                              duration || 3000)
    // }
    // 🔥 修复快捷通知方法 - 添加安全检查
    function showSuccessMessage(message, title, duration) {
        console.log("🔔 尝试显示成功消息:", message)

        // 安全检查
        if (!notificationManager) {
            console.error("❌ 通知管理器未初始化")
            return
        }

        if (typeof notificationManager.showSuccess !== "function") {
            console.error("❌ showSuccess 方法不存在")
            return
        }

        try {
            notificationManager.showSuccess(title || "操作成功", message,
                                            duration || 3000)
            console.log("✅ 成功显示通知")
        } catch (error) {
            console.error("❌ 显示通知失败:", error)
        }
    }

    Connections {
        target: ManagerGlobal

        function onDownloadCompleted(jobId, fileName, bucketName, objectKey, localPath, fileSize, success) {
            console.log("✅ 接收到下载完成信号:", jobId, fileName, "成功:", success)
            showSuccessMessage("下载任务已完成: " + fileName, "下载完成", 3000)
            // 更新下载模型中的任务状态
            for (var i = 0; i < downloadModel.count; i++) {
                var item = downloadModel.get(i)
                if (item && item.jobId === jobId) {
                    downloadModel.setProperty(i, "status",
                                              success ? "已完成" : "错误")
                    downloadModel.setProperty(i, "progress",
                                              success ? 1.0 : item.progress)

                    if (fileName && fileName !== "downloaded_file.txt") {
                        downloadModel.setProperty(i, "fileName", fileName)
                        downloadModel.setProperty(i, "name", fileName)
                    }

                    if (typeof fileSize === 'number' && fileSize > 0) {
                        downloadModel.setProperty(i, "size", fileSize)
                        downloadModel.setProperty(i, "fileSize", fileSize)
                    }

                    downloadModel.setProperty(i, "completedTime",
                                              new Date().getTime())

                    if (success) {
                        console.log("🔄 开始保存下载历史记录...")
                        // 保存历史记录
                        ManagerGlobal.saveDownloadToHistory(jobId, fileName,
                                                            bucketName,
                                                            objectKey,
                                                            localPath, fileSize)
                    }
                    break
                }
            }
        }
        function onDownloadProgressUpdated(jobId, progress) {
            console.log("更新下载进度:", jobId, progress)

            for (var i = 0; i < downloadModel.count; i++) {
                var item = downloadModel.get(i)
                if (item && item.jobId === jobId) {
                    var numericProgress = typeof progress === 'number' ? progress : parseFloat(
                                                                             progress)
                    downloadModel.setProperty(i, "progress", numericProgress)

                    if (numericProgress >= 1.0) {
                        downloadModel.setProperty(i, "status", "已完成")
                        console.log("更新下载进度完成, 100%")
                        handleDownloadCompleted(jobId)
                    } else {
                        downloadModel.setProperty(i, "status", "下载中")
                    }
                    break
                }
            }
        }
    }

    onUpdateCurrentBucket: function (bucketName) {
        console.log("更新当前桶", bucketName)
        rootItem.currentBucket = bucketName
    }
    function openTransferManager() {
        console.log("打开传输管理窗口")

        if (!transferWindow) {
            var component = Qt.createComponent(
                        "qrc:/ui/TransferManager/TransferWindow.qml")
            if (component.status === Component.Ready) {
                transferWindow = component.createObject(rootItem)
                transferWindow.uploadModel = rootItem.uploadModel
                transferWindow.downloadModel = rootItem.downloadModel
                transferWindow.uploadHistoryModel = rootItem.uploadHistoryModel
                transferWindow.downloadHistoryModel = rootItem.downloadHistoryModel
                Qt.callLater(function () {
                    if (transferWindow.loadDownloadHistory) {
                        transferWindow.loadDownloadHistory()
                    }
                    if (transferWindow.loadUploadHistory) {
                        transferWindow.loadUploadHistory()
                    }
                })

                transferWindow.transferPaused.connect(function (jobId, type) {
                    console.log("暂停传输:", jobId, type)
                    if (type === "upload") {
                        ManagerGlobal.pauseUpload(jobId)
                    } else {
                        ManagerGlobal.pauseDownload(jobId)
                    }
                })

                transferWindow.transferResumed.connect(function (jobId, type) {
                    console.log("恢复传输:", jobId, type)
                    if (type === "upload") {
                        ManagerGlobal.resumeUpload(jobId)
                    } else {
                        ManagerGlobal.resumeDownload(jobId)
                    }
                })

                transferWindow.transferCancelled.connect(
                            function (jobId, type) {
                                console.log("取消传输:", jobId, type)
                                if (type === "upload") {
                                    ManagerGlobal.cancelUpload(jobId)
                                } else {
                                    ManagerGlobal.cancelDownload(jobId)
                                }
                            })

                transferWindow.transferRetried.connect(function (jobId, type) {
                    console.log("重试传输:", jobId, type)
                    if (type === "upload") {
                        ManagerGlobal.retryUpload(jobId)
                    } else {
                        ManagerGlobal.retryDownload(jobId)
                    }
                })

                transferWindow.historyItemRemoved.connect(
                            function (jobId, type) {
                                console.log("删除历史记录:", jobId, type)
                                // 从对应的历史模型中删除项目
                                var model = type === "upload" ? transferWindow.uploadHistoryModel : transferWindow.downloadHistoryModel
                                for (var i = 0; i < model.count; i++) {
                                    if (model.get(i).jobId === jobId) {
                                        model.remove(i)
                                        break
                                    }
                                }
                            })

                // 窗口关闭时清理
                transferWindow.onClosing.connect(function () {
                    transferWindow = null
                })
            } else {
                console.error("创建传输管理窗口失败:", component.errorString())
                return
            }
        }

        if (transferWindow) {
            transferWindow.uploadModel = rootItem.uploadModel
            transferWindow.downloadModel = rootItem.downloadModel
            // 如果历史记录模型为空，重新加载
            if (transferWindow.downloadHistoryModel
                    && transferWindow.downloadHistoryModel.count === 0) {
                Qt.callLater(function () {
                    if (transferWindow.loadDownloadHistory) {
                        // 调用空方法
                        transferWindow.loadDownloadHistory()
                    }
                })
            }
            transferWindow.show()
            transferWindow.raise()
            transferWindow.requestActivate()
            console.log("传输管理窗口已打开")
        }
    }

    // 处理上传请求
    onUploadRequested: {
        openFileUploadDialog()
    }

    function getCurrentPath() {
        // 从面包屑导航获取当前路径
        if (breadcrumbNav
                && typeof breadcrumbNav.getCurrentPath === "function") {
            return breadcrumbNav.getCurrentPath()
        }

        // 如果面包屑导航不可用，返回空字符串或根路径
        return ""
    }

    // 创建文件上传对话框
    function openFileUploadDialog() {
        if (!fileUploadDialog) {
            var component = Qt.createComponent(
                        "qrc:/ui/Component/FileUpLoadDialog.qml")
            if (component.status === Component.Ready) {
                fileUploadDialog = component.createObject(rootItem)

                // 连接信号
                fileUploadDialog.uploadRequested.connect(
                            function (uploadTasks) {
                                processUploadTasks(uploadTasks)
                                fileUploadDialog.close()
                            })

                fileUploadDialog.cancelled.connect(function () {
                    fileUploadDialog.close()
                })
            } else {
                console.error("创建文件上传对话框失败:", component.errorString())
                return
            }
        }

        // 设置当前桶信息
        if (currentBucket) {
            fileUploadDialog.targetBucket = currentBucket
        }

        // 设置当前路径
        var currentPath = getCurrentPath()
        if (currentPath && currentPath !== "all" && currentPath !== "") {
            fileUploadDialog.targetPath = currentPath
        }
        if (ManagerGlobal && ManagerGlobal.getBucketNames) {
            fileUploadDialog.bucketList = ManagerGlobal.getBucketNames()
        }
        fileUploadDialog.open()
    }

    function handleOpenBucket(bucketName) {
        switchToObjectsModel(bucketName)
        breadcrumbNav.clearModel(bucketName)
        breadcrumbNav.addPathItem(bucketName, bucketName)
    }

    // 处理上传任务
    function processUploadTasks(uploadTasks) {
        console.log("处理上传任务:", uploadTasks.length, "个文件")
        for (var i = 0; i < uploadTasks.length; i++) {
            var task = uploadTasks[i]
            addUploadTask(task)
        }
        // 显示上传面板
        if (uploadPanel) {
            uploadPanel.open()
        }
    }

    // 添加上传任务到模型
    function addUploadTask(taskInfo) {
        let timestamp = new Date().getTime()
        let random = Math.floor(Math.random() * 10000)
        let jobId = `upload_${timestamp}_${random}`

        // if (!taskInfo.key) {
        //     // BUG 缺少 key, 与 name 相同
        //     console.error("上传失败: 缺少文件 key")
        //     return
        // }
        // if (!taskInfo.name) {
        //     console.error("上传失败: 缺少文件名")
        //     return
        // }
        console.log("添加上传任务:", taskInfo.fileName)

        // 添加到上传模型
        uploadModel.append({
                               "jobId": jobId,
                               "fileName": taskInfo.fileName,
                               "localPath": taskInfo.localPath,
                               "bucket": taskInfo.bucket,
                               "remotePath": taskInfo.remotePath,
                               "status": "待上传",
                               "progress": 0,
                               "startTime": timestamp,
                               "speed": 0,
                               "size": taskInfo.fileSize || 0
                           })

        // 开始上传
        startUploadTask(jobId, taskInfo)
    }

    // 开始上传任务
    function startUploadTask(jobId, taskInfo) {
        console.log("开始上传任务:", jobId)

        // 更新状态为上传中
        updateUploadStatus(jobId, "上传中")

        // 构建远程key
        var remoteKey = taskInfo.remotePath ? taskInfo.remotePath
                                              + taskInfo.fileName : taskInfo.fileName

        // 调用后端上传方法
        if (ManagerGlobal && ManagerGlobal.uploadFile) {
            ManagerGlobal.uploadFile(jobId, taskInfo.bucket, remoteKey,
                                     taskInfo.localPath)
        } else {
            console.error("上传方法不可用")
            updateUploadStatus(jobId, "错误")
        }
    }

    function updateUploadStatus(jobId, status, progress) {
        console.log("更新上传状态:", jobId, status, progress)
        for (var i = 0; i < uploadModel.count; i++) {
            var item = uploadModel.get(i)
            if (item.jobId === jobId) {
                uploadModel.setProperty(i, "status", status)
                if (progress !== undefined) {
                    uploadModel.setProperty(i, "progress", progress)
                }

                // 如果上传完成，移动到历史记录
                if (status === "已完成" && transferWindow
                        && transferWindow.uploadHistoryModel) {
                    transferWindow.uploadHistoryModel.append({
                                                                 "jobId": item.jobId,
                                                                 "fileName": item.fileName,
                                                                 "localPath": item.localPath,
                                                                 "bucket": item.bucket,
                                                                 "remotePath": item.remotePath,
                                                                 "status": "已完成",
                                                                 "progress": 1.0,
                                                                 "completedTime": new Date().getTime(),
                                                                 "size": item.size
                                                                         || 0
                                                             })
                    uploadModel.remove(i)
                }
                break
            }
        }
        updateActiveUploadCount()
    }
    // 添加获取活跃上传数的函数
    function getActiveUploadCount() {
        if (!uploadModel)
            return 0

        var count = 0
        for (var i = 0; i < uploadModel.count; i++) {
            var item = uploadModel.get(i)
            if (item && (item.status === "上传中" || item.status === "准备上传")) {
                count++
            }
        }
        return count
    }

    // 更新活跃上传数
    function updateActiveUploadCount() {
        var count = 0
        for (var i = 0; i < uploadModel.count; i++) {
            var item = uploadModel.get(i)
            if (item.status === "上传中") {
                count++
            }
        }
        if (uploadPanel) {
            uploadPanel.activeUploads = count
        }
    }

    function selectBucketByName(bucketName) {
        console.log("选择桶:", bucketName)

        var bucketModel = ManagerGlobal.getBucketsModel()
        if (!bucketModel) {
            console.error("无法获取桶模型")
            return false
        }

        // 查找匹配的桶
        for (var i = 0; i < bucketModel.rowCount(); i++) {
            var index = bucketModel.index(i, 0)
            var currentBucketName = bucketModel.data(index, Qt.DisplayRole)

            if (currentBucketName === bucketName) {
                console.log("找到匹配的桶，索引:", i, "桶名:", bucketName)

                // 设置左侧桶列表的当前索引
                bucketListView.currentIndex = i

                // 更新当前桶名
                rootItem.currentBucket = bucketName

                // 切换到对象模型显示
                switchToObjectsModel(bucketName)

                // 更新面包屑导航
                breadcrumbNav.resetToRoot()
                breadcrumbNav.addPathItem(bucketName, bucketName)

                // 重置分页状态
                resetPaginationOnFolderChange()

                console.log("成功切换到桶:", bucketName)
                return true
            }
        }

        console.warn("未找到匹配的桶:", bucketName)
        return false
    }

    // 修改下载任务添加函数
    function addDownloadTask(taskInfo) {
        let timestamp = new Date().getTime()
        let random = Math.floor(Math.random() * 10000)
        let jobId = `download_${timestamp}_${random}`
        // 验证必需的下载信息
        if (!taskInfo.key) {
            // 缺少 key, 与 name 相同
            console.error("下载失败: 缺少文件 key")
            return
        }
        if (!taskInfo.name) {
            console.error("下载失败: 缺少文件名")
            return
        }
        let downloadDir = getDownloadDirectory() // 新增函数获取下载目录
        let localPath = downloadDir + "/" + taskInfo.name
        // 下载
        console.log("本地下下载目录: ", localPath)

        // 将下载任务添加到模型
        downloadModel.append({
                                 "name": taskInfo.name,
                                 "size": taskInfo.size || "未知大小",
                                 "progress": 0.0,
                                 "jobId": jobId,
                                 "status": "准备下载",
                                 "speed": "0 KB/s",
                                 "startTime": timestamp,
                                 "lastUpdateTime": timestamp,
                                 "key": taskInfo.key,
                                 "bucketName": rootItem.currentBucket,
                                 "localPath": localPath,
                                 "needsRetry": false,
                                 "retryCount": 0
                             })

        // 下载名有问题
        // 点击下载后, 提供的 key 是有效的路径
        // 获取的 name 有问题
        console.log("添加下载任务:", jobId, taskInfo.name, taskInfo.size,
                    taskInfo.key)
        ManagerGlobal.downloadFile(jobId, rootItem.currentBucket, taskInfo.key,
                                   localPath)
        createDownloadTimeoutCheck(jobId)
        return jobId
    }
    // 在 MainPage.qml 中添加获取补全数据的函数

    // 添加监听模型变化的函数，当文件列表更新时刷新补全数据
    function refreshCompletionData() {
        if (searchField) {
            searchField.completionModel = getCurrentFileCompletions()
        }
    }

    function getDownloadDirectory() {
        // 从设置中获取下载目录，如果没有设置则使用默认目录
        if (typeof ManagerGlobal.getDownloadDirectory === "function") {
            // return ManagerGlobal.getDownloadDirectory()
            let savedPath = ManagerGlobal.getDownloadDirectory()
            if (savedPath && savedPath !== "") {
                return savedPath
            }
        }
        // 默认下载目录
        return ManagerGlobal.getDefaultDownloadDirectory ? ManagerGlobal.getDefaultDownloadDirectory(
                                                               ) : "./downloads"
    }

    function createDownloadTimeoutCheck(jobId) {
        // 声明一个列表模型
        downloadTimeouts[jobId] = {
            "retryCount": 0,
            "maxRetries": 3,
            "checkInterval": 2000
        }
        // 创建独立的定时器
        var timeoutTimer = Qt.createQmlObject(`
                                              import QtQuick
                                              Timer {
                                              interval: 2000
                                              repeat: false
                                              property string taskJobId: "${jobId}"

                                              onTriggered: {
                                              checkSingleTaskProgress(taskJobId)
                                              }
                                              }
                                              `, rootItem,
                                              `timeoutTimer_${jobId}`)
        downloadTimeouts[jobId].timer = timeoutTimer
        timeoutTimer.start()
    }
    // 检查单个任务的进度
    function checkSingleTaskProgress(jobId) {
        if (!downloadTimeouts[jobId]) {
            console.warn("任务超时信息不存在:", jobId)
            return
        }
        // 查找对应的下载项
        var taskItem = null
        var taskIndex = -1
        for (var i = 0; i < downloadModel.count; i++) {
            const item = downloadModel.get(i)
            if (item && item.jobId === jobId) {
                taskItem = item
                taskIndex = i
                break
            }
        }
        if (!taskItem) {
            console.warn("找不到下载任务:", jobId)
            // 清理超时信息
            cleanupDownloadTimeout(jobId)
            return
        }
        // 检查任务是否卡住
        if (taskItem.progress === 0 && (taskItem.status === "准备下载"
                                        || taskItem.status === "连接中...")) {
            var timeoutInfo = downloadTimeouts[jobId]
            console.warn("下载任务可能卡住:", jobId, "重试次数:", timeoutInfo.retryCount)

            if (timeoutInfo.retryCount < timeoutInfo.maxRetries) {
                timeoutInfo.retryCount++
                downloadModel.setProperty(
                            taskIndex, "status",
                            "重试中(" + timeoutInfo.retryCount + "/" + timeoutInfo.maxRetries + ")")
                console.log("自动重试下载:", jobId)
                // 重新启动下载
                ManagerGlobal.downloadFile(jobId, rootItem.currentBucket,
                                           taskItem.key, taskItem.name)

                // 重新启动定时器检查
                if (timeoutInfo.timer) {
                    timeoutInfo.timer.start()
                }
            } else {
                // 超过最大重试次数，标记为错误状态
                downloadModel.setProperty(taskIndex, "status", "超时")
                downloadModel.setProperty(taskIndex, "needsRetry", true)
                downloadModel.setProperty(taskIndex, "speed", "")

                console.error("下载任务超时:", jobId, "重试次数已达上限:",
                              timeoutInfo.maxRetries)

                // 清理超时信息
                cleanupDownloadTimeout(jobId)
            }
        } else {
            // 下载已经开始或完成，清理超时信息
            // console.log("下载任务正常进行或已完成:", jobId)
            cleanupDownloadTimeout(jobId)
        }
    }

    function cleanupDownloadTimeout(jobId) {
        if (downloadTimeouts[jobId]) {
            if (downloadTimeouts[jobId].timer) {
                downloadTimeouts[jobId].timer.stop()
                downloadTimeouts[jobId].timer.destroy()
            }
            delete downloadTimeouts[jobId]
            // console.log("已清理任务超时信息:", jobId)
        }
    }

    // 存储每个任务的超时信息
    property var downloadTimeouts: ({})

    function retryDownload(jobId) {
        // 查找对应的下载项
        for (var i = 0; i < downloadModel.count; i++) {
            const item = downloadModel.get(i)
            if (item && item.jobId === jobId) {
                // 重置状态
                downloadModel.setProperty(i, "progress", 0.0)
                downloadModel.setProperty(i, "status", "准备重新下载")
                downloadModel.setProperty(i, "speed", "0 KB/s")
                downloadModel.setProperty(i, "needsRetry", false)
                downloadModel.setProperty(i, "startTime", new Date().getTime())
                downloadModel.setProperty(i, "lastUpdateTime",
                                          new Date().getTime())
                downloadModel.setProperty(i, "retryCount", item.retryCount + 1)
                // 重新启动下载
                const bucketName = item.bucketName || rootItem.currentBucket
                const key = item.key
                const name = item.name

                console.log("重试下载:", jobId, bucketName, key, name)
                ManagerGlobal.downloadFile(jobId, bucketName, key, name)
                Qt.callLater(function () {
                    checkDownloadProgress(jobId)
                })
                break
            }
        }
    }

    function processBatchDownloads() {
        if (!downloadBatchTimer.batchItems
                || downloadBatchTimer.nextIndex >= downloadBatchTimer.batchItems.length) {
            return
        }

        const startIndex = downloadBatchTimer.nextIndex
        const endIndex = Math.min(startIndex + downloadBatchTimer.batchSize,
                                  downloadBatchTimer.batchItems.length)
        for (var i = startIndex; i < endIndex; i++) {
            addDownloadTask(downloadBatchTimer.batchItems[i])
        }
        downloadBatchTimer.nextIndex = endIndex
        if (downloadBatchTimer.nextIndex < downloadBatchTimer.batchItems.length) {
            downloadBatchTimer.start()
        } else {

            // console.log("所有下载任务已安排完成")
        }
    }
    Timer {
        id: downloadBatchTimer
        interval: 200 // 200毫秒延迟
        repeat: false
        property var batchItems: []
        property int nextIndex: 0
        property int batchSize: 2
        onTriggered: {
            processBatchDownloads()
        }
    }
    property ListModel downloadHistoryModel: ListModel {}

    property var downloadWindow: null

    // 添加获取活跃下载数的函数
    function getActiveDownloadCount() {
        if (!downloadModel)
            return 0

        let count = 0
        for (var i = 0; i < downloadModel.count; i++) {
            const item = downloadModel.get(i)
            if (item && item.progress < 1 && item.status !== "错误"
                    && item.status !== "已完成") {
                count++
            }
        }
        return count
    }

    function sortByColumn(column, ascending) {
        let rows = []
        for (var i = 0; i < tableModel.rowCount; i++) {
            rows.push(tableModel.getRow(i))
        }

        // 根据选定的列排序
        rows.sort(function (a, b) {
            let valueA, valueB

            // 根据列选择字段
            if (column === 1) {
                valueA = a.name ? a.name.toLowerCase() : ""
                valueB = b.name ? b.name.toLowerCase() : ""
            } else if (column === 2) {
                valueA = a.zone ? a.zone.toLowerCase() : ""
                valueB = b.zone ? b.zone.toLowerCase() : ""
            } else if (column === 3) {
                valueA = parseDateString(a.date)
                valueB = parseDateString(b.date)
            } else {
                return 0
            }

            if (ascending) {
                if (valueA < valueB)
                    return -1
                if (valueA > valueB)
                    return 1
                return 0
            } else {
                if (valueA > valueB)
                    return -1
                if (valueA < valueB)
                    return 1
                return 0
            }
        })

        tableModel.clear()
        for (var i = 0; i < rows.length; i++) {
            tableModel.appendRow(rows[i])
        }
    }
    function resetPaginationOnFolderChange() {
        rootItem.currentPage = 1
        tableView.clearSelection()
        rootItem.currentRecordCount = updateRecordCount()

        rootItem.pageStartRow = 0
        rootItem.pageEndRow = Math.min(currentPerPage, currentRecordCount) - 1

        pagination.totalRecords = rootItem.currentRecordCount
        pagination.currentPage = 1
        rootItem.updatePaginationState()

        console.log("文件夹变更，重置分页状态：当前页=1，总记录数=", rootItem.currentRecordCount)
    }

    function parseDateString(dateStr) {
        if (!dateStr) {
            return 0
        }
        try {
            const date = new Date(dateStr)
            if (isNaN(date.getTime())) {
                return dateStr.toLowerCase()
            }
            return date.getTime()
        } catch (e) {
            return dateStr.toLowerCase()
        }
    }

    function switchToBucketsModel() {
        tableView.inBucketMode = true
        const availableWidth = contentPanel.width
        if (availableWidth > 0) {
            rootItem.columnWidths = [Math.max(200,
                                              availableWidth * 0.60), Math.max(
                                         150, availableWidth * 0.20), Math.max(
                                         150, availableWidth * 0.20)]
            console.log("桶模型列宽设置为:", rootItem.columnWidths)
        } else {
            rootItem.columnWidths = [500, 200, 200]
        }
        headerBar.headerTitles = ["桶名称", "区域", "创建时间"]
        console.log("调用一次获取桶，并刷新桶")
        ManagerGlobal.refreshBuckets()
        tableView.model = ManagerGlobal.getBucketsModel()
        paginationProxy = tableView.model
        tableView.contentY = 0
        tableView.forceLayout()
    }

    function switchToObjectsModel(bucketName) {
        showSuccessMessage(`正在切换到对象模型: ${bucketName}`, "切换成功", 2000)
        tableView.inBucketMode = false
        tableView.clearSelection()
        const availableWidth = contentPanel.width
        if (availableWidth > 0) {
            rootItem.columnWidths = [Math.max(200,
                                              availableWidth * 0.45), Math.max(
                                         150, availableWidth
                                         * 0.20), Math.max(150,
                                                           availableWidth * 0.20), Math.max(
                                         100, availableWidth * 0.15)]
        } else {
            rootItem.columnWidths = [300, 150, 150, 100]
        }
        headerBar.headerTitles = [qsTr("对象名称"), qsTr("大小"), qsTr(
                                      "更新时间"), qsTr("操作")]
        var objectsModel = ManagerGlobal.getObjectsModel()
        if (!objectsModel) {
            console.error("无法获取对象模型")
            return
        }
        if (typeof objectsModel.clear === "function") {
            objectsModel.clear()
            console.log("已清空对象模型数据")
        } else if (typeof objectsModel.removeRows === "function") {
            var rowCount = objectsModel.rowCount()
            if (rowCount > 0) {
                objectsModel.removeRows(0, rowCount)
                console.log("已移除所有行数据")
            }
        }
        tableView.model = objectsModel
        tableView.contentY = 0
        tableView.forceLayout()
        Qt.callLater(function () {
            if (rootItem.currentBucket === bucketName) {
                ManagerGlobal.refreshObjects(bucketName)
            } else {
                console.warn("️桶已切换，取消数据请求:", bucketName)
            }
        })
        console.log("对象模型切换完成:", bucketName)
    }

    property int pageStartRow: (currentPage - 1) * currentPerPage
    property int pageEndRow: Math.min(pageStartRow + currentPerPage,
                                      currentRecordCount) - 1

    function getPageStartRow() {
        return (currentPage - 1) * currentPerPage
    }

    function getPageEndRow() {
        return Math.min(getPageStartRow() + currentPerPage,
                        currentRecordCount) - 1
    }
    // 添加函数来更新分页状态
    function updatePaginationState() {
        // 强制刷新表格布局
        Qt.callLater(function () {
            tableView.forceLayout()
            tableView.contentY = 0
        })
    }

    function updateRecordCount() {
        if (!tableView.model) {
            return 0
        }
        if (typeof tableView.model.totalCount !== "undefined") {
            return tableView.model.totalCount
        }
        if (typeof tableView.model.rowCount === "function") {
            return tableView.model.rowCount()
        }

        return 0
    }

    function getCurrentPageRowCount() {
        if (!tableView.model)
            return 0
        if (typeof tableView.model.currentPageRowCount !== "undefined") {
            return tableView.model.currentPageRowCount
        }
        const totalRecords = updateRecordCount()
        const rowsPerPage = pagination.rowsPerPage
        const currentPage = pagination.currentPage
        const firstRow = (currentPage - 1) * rowsPerPage
        return Math.min(rowsPerPage, totalRecords - firstRow)
    }

    // 添加到 MainPage.qml 中的函数区域
    function handleBucketSwitch(bucketName) {
        console.log("🔄 开始切换桶:", bucketName)

        // 🔥 显示加载状态
        loadingOverlay.show("objects", `正在加载 ${bucketName} 中的文件...`)

        // 🔥 立即更新界面状态
        currentBucket = bucketName

        // 🔥 清空选择状态
        tableView.clearSelection()

        // 🔥 更新左侧桶列表选择
        updateBucketListSelection(bucketName)

        // 🔥 重置面包屑导航
        breadcrumbNav.resetToRoot()
        breadcrumbNav.addPathItem(bucketName, bucketName)

        // 🔥 重置分页状态
        resetPaginationOnFolderChange()

        // 🔥 关键：先切换到对象模式，再请求数据
        switchToObjectsModelSafely(bucketName)
    }

    function handleBucketRefresh(bucketName) {
        console.log("🔄 刷新桶:", bucketName)

        loadingOverlay.show("objects", `正在刷新 ${bucketName} 中的文件...`)

        // 清空选择但保持其他状态
        tableView.clearSelection()

        // 直接刷新数据
        ManagerGlobal.refreshObjects(bucketName)
    }

    function switchToObjectsModelSafely(bucketName) {
        console.log("🔄 安全切换到对象模型:", bucketName)

        try {
            // 🔥 设置表格模式
            tableView.inBucketMode = false

            // 🔥 计算列宽
            const availableWidth = contentPanel.width
            if (availableWidth > 0) {
                rootItem.columnWidths = [Math.max(200,
                                                  availableWidth * 0.45), Math.max(
                                             150, availableWidth
                                             * 0.20), Math.max(150,
                                                               availableWidth * 0.20), Math.max(
                                             100, availableWidth * 0.15)]
            } else {
                rootItem.columnWidths = [300, 150, 150, 100]
            }

            headerBar.headerTitles = ["对象名称", "大小", "更新时间", "操作"]

            var objectsModel = ManagerGlobal.getObjectsModel()
            if (!objectsModel) {
                console.error("❌ 无法获取对象模型")
                loadingOverlay.hide()
                return
            }

            if (typeof objectsModel.clear === "function") {
                objectsModel.clear()
                console.log("✅ 已清空对象模型数据")
            }

            // 🔥 设置表格模型
            tableView.model = objectsModel

            // 🔥 重置滚动位置
            tableView.contentY = 0

            // 🔥 强制刷新布局
            tableView.forceLayout()

            // 🔥 延迟请求数据，确保界面状态已更新
            Qt.callLater(function () {
                if (rootItem.currentBucket === bucketName) {
                    console.log("🔄 开始请求桶数据:", bucketName)
                    ManagerGlobal.refreshObjects(bucketName)
                } else {
                    console.warn("⚠️ 桶已切换，取消数据请求:", bucketName)
                    loadingOverlay.hide()
                }
            })

            console.log("✅ 对象模型切换完成:", bucketName)
        } catch (error) {
            console.error("❌ 切换对象模型失败:", error)
            loadingOverlay.hide()
        }
    }

    function updateBucketListSelection(bucketName) {
        try {
            var bucketModel = ManagerGlobal.getBucketsModel()
            if (!bucketModel) {
                console.warn("无法获取桶模型")
                return
            }

            // 查找匹配的桶并设置选择
            for (var i = 0; i < bucketModel.rowCount(); i++) {
                var index = bucketModel.index(i, 0)
                var currentBucketName = bucketModel.data(index, Qt.DisplayRole)

                if (currentBucketName === bucketName) {
                    bucketListView.currentIndex = i
                    console.log("✅ 更新桶列表选择:", bucketName, "索引:", i)
                    break
                }
            }
        } catch (error) {
            console.error("❌ 更新桶列表选择失败:", error)
        }
    }

    onDownloadRequested: function (selectedItems) {
        // 首先执行这里
        console.log("下载文件请求，总项目数:", selectedItems.length)
        // 如果选中项少于等于4个，直接处理
        if (selectedItems.length <= 4) {
            for (var i = 0; i < selectedItems.length; i++) {
                addDownloadTask(selectedItems[i])
            }
            // downloadPanel.open()
            return
        }
        // downloadPanel.open()

        // 设置批处理计时器属性
        downloadBatchTimer.batchItems = selectedItems
        downloadBatchTimer.nextIndex = 0
        downloadBatchTimer.batchSize = 4

        processBatchDownloads()
    }
    // 确保有 LoadingOverlay 组件
    LoadingOverlay {
        id: loadingOverlay
        anchors.fill: parent
        z: 1000
        // active: false
    }

    // 整体布局
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // 顶部工具栏
        Rectangle {
            id: toolbar
            Layout.fillWidth: true
            height: 60
            color: "#2C3E50"

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 16
                    rightMargin: 16
                }
                spacing: 6
                // 搜索框
                HistoryTextField {
                    id: searchField
                    Layout.preferredWidth: 300
                    Layout.preferredHeight: 36
                    enableCompletion: true

                    color: "#FFFFFF" // 白色文字

                    showHistoryButton: false
                    showClearButton: true

                    background: Rectangle {
                        color: "#404040" // 深灰色背景
                        opacity: 0.9
                        radius: 4
                        border.width: 0
                        Rectangle {
                            visible: searchField.activeFocus
                            anchors.fill: parent
                            color: "transparent"
                            radius: 4
                            border.color: "#2980B9"
                            border.width: 1
                        }
                    }

                    Label {
                        visible: !searchField.text && !searchField.activeFocus
                        anchors {
                            left: parent.left
                            leftMargin: 10
                            verticalCenter: parent.verticalCenter
                        }
                        text: "搜索桶..."
                        color: "#999999"
                    }

                    onAccepted: {
                        if (text.length > 0) {
                            searchRequested(text)
                        }
                    }

                    // 处理补全项选择
                    onCompletionItemSelected: function (value) {
                        console.log("选择了补全项:", value)
                        searchRequested(value)
                    }

                    onHistoryItemSelected: function (value) {
                        console.log("选择了历史记录:", value)
                        searchRequested(value)

                        // 选择对应桶对象表格
                        var success = selectBucketByName(value)
                        if (!success) {
                            console.log("首次选择失败，刷新桶列表后重试...")
                            ManagerGlobal.refreshBuckets()
                            Qt.callLater(function () {
                                var retrySuccess = selectBucketByName(value)
                                if (!retrySuccess) {
                                    console.error("重试后仍无法找到桶:", value)
                                }
                            })
                        }
                    }
                }
                // 占位符
                Item {
                    Layout.fillWidth: true
                }
                RowLayout {
                    spacing: 6
                    Button {
                        id: switchBucketListButton
                        text: "桶列表"
                        Layout.preferredWidth: 72
                        Layout.preferredHeight: 50
                        // 修复后的内容布局
                        contentItem: Rectangle {
                            color: "transparent" // 透明背景
                            Text {
                                id: buttonText
                                text: switchBucketListButton.text
                                anchors.centerIn: parent // 绝对居中
                                font.pixelSize: 14
                                color: "#FFFFFF"
                            }
                        }
                        background: Rectangle {
                            color: switchBucketListButton.hovered ? "#3498DB" : "#2980B9"
                            radius: 4
                        }
                        onClicked: {
                            console.log("桶列表按钮点击")
                            rootItem.currentBucket = ""
                            tableView.clearSelection()
                            switchToBucketsModel()
                            breadcrumbNav.clearModel()
                            breadcrumbNav.resetToRoot()
                            bucketListView.currentIndex = -1
                        }
                    }
                    Button {
                        id: refreshButton
                        text: qsTr("刷新")
                        Layout.preferredWidth: 70
                        Layout.preferredHeight: 50
                        property bool isRefreshing: false
                        // 修复后的内容布局 - 使用Item作为顶层容器
                        contentItem: Item {
                            anchors.fill: parent
                            RowLayout {
                                anchors.centerIn: parent
                                width: parent.width - 10
                                height: parent.height
                                spacing: 3
                                Item {
                                    Layout.fillWidth: true
                                }

                                // 刷新图标容器
                                Item {
                                    Layout.preferredWidth: 16
                                    Layout.preferredHeight: 16
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        id: refreshIcon
                                        text: "⟳" // 使用Unicode刷新符号
                                        font.pixelSize: 14
                                        color: "#FFFFFF"
                                        anchors.centerIn: parent
                                        transformOrigin: Item.Center

                                        RotationAnimation {
                                            id: rotationAnimation
                                            target: refreshIcon
                                            from: 0
                                            to: 360
                                            duration: 1500
                                            loops: Animation.Infinite
                                            running: refreshButton.isRefreshing
                                        }
                                    }
                                }

                                // 刷新文本
                                Text {
                                    text: refreshButton.isRefreshing ? "刷新中..." : refreshButton.text
                                    font.pixelSize: refreshButton.isRefreshing ? 11 : 13
                                    color: "#FFFFFF"
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                // 添加右侧填充确保水平居中
                                Item {
                                    Layout.fillWidth: true
                                }
                            }
                        }
                        background: Rectangle {
                            color: refreshButton.hovered ? "#3498DB" : "#2980B9"
                            radius: 4

                            // 添加波纹效果
                            Rectangle {
                                id: refreshRipple
                                anchors.centerIn: parent
                                width: 0
                                height: 0
                                radius: width / 2
                                color: "#FFFFFF"
                                opacity: 0

                                // 波纹动画
                                NumberAnimation {
                                    id: rippleAnimation
                                    targets: [refreshRipple]
                                    properties: "width,height"
                                    from: 0
                                    to: refreshButton.width * 2
                                    duration: 500
                                    easing.type: Easing.OutQuad
                                    running: false
                                    onFinished: refreshRipple.opacity = 0
                                }

                                // 透明度动画
                                NumberAnimation {
                                    id: opacityAnimation
                                    target: refreshRipple
                                    property: "opacity"
                                    from: 0.3
                                    to: 0
                                    duration: 500
                                    easing.type: Easing.OutQuad
                                    running: false
                                }
                            }
                        }
                        // 按钮点击事件
                        onClicked: {
                            // 防止重复点击
                            if (isRefreshing) {
                                return
                            }
                            // 播放波纹动画
                            refreshRipple.opacity = 0.3
                            rippleAnimation.start()
                            opacityAnimation.start()
                            // 设置刷新状态，开始旋转
                            isRefreshing = true
                            // 记录刷新开始时间
                            refreshStartTime = Date.now()
                            // 根据当前模式执行不同的刷新
                            if (tableView.inBucketMode) {
                                // 如果当前是桶模式，刷新桶列表
                                console.log("刷新桶列表")
                                ManagerGlobal.refreshBuckets()
                            } else if (rootItem.currentBucket) {
                                // 回到根目录下
                                breadcrumbNav.resetToRoot()
                                console.log("刷新当前桶中的对象:",
                                            rootItem.currentBucket)
                                ManagerGlobal.refreshObjects(
                                            rootItem.currentBucket)
                                breadcrumbNav.addPathItem(
                                            rootItem.currentBucket,
                                            rootItem.currentBucket)
                            } else {
                                // 默认刷新桶列表
                                console.log("刷新桶列表")
                                ManagerGlobal.refreshBuckets()
                            }
                            // 确保刷新状态最终会被重置，即使没有收到完成信号
                            refreshTimer.start()
                        }
                        // 定义刷新开始时间以确保最小刷新持续时间
                        property var refreshStartTime: null
                        // 定时器控制刷新动画时长
                        Timer {
                            id: refreshTimer
                            interval: 1500 // 刷新动画最短持续1.5秒
                            repeat: false
                            onTriggered: {
                                // 计算已经过去的刷新时间
                                const elapsedTime = Date.now(
                                                      ) - (refreshButton.refreshStartTime
                                                           || Date.now())

                                // 如果已经过去足够长的时间，重置刷新状态
                                if (elapsedTime >= 1000) {
                                    refreshButton.isRefreshing = false
                                } else {
                                    // 否则等待剩余时间后再重置
                                    interval = 1000 - elapsedTime
                                    start()
                                }
                            }
                        }

                        // 添加工具提示
                        ToolTip.visible: hovered && !isRefreshing
                        ToolTip.text: qsTr("刷新当前视图")
                        ToolTip.delay: 500

                        // 刷新完成处理
                        Connections {
                            target: ManagerGlobal
                            // 辅助函数确保刷新状态正确重置
                            function finishRefreshing() {
                                const elapsedTime = Date.now(
                                                      ) - (refreshButton.refreshStartTime
                                                           || Date.now())

                                // 确保动画至少显示一段最短时间
                                if (elapsedTime < 800) {
                                    // 如果时间太短，延迟重置刷新状态
                                    refreshTimer.interval = 800 - elapsedTime
                                    refreshTimer.start()
                                } else {
                                    // 已经过了足够长的时间，可以立即重置
                                    refreshButton.isRefreshing = false
                                }
                            }
                        }
                    }
                    // 上传按钮
                    Button {
                        id: uploadButton
                        text: "上传文件"
                        Layout.preferredWidth: 80
                        Layout.preferredHeight: 50
                        icon.source: "qrc:/resources/icon/upload.png"
                        icon.color: "transparent"
                        contentItem: Item {
                            anchors.fill: parent

                            RowLayout {
                                anchors.centerIn: parent
                                width: Math.min(parent.width - 12,
                                                70) // 确保内容不超出按钮边界
                                height: parent.height
                                spacing: 4

                                Image {
                                    source: "qrc:/resources/icon/upload.png"
                                    Layout.preferredWidth: 14
                                    Layout.preferredHeight: 14
                                    Layout.alignment: Qt.AlignVCenter
                                    fillMode: Image.PreserveAspectFit
                                    visible: source != ""
                                }

                                Text {
                                    text: uploadButton.text
                                    font.pixelSize: 12 // 减小字体大小以适应按钮
                                    color: "#FFFFFF"
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.fillWidth: true
                                    // eorizontalAlignment: Text.AlignHCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight // 如果文字太长则省略
                                    wrapMode: Text.NoWrap
                                }
                            }
                        }

                        background: Rectangle {
                            color: uploadButton.hovered ? "#3498DB" : "#2980B9"
                            radius: 4
                            // 确保背景完全包含内容
                            implicitWidth: uploadButton.Layout.preferredWidth
                            implicitHeight: uploadButton.Layout.preferredHeight
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                // console.log("点击上传按钮")
                                rootItem.uploadRequested()
                            }
                        }
                    }

                    // 下载按钮
                    Button {
                        id: downloadButton
                        text: "下载"
                        Layout.preferredWidth: 70 // 固定宽度
                        Layout.preferredHeight: 50
                        enabled: tableView.selectedItems
                                 && tableView.selectedItems.length > 0
                        contentItem: Item {
                            anchors.fill: parent
                            RowLayout {
                                anchors.centerIn: parent
                                width: parent.width - 10
                                height: parent.height
                                spacing: 3
                                Item {
                                    Layout.fillWidth: true
                                }
                                Image {
                                    source: "qrc:/resources/icon/download.png"
                                    Layout.preferredWidth: 14
                                    Layout.preferredHeight: 14
                                    Layout.alignment: Qt.AlignVCenter
                                    fillMode: Image.PreserveAspectFit
                                }

                                Text {
                                    text: downloadButton.text
                                    font.pixelSize: 13
                                    color: "#FFFFFF"
                                    opacity: downloadButton.enabled ? 1.0 : 0.5
                                    Layout.alignment: Qt.AlignVCenter
                                }
                                Item {
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        background: Rectangle {
                            color: downloadButton.enabled ? (downloadButton.hovered ? "#27AE60" : "#2ECC71") : "#7F8C8D"
                            radius: 4
                        }
                        onClicked: {
                            downloadRequested(tableView.selectedItems)
                        }
                    }
                    Button {
                        id: transferManagerButton
                        text: "传输管理"
                        Layout.preferredWidth: 85
                        Layout.preferredHeight: 50
                        contentItem: Item {
                            anchors.fill: parent
                            RowLayout {
                                anchors.centerIn: parent
                                width: Math.min(parent.width - 12, 70)
                                height: parent.height
                                spacing: 4
                                Text {
                                    text: "📊"
                                    font.pixelSize: 13
                                    color: "#FFFFFF"
                                }

                                Text {
                                    text: transferManagerButton.text
                                    font.pixelSize: 12
                                    color: "#FFFFFF"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }

                        background: Rectangle {
                            color: transferManagerButton.hovered ? "#3498DB" : "#2980B9"
                            radius: 4
                            // 确保背景完全包含内容
                            implicitWidth: transferManagerButton.Layout.preferredWidth
                            implicitHeight: transferManagerButton.Layout.preferredHeight
                        }

                        // MouseArea {
                        //     // 点击无效
                        //     cursorShape: Qt.PointingHandCursor
                        //     onClicked: openTransferManager()
                        // }
                        onClicked: openTransferManager()

                        TtToolTip {
                            visible: parent.hovered
                            text: qsTr("打开传输管理器 (Ctrl+T)")
                            delay: 500
                            arrowPosition: "auto"
                        }
                    }
                    // Button {
                    //     id: downloadManagerButton
                    //     text: "下载管理"
                    //     Layout.preferredWidth: 85
                    //     Layout.preferredHeight: 50

                    //     contentItem: Rectangle {
                    //         color: "transparent"

                    //         Row {
                    //             anchors.centerIn: parent
                    //             spacing: 5
                    //             Image {
                    //                 width: 14
                    //                 height: 14
                    //                 anchors.verticalCenter: parent.verticalCenter
                    //                 source: "qrc:/resources/icon/download.png"
                    //                 fillMode: Image.PreserveAspectFit
                    //             }
                    //             Text {
                    //                 text: downloadManagerButton.text
                    //                 font.pixelSize: 13
                    //                 color: "#FFFFFF"
                    //                 anchors.verticalCenter: parent.verticalCenter
                    //             }
                    //             Rectangle {
                    //                 width: 16
                    //                 height: 16
                    //                 radius: 8
                    //                 color: "#EF4444"
                    //                 visible: getActiveDownloadCount() > 0
                    //                 anchors.verticalCenter: parent.verticalCenter

                    //                 Text {
                    //                     anchors.centerIn: parent
                    //                     text: getActiveDownloadCount()
                    //                     font.pixelSize: 9
                    //                     font.bold: true
                    //                     color: "white"
                    //                 }
                    //             }
                    //         }
                    //     }

                    //     background: Rectangle {
                    //         color: downloadManagerButton.hovered ? "#3498DB" : "#2980B9"
                    //         radius: 4
                    //     }

                    //     onClicked: {
                    //         if (!downloadWindow) {
                    //             createDownloadWindow()
                    //         }
                    //         downloadWindow.visible = true
                    //     }

                    //     // 保留工具提示
                    //     ToolTip.visible: hovered
                    //     ToolTip.text: "下载管理"
                    //     ToolTip.delay: 500
                    // }
                    Button {
                        id: moreButton
                        text: "操作"
                        Layout.preferredWidth: 70
                        Layout.preferredHeight: 50
                        contentItem: RowLayout {
                            spacing: 3
                            Text {
                                text: moreButton.text
                                font.pixelSize: 13
                                color: "#FFFFFF"
                            }
                            Text {
                                text: "▼"
                                font.pixelSize: 9
                                color: "#FFFFFF"
                            }
                        }

                        background: Rectangle {
                            color: moreButton.hovered ? "#34495E" : "#2C3E50"
                            radius: 4
                            border.color: "#7F8C8D"
                            border.width: 1
                        }

                        onClicked: operationsMenu.popup()

                        TtMenu {
                            id: operationsMenu
                            MenuItem {
                                text: "新建文件夹"
                                onTriggered: console.log("新建文件夹")
                            }
                            MenuItem {
                                text: "重命名"
                                enabled: tableView.selectedItems
                                         && tableView.selectedItems.length === 1
                                onTriggered: console.log("重命名")
                            }
                            MenuItem {
                                text: "删除"
                                enabled: tableView.selectedItems
                                         && tableView.selectedItems.length > 0
                                onTriggered: console.log("删除")
                            }
                        }
                    }
                    Button {
                        id: settingsButton
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        background: Item {
                            anchors.fill: parent

                            Rectangle {
                                anchors.centerIn: parent
                                property real size: Math.min(parent.width,
                                                             parent.height) - 6
                                width: size
                                height: size
                                radius: width / 2
                                color: "#3498DB"
                                opacity: settingsButton.hovered ? 0.2 : 0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 150
                                    }
                                }
                            }
                        }
                        contentItem: Item {
                            anchors.fill: parent
                            Text {
                                leftPadding: 1
                                id: settingsIcon
                                anchors.centerIn: parent
                                text: "⚙️"
                                font.pixelSize: 16
                                color: "#FFFFFF"
                                RotationAnimation {
                                    id: settingRotationAnimation
                                    target: settingsIcon
                                    from: 0
                                    to: 90
                                    duration: 300
                                    running: false
                                }
                            }
                        }
                        onPressed: {
                            settingRotationAnimation.start()
                        }
                        onClicked: {
                            settingsMenu.popup()
                        }
                        TtMenu {
                            id: settingsMenu
                            animationType: TtMenu.AnimationType.Elegant
                            MenuItem {
                                text: qsTr("账号设置")
                                onTriggered: {
                                    console.log("账号设置")
                                }
                            }
                            MenuItem {
                                text: qsTr("偏好设置")
                                onTriggered: {
                                    var component = Qt.createComponent(
                                                "PreferencesDialog.qml")
                                    if (component.status === Component.Ready) {
                                        var dialog = component.createObject(
                                                    rootItem)
                                        dialog.settingsApplied.connect(
                                                    function () {
                                                        // console.log("设置已应用")
                                                        if (dialog.downloadPath
                                                                && dialog.downloadPath !== "") {
                                                            ManagerGlobal.setDownloadDirectory(
                                                                        dialog.downloadPath)
                                                            console.log("下载目录已更新为:",
                                                                        dialog.downloadPath)
                                                        }
                                                        //  // 如果有其他下载相关设置，在这里处理
                                                        // if (dialog.maxDownloadSpeed !== undefined) {
                                                        //     ManagerGlobal.setMaxDownloadSpeed(dialog.maxDownloadSpeed)
                                                        // }
                                                    })
                                        dialog.visible = true
                                    } else {
                                        console.error("无法加载偏好设置对话框:",
                                                      component.errorString())
                                    }
                                }
                            }
                            MenuSeparator {}
                            MenuItem {
                                text: qsTr("退出登录")
                                onTriggered: {
                                    console.log("退出登录")
                                    rootItem.logoutRequested()
                                }
                            }
                        }

                        // 添加工具提示
                        ToolTip.visible: hovered
                        ToolTip.text: qsTr("设置")
                        ToolTip.delay: 500
                    }
                }
            }
        }

        // 主内容区
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            TtSplitView {
                anchors.fill: parent
                // 左侧导航面板
                Rectangle {
                    id: navPanel
                    SplitView.preferredWidth: 190
                    SplitView.minimumWidth: 150
                    SplitView.maximumWidth: 300
                    color: "#2D3436"

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0
                        // 导航标题
                        Rectangle {
                            Layout.fillWidth: true
                            height: 30
                            color: "#1E272E"
                            Label {
                                anchors {
                                    left: parent.left
                                    leftMargin: 16
                                    verticalCenter: parent.verticalCenter
                                }
                                text: "存储桶"
                                color: "#FFFFFF"
                                font.pixelSize: 16
                                // font.bold: true
                            }
                        }
                        // 左侧文件列表
                        ListView {
                            id: bucketListView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: {
                                // 这里获取了一次
                                console.log("构造 左侧 bucket 时调用获取桶模型")
                                // 初始时获取 ???
                                return ManagerGlobal.getBucketsModel()
                            }
                            currentIndex: -1
                            Component.onCompleted: {
                                // 刷新桶表
                                console.log("左侧列表刷新桶, 再未登录之前")
                                ManagerGlobal.refreshBuckets()
                            }
                            delegate: ItemDelegate {
                                id: folderItem
                                width: bucketListView.width
                                height: 50
                                highlighted: ListView.isCurrentItem

                                background: Rectangle {
                                    color: folderItem.highlighted ? "#34495E" : folderItem.hovered ? "#2C3E50" : "transparent"
                                }
                                RowLayout {
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        leftMargin: 16
                                        rightMargin: 10
                                        verticalCenter: parent.verticalCenter
                                    }
                                    spacing: 12
                                    Rectangle {
                                        width: 24
                                        height: 24
                                        color: "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: "🪣"
                                            font.pixelSize: 18
                                            color: "#F0F0F0"
                                        }
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        text: model.display || ""
                                        font.pixelSize: 14
                                        color: "#F0F0F0"
                                        elide: Text.ElideRight
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    propagateComposedEvents: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: function (mouse) {
                                        if (mouse.button === Qt.RightButton) {
                                            folderContextMenu.folderData = modelData
                                            folderContextMenu.folderIndex = index
                                            folderContextMenu.popup()
                                        }
                                        mouse.accepted = false
                                    }
                                    onDoubleClicked: function (mouse) {
                                        if (mouse.button === Qt.LeftButton) {

                                            if (model.display === currentBucket) {
                                                if (model.display !== breadcrumbNav.getCurrentPath(
                                                            )) {
                                                    breadcrumbNav.resetToRoot()
                                                    breadcrumbNav.addPathItem(
                                                                model.display,
                                                                model.display)
                                                    switchToObjectsModel(
                                                                model.display)
                                                    mouse.accepted = true
                                                } else {
                                                    switchToObjectsModel(
                                                                model.display)
                                                    mouse.accepted = true
                                                }
                                                return
                                            }
                                            breadcrumbNav.resetToRoot()
                                            var bucketName = model.display
                                            currentBucket = bucketName
                                            bucketListView.currentIndex = index
                                            breadcrumbNav.addPathItem(
                                                        bucketName, bucketName)
                                            switchToObjectsModel(bucketName)
                                            resetPaginationOnFolderChange()
                                            mouse.accepted = true
                                        }
                                    }
                                    // 添加文件夹上下文菜单
                                    TtMenu {
                                        id: folderContextMenu
                                        property var folderData: null
                                        property int folderIndex: -1
                                        MenuItem {
                                            text: qsTr("编辑")
                                            onTriggered: {
                                                console.log("编辑文件夹:",
                                                            folderContextMenu.folderData ? folderContextMenu.folderData.name : "未知")
                                                // 实现文件夹编辑逻辑
                                                // TODO 修改桶名
                                            }
                                        }

                                        MenuItem {
                                            text: qsTr("删除桶")
                                            onTriggered: {
                                                console.log("删除桶:",
                                                            folderContextMenu.folderData ? folderContextMenu.folderData.name : "未知")
                                                ManagerGlobal.deleteBucket(
                                                            folderContextMenu.folderData ? folderContextMenu.folderData.name : "")
                                                console.log(folderContextMenu.folderData.name)
                                            }
                                        }
                                    }
                                }
                            }
                            ScrollIndicator.vertical: ScrollIndicator {}
                        }
                    }
                }
                // 右侧内容区
                Rectangle {
                    id: contentPanel
                    SplitView.fillWidth: true
                    SplitView.preferredWidth: parent.width - navPanel.width // 添加优先宽度
                    color: "#FFFFFF"
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0
                        // 面包屑导航栏
                        TtBreadcrumbNav {
                            id: breadcrumbNav
                            Layout.fillWidth: true
                            m_model: breadcrumbPathData
                            // 连接信号
                            onPathItemClicked: function (itemId) {
                                console.log("面包屑导航：选择路径项, currentBucket: ",
                                            itemId, currentBucket)
                                if (itemId === "root") {
                                    // 点击了根图标
                                    console.log("点击了根图标，清除当前模型数据, 切换为桶模型")
                                    // 2. 清空当前桶名
                                    rootItem.currentBucket = ""
                                    // 3. 清除表格所有选中项
                                    tableView.clearSelection()
                                    // 4. 重要: 切换表格模型为桶模型
                                    switchToBucketsModel()
                                    // 可选：切换回桶列表视图
                                    bucketListView.currentIndex = -1
                                    // 重置分页状态 触发一次
                                } else if (itemId === rootItem.currentBucket) {
                                    // 点击的是桶名, 刷新当前桶名
                                    ManagerGlobal.refreshObjects(
                                                rootItem.currentBucket)
                                } else {
                                    // test_dir 不同, 获取的 test_dir 应该需要夹/
                                    // 如果点击的是路径中的某个文件夹
                                    ManagerGlobal.refreshObjects(
                                                rootItem.currentBucket, itemId)
                                }
                                resetPaginationOnFolderChange()
                            }
                        }
                        Rectangle {
                            width: parent.width
                            height: 1
                            Rectangle {
                                color: "lightblue"
                            }
                        }

                        Rectangle {
                            id: headerBar
                            Layout.fillWidth: true
                            height: 40
                            color: "#F5F6FA"
                            property var headerTitles: tableView.inBucketMode ? [qsTr("桶名称"), qsTr("区域"), qsTr("创建时间")] : [qsTr("对象名称"), qsTr("大小"), qsTr("更新时间"), qsTr("操作")]
                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: 0
                                    rightMargin: 0
                                }
                                spacing: 0
                                // 对象名称
                                Rectangle {
                                    Layout.preferredWidth: rootItem.columnWidths[0]
                                    Layout.fillHeight: true
                                    color: "#F0F4F8" // 稍微不同的背景色

                                    Label {
                                        anchors.centerIn: parent
                                        text: headerBar.headerTitles[0]
                                        font.bold: true
                                    }
                                    // 右侧边框
                                    Rectangle {
                                        width: 1
                                        height: parent.height
                                        anchors.right: parent.right
                                        color: "#E0E0E0" // 边框颜色
                                    }
                                }

                                // 大小
                                Rectangle {
                                    Layout.preferredWidth: rootItem.columnWidths[1]
                                    Layout.fillHeight: true
                                    color: "#F0F4F8" // 稍微不同的背景色
                                    Label {
                                        anchors.centerIn: parent
                                        text: headerBar.headerTitles[1]
                                        font.bold: true
                                    }
                                    // 右侧边框
                                    Rectangle {
                                        width: 1
                                        height: parent.height
                                        anchors.right: parent.right
                                        color: "#E0E0E0" // 边框颜色
                                    }
                                }

                                // 修改时间
                                Rectangle {
                                    Layout.preferredWidth: rootItem.columnWidths[2]
                                    Layout.fillHeight: true
                                    color: rootItem.sortColumn == 2 ? "#E3F2FD" : "#F0F4F8"
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (rootItem.sortColumn == 3) {
                                                rootItem.sortAscending = !rootItem.sortAscending
                                            } else {
                                                rootItem.sortColumn = 3
                                                rootItem.sortAscending = true
                                            }
                                            sortByColumn(3,
                                                         rootItem.sortAscending)
                                        }
                                    }
                                    RowLayout {
                                        anchors {
                                            fill: parent
                                            leftMargin: 0
                                            rightMargin: 0
                                            verticalCenter: parent.verticalCenter
                                        }
                                        spacing: 4
                                        Item {
                                            Layout.fillWidth: true
                                        } // 左侧弹性空间

                                        Label {
                                            Layout.alignment: Qt.AlignVCenter
                                            text: headerBar.headerTitles[2]
                                            font.bold: true
                                        }

                                        // 排序指示器
                                        Label {
                                            Layout.alignment: Qt.AlignVCenter
                                            visible: rootItem.sortColumn == 3
                                            text: rootItem.sortAscending ? "▲" : "▼"
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: "#2980B9"
                                        }
                                        Item {
                                            Layout.fillWidth: true
                                        } // 右侧弹性空间
                                    }
                                }
                                Rectangle {
                                    Layout.preferredWidth: !tableView.inBucketMode
                                                           && rootItem.columnWidths.length
                                                           > 3 ? rootItem.columnWidths[3] : 0
                                    Layout.fillHeight: true
                                    color: "#F0F4F8"
                                    visible: !tableView.inBucketMode // 只有在对象模式中才显示操作列

                                    Label {
                                        anchors.centerIn: parent
                                        text: headerBar.headerTitles[3] || ""
                                        font.bold: true
                                    }
                                }
                            }
                        }
                        ScrollView {
                            id: tableScrollView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            ScrollBar.vertical: ScrollBar {
                                id: verticalScrollBar
                                width: 10
                                background: Rectangle {
                                    color: "transparent"
                                }
                                contentItem: Rectangle {
                                    implicitWidth: 8
                                    radius: 4
                                    color: verticalScrollBar.hovered ? "#808080" : "#C0C0C0"
                                    opacity: verticalScrollBar.active ? 0.8 : 0.4
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 100
                                        }
                                    }
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 100
                                        }
                                    }
                                }
                            }
                            ScrollBar.horizontal: ScrollBar {
                                id: horizontalScrollBar
                                policy: ScrollBar.AsNeeded
                                height: 8
                                padding: 0
                                background: Rectangle {
                                    color: "transparent"
                                }
                                contentItem: Rectangle {
                                    implicitHeight: 8
                                    radius: 4
                                    color: horizontalScrollBar.hovered ? "#808080" : "#C0C0C0"
                                    opacity: horizontalScrollBar.active ? 0.8 : 0.4
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 100
                                        }
                                    }
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 100
                                        }
                                    }
                                }
                            }

                            TableView {
                                id: tableView
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                property bool inBucketMode: true // 默认是桶属性
                                // 编辑
                                property int editingRow: -1
                                property int editingColumn: -1
                                model: tableView.inBucketMode ? ManagerGlobal.getBucketsModel(
                                                                    ) : ManagerGlobal.getObjectsModel()
                                Behavior on contentY {
                                    enabled: false // 禁用滚动动画，优化性能
                                }
                                // 在 TableView 中添加
                                Connections {
                                    target: tableView.model

                                    function onDataChanged(topLeft, bottomRight, roles) {
                                        // console.info("模型数据已更新")
                                        try {
                                            tableView.forceLayout()
                                            // 更新记录数
                                            rootItem.updateRecordCount()
                                        } catch (e) {
                                            console.error("更新视图失败:", e)
                                        }
                                        const oldCount = rootItem.currentRecordCount
                                        rootItem.currentRecordCount = updateRecordCount()
                                        if (oldCount !== rootItem.currentRecordCount) {
                                            console.log("记录数已变化，更新分页状态")
                                            updatePaginationState()
                                        }
                                    }
                                    function onModelReset() {
                                        // console.log("模型重置")
                                        rootItem.currentRecordCount = updateRecordCount()
                                        updatePaginationState()
                                    }

                                    function onRowsInserted() {
                                        // console.log("行被插入")
                                        rootItem.updateRecordCount() // 更新记录数
                                    }

                                    function onRowsRemoved() {
                                        rootItem.updateRecordCount() // 更新记录数
                                    }
                                }
                                function sortByColumn(column, ascending) {
                                    let rows = []
                                    for (var i = 0; i < tableModel.rowCount; i++) {
                                        rows.push(tableModel.getRow(i))
                                    }
                                    rows.sort(function (a, b) {
                                        let valueA, valueB
                                        if (column === 1) {
                                            valueA = a.name ? a.name.toLowerCase(
                                                                  ) : ""
                                            valueB = b.name ? b.name.toLowerCase(
                                                                  ) : ""
                                        } else if (column === 2) {
                                            valueA = a.zone ? a.zone.toLowerCase(
                                                                  ) : ""
                                            valueB = b.zone ? b.zone.toLowerCase(
                                                                  ) : ""
                                        } else if (column === 3) {
                                            valueA = rootItem.parseDateString(
                                                        a.date)
                                            valueB = rootItem.parseDateString(
                                                        b.date)
                                        } else {
                                            return 0
                                        }
                                        if (ascending) {
                                            if (valueA < valueB)
                                                return -1
                                            if (valueA > valueB)
                                                return 1
                                            return 0
                                        } else {
                                            if (valueA > valueB)
                                                return -1
                                            if (valueA < valueB)
                                                return 1
                                            return 0
                                        }
                                    })
                                    tableModel.clear()
                                    for (var i = 0; i < rows.length; i++) {
                                        tableModel.appendRow(rows[i])
                                    }
                                }
                                columnWidthProvider: function (column) {
                                    try {
                                        if (column < 0
                                                || !rootItem.columnWidths) {
                                            return 0
                                        }
                                        if (column === 3) {
                                            if (tableView.inBucketMode) {
                                                return 0
                                            } else {
                                                var width = rootItem.columnWidths.length
                                                        > 3 ? rootItem.columnWidths[3] : 100
                                                return width
                                            }
                                        }

                                        // 其他列
                                        if (column >= rootItem.columnWidths.length)
                                            return 0

                                        return rootItem.columnWidths[column]
                                    } catch (e) {
                                        console.warn("列宽计算错误:", e)
                                        return 0
                                    }
                                }
                                rowHeightProvider: function (row) {
                                    try {
                                        if (!model) {
                                            return 0
                                        }
                                        // 检查模型是否有效
                                        if (typeof model.rowCount !== 'function') {
                                            return 0
                                        }

                                        // 严格检查行是否在有效范围内
                                        const rowCount = model.rowCount()
                                        if (row < 0 || row >= rowCount) {
                                            return 0
                                        }
                                        // 使用函数获取最新的分页范围值
                                        const isInCurrentPage = row >= rootItem.getPageStartRow()
                                                              && row <= rootItem.getPageEndRow()
                                        // console.log("start end: ",
                                        //             rootItem.pageStartRow,
                                        //             rootItem.pageEndRow)

                                        // 如果不在当前页，返回高度0（实际隐藏该行）
                                        if (!isInCurrentPage) {
                                            // console.log("行不在当前页范围内，返回高度0:",
                                            //             row,
                                            //             rootItem.getPageStartRow(
                                            //                 ),
                                            //             rootItem.getPageEndRow(
                                            //                 ))
                                            return 0
                                        }
                                        // console.log("计算行高:", row, "在当前页内:",
                                        //             isInCurrentPage)

                                        // 否则返回标准行高
                                        return 50
                                    } catch (e) {
                                        console.warn("行高计算错误:", e)
                                        return 0
                                    }
                                }
                                function isValidRow(row) {
                                    if (!tableView.model) {
                                        return false
                                    }
                                    return row >= rootItem.getPageStartRow()
                                            && row <= rootItem.getPageEndRow()
                                }
                                property var selectedItems: []
                                delegate: DelegateChooser {
                                    // 基于列号的委托
                                    role: "column"
                                    // 对象名称
                                    DelegateChoice {
                                        column: 0
                                        delegate: Rectangle {
                                            id: nameCell
                                            width: tableView.columnWidthProvider(
                                                       0)
                                            implicitWidth: tableView.columnWidthProvider(
                                                               0)
                                            property bool isEditing: tableView.editingRow === row
                                                                     && tableView.editingColumn
                                                                     === 1
                                            // 行范围检查函数
                                            visible: tableView.isValidRow(row)
                                            // 添加动态属性，使用函数而不是绑定表达式，确保每次访问都重新计算
                                            function isFolderType() {
                                                try {
                                                    // 获取当前行数据
                                                    // const rowData = tableView.adapterModel ? tableView.adapterModel.getRow(row) : null
                                                    // 拿到索引
                                                    var idx = tableView.model.index(
                                                                row, 0)
                                                    // BUG 索引也是不对的
                                                    if (idx && idx.isValid) {
                                                        // 2) 用 Qt.UserRole 取出 C++ 那个 QVariantMap
                                                        console.log("正常的索引")
                                                        var userData = tableView.model.data(
                                                                    idx,
                                                                    Qt.UserRole)
                                                        if (userData
                                                                && userData.isFolder
                                                                !== undefined) {
                                                            return userData.isFolder // 一定要 return
                                                        }
                                                    } else {

                                                        // 这里也会输出
                                                        // console.log("获取不正常的索引")
                                                    }

                                                    // 3) 回退：文件名末尾带斜杠就当作文件夹
                                                    var name = model.display
                                                            || ""
                                                    return name.endsWith("/")
                                                } catch (e) {
                                                    console.error("判断文件夹错误:", e)
                                                    return false
                                                }
                                            }
                                            property bool isItemSelected: {
                                                try {
                                                    if (!tableView.selectedItems)
                                                        return false
                                                    // 使用直接的 row 标识符而不依赖于 tableModel
                                                    return tableView.selectedItems.some(
                                                                item => item.id === "obj" + row)
                                                } catch (e) {
                                                    console.error(
                                                                "Error checking selection:",
                                                                e)
                                                    return false
                                                }
                                            }
                                            color: isItemSelected ? "#E3F2FD" : "#FFFFFF"
                                            implicitHeight: 50
                                            RowLayout {
                                                anchors {
                                                    fill: parent
                                                    leftMargin: 8
                                                    rightMargin: 8
                                                }
                                                spacing: 8
                                                Text {
                                                    id: fileIcon
                                                    text: {
                                                        if (tableView.inBucketMode) {
                                                            return "🪣"
                                                        } else {
                                                            return nameCell.isFolderType(
                                                                        ) ? "📁" : "📄"
                                                        }
                                                    }
                                                    font.pixelSize: 18
                                                    color: {
                                                        if (tableView.inBucketMode) {
                                                            return "#1E88E5" // 桶图标颜色
                                                        } else {
                                                            return nameCell.isFolderType(
                                                                        ) ? "#2980B9" : "#333333"
                                                        }
                                                    }
                                                    Layout.preferredWidth: 24
                                                }
                                                Text {
                                                    id: cellText
                                                    Layout.fillWidth: true
                                                    text: {
                                                        let name = model.display
                                                            || "未命名"
                                                        return nameCell.isFolderType()
                                                                && name.endsWith(
                                                                    '/') ? name.substring(0, name.length - 1) : name
                                                    }
                                                    elide: Text.ElideRight
                                                    visible: !nameCell.isEditing
                                                    color: nameCell.isFolderType(
                                                               ) ? "#2980B9" : "#333333"
                                                    font.bold: nameCell.isFolderType()
                                                    font.underline: nameCell.isFolderType()
                                                }
                                                // 添加模型变更监听
                                                Component.onCompleted: {

                                                }
                                            }
                                            // 处理点击事件
                                            MouseArea {
                                                id: mouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                cursorShape: Qt.PointingHandCursor
                                                propagateComposedEvents: !nameCell.isEditing
                                                property var root: rootItem
                                                onClicked: function (mouse) {
                                                    console.log("Clicked on row",
                                                                row)
                                                    try {
                                                        // 如果当前是桶模型模式，点击处理不同
                                                        if (tableView.inBucketMode) {
                                                            if (mouse.button === Qt.LeftButton) {
                                                                // 获取桶名
                                                                const bucketName = model.display
                                                                // 普通点击只是选择，不导航
                                                                tableView.clearSelection()
                                                            } else if (mouse.button
                                                                       === Qt.RightButton) {
                                                                bucketContextMenu.bucketName
                                                                        = model.display
                                                                bucketContextMenu.rowIndex = row
                                                                bucketContextMenu.popup()
                                                            }
                                                        } else {
                                                            const isFolder = nameCell.isFolderType()
                                                            // 这里保存对应的行信息
                                                            if (mouse.button === Qt.LeftButton) {
                                                                // 左键点击
                                                                if (mouse.modifiers
                                                                        & Qt.ControlModifier) {
                                                                    // 构建行信息
                                                                    const rowData = {
                                                                        "id": "obj" + row,
                                                                        "name": display
                                                                    }
                                                                    // 从模型中获取 UserRole 数据
                                                                    // 这里获取的 idx 是有效的 ???
                                                                    var idx = tableView.model.index(
                                                                                row, 0)
                                                                    if (idx && idx.valid) {
                                                                        console.log("有效的 idx")
                                                                        var userData = tableView.model.data(idx, Qt.UserRole)
                                                                        if (userData) {
                                                                            // 添加下载所需的关键信息
                                                                            rowData.key = userData.key || ""
                                                                            rowData.size = userData.size || 0
                                                                            rowData.isFolder = userData.isFolder || false
                                                                            rowData.lastModified = userData.lastModified || ""
                                                                        }
                                                                    }
                                                                    // 上面是无效的
                                                                    // 如果没有获取到 key，使用 name 作为备选
                                                                    if (!rowData.key) {
                                                                        rowData.key = rowData.name
                                                                    }
                                                                    // 获取的 key 是完整路径
                                                                    console.log("Ctrl+点击选择项目:",
                                                                                rowData.name,
                                                                                "key:",
                                                                                rowData.key,
                                                                                "size:",
                                                                                rowData.size)
                                                                    // 添加的数据
                                                                    tableView.toggleSelection(
                                                                                rowData)
                                                                } else {
                                                                    // 普通点击: 单选
                                                                    tableView.clearSelection()
                                                                }
                                                            } else if (mouse.button
                                                                       === Qt.RightButton) {
                                                                // 右键菜单
                                                                // 出现问题, 唯有 isFolder 属性
                                                                const rowData = {
                                                                    "id": "obj" + row,
                                                                    "name": display
                                                                            || ""
                                                                }
                                                                var idx = tableView.model.index(
                                                                            row,
                                                                            0)
                                                                if (idx && idx.valid) {
                                                                    console.log("有效的 idx")
                                                                    var userData = tableView.model.data(idx, Qt.UserRole)
                                                                    if (userData) {
                                                                        // 添加下载所需的关键信息
                                                                        rowData.key = userData.key
                                                                                || ""
                                                                        // rowData.size = userData.size
                                                                        // || 0
                                                                        // rowData.isFolder = userData.isFolder || false
                                                                        // rowData.lastModified = userData.lastModified || ""
                                                                    }
                                                                }
                                                                // 上面是无效的
                                                                // 如果没有获取到 key，使用 name 作为备选
                                                                if (!rowData.key) {
                                                                    rowData.key = rowData.name
                                                                }

                                                                // 获取的 key 是完整路径
                                                                // 完整的 key
                                                                // console.log("Ctrl+点击选择项目:",
                                                                //             rowData.name,
                                                                //             "key:",
                                                                //             rowData.key,
                                                                //             "size:",
                                                                //             rowData.size)
                                                                if (!tableView.isItemSelected(
                                                                            rowData.id)) {
                                                                    // 当前不是选中的状态
                                                                    tableView.clearSelection()
                                                                    tableView.toggleSelection(
                                                                                rowData)
                                                                }
                                                                // 准备上下文菜单数据
                                                                contextMenu.rowData = rowData
                                                                // 缺少属性
                                                                contextMenu.rowIndex = row
                                                                contextMenu.popup()
                                                            }
                                                        }
                                                    } catch (e) {
                                                        console.error(
                                                                    "处理点击事件时出错:",
                                                                    e)
                                                    }
                                                }
                                                onDoubleClicked: function (mouse) {
                                                    if (mouse.button === Qt.LeftButton) {
                                                        if (tableView.inBucketMode) {
                                                            console.log("打开桶列表: ",
                                                                        model.display)
                                                            currentBucket = model.display
                                                            handleOpenBucket(
                                                                        currentBucket)
                                                            return
                                                        }
                                                        const isFolder = nameCell.isFolderType()
                                                        if (!isFolder) {
                                                            console.log("双击的不是文件夹, 忽略操作")
                                                            return
                                                        }
                                                        var rowData = {
                                                            "id": "obj" + row,
                                                            "name": display
                                                                    || ""
                                                        }
                                                        if (!rowData) {
                                                            console.error(
                                                                        "无法获取行数据:",
                                                                        row)
                                                            return
                                                        }
                                                        var currentObjectModel = tableView.model
                                                        var indexCol0 = currentObjectModel.index(
                                                                    row, 0)
                                                        if (indexCol0
                                                                && indexCol0.valid) {
                                                            // 名字
                                                            var userRoleDataMap = currentObjectModel.data(
                                                                        indexCol0,
                                                                        Qt.UserRole)
                                                            if (userRoleDataMap) {
                                                                rowData.isFolder
                                                                        = userRoleDataMap.isFolder
                                                                rowData.key = userRoleDataMap.key
                                                                rowData.size = userRoleDataMap.size
                                                                rowData.date = userRoleDataMap.lastModified
                                                            } else {
                                                                console.warn(
                                                                            "UserRole data missing for row:",
                                                                            row,
                                                                            "name:",
                                                                            rowData.name)
                                                                rowData.isFolder
                                                                        = (rowData.name
                                                                           && rowData.name.endsWith(
                                                                               '/'))
                                                                rowData.key = rowData.name

                                                                var indexCol1 = currentObjectModel.index(
                                                                            row,
                                                                            1)
                                                                if (indexCol1
                                                                        && indexCol1.valid)
                                                                    rowData.size = currentObjectModel.data(indexCol1, Qt.DisplayRole)

                                                                var indexCol2 = currentObjectModel.index(
                                                                            row,
                                                                            2)
                                                                if (indexCol2
                                                                        && indexCol2.valid)
                                                                    rowData.date = currentObjectModel.data(indexCol2, Qt.DisplayRole)
                                                            }
                                                        } else {
                                                            console.error(
                                                                        "双击处理：无法获取行 ",
                                                                        row,
                                                                        " 的有效索引。")
                                                            return
                                                        }
                                                        if (rowData.isFolder !== isFolder) {
                                                            console.warn("双击处理：rowData.isFolder (" + rowData.isFolder + ") 与 nameCell.isFolderType() (" + isFolder + ") 不一致。 UserRole/derived data is used for rowData.")
                                                        }

                                                        console.log("打开文件夹:",
                                                                    rowData.name,
                                                                    "(Key:",
                                                                    rowData.key,
                                                                    "IsFolder:",
                                                                    rowData.isFolder,
                                                                    ")")

                                                        const keyToNavigate = rowData.key
                                                                            || (rowData.name && rowData.name.endsWith('/') ? rowData.name : rowData.name + '/')

                                                        ManagerGlobal.refreshObjects(
                                                                    currentBucket,
                                                                    keyToNavigate)

                                                        console.log("记录数: ",
                                                                    currentObjectModel.rowCount(
                                                                        ))

                                                        const displayName = rowData.name.endsWith('/') ? rowData.name.substring(0, rowData.name.length - 1) : rowData.name
                                                        console.log("双击打开文件夹和路径:",
                                                                    keyToNavigate,
                                                                    displayName)
                                                        breadcrumbNav.addPathItem(
                                                                    keyToNavigate,
                                                                    displayName)
                                                        resetPaginationOnFolderChange()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    // 文件大小
                                    DelegateChoice {
                                        column: 1
                                        delegate: Rectangle {
                                            visible: tableView.isValidRow(row)
                                            implicitHeight: 50
                                            property bool isItemSelected: {
                                                try {
                                                    if (!tableView.selectedItems)
                                                        return false
                                                    return tableView.selectedItems.some(
                                                                item => item.id === "obj" + row)
                                                } catch (e) {
                                                    console.error(
                                                                "Error checking selection:",
                                                                e)
                                                    return false
                                                }
                                            }
                                            color: isItemSelected ? "#E3F2FD" : "#FFFFFF"

                                            Text {
                                                anchors {
                                                    verticalCenter: parent.verticalCenter
                                                }
                                                text: display || ""
                                                color: "#555555"
                                                elide: Text.ElideRight
                                                width: parent.width - 16
                                            }
                                            // 添加行选择效果
                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: {
                                                    console.log("Current Row",
                                                                row)
                                                }
                                            }
                                        }
                                    }
                                    // 日期
                                    DelegateChoice {
                                        column: 2
                                        delegate: Rectangle {
                                            // 仅在行有效时显示
                                            visible: tableView.isValidRow(row)
                                            property bool isItemSelected: {
                                                try {
                                                    if (!tableView.selectedItems)
                                                        return false
                                                    return tableView.selectedItems.some(
                                                                item => item.id === "obj" + row)
                                                } catch (e) {
                                                    console.error(
                                                                "Error checking selection:",
                                                                e)
                                                    return false
                                                }
                                            }
                                            color: isItemSelected ? "#E3F2FD" : "#FFFFFF"
                                            implicitHeight: 50
                                            Text {
                                                anchors {
                                                    verticalCenter: parent.verticalCenter
                                                }
                                                text: display || ""
                                                color: "#555555"
                                                elide: Text.ElideRight
                                                width: parent.width - 16
                                            }
                                        }
                                    }
                                    DelegateChoice {
                                        column: 3 // 操作列
                                        delegate: Rectangle {
                                            id: operationCell
                                            visible: tableView.isValidRow(row)
                                                     && !tableView.inBucketMode
                                            implicitHeight: 50
                                            color: {
                                                try {
                                                    if (!tableView.selectedItems)
                                                        return "#FFFFFF"
                                                    return tableView.selectedItems.some(
                                                                item => item.id === "obj"
                                                                + row) ? "#E3F2FD" : "#FFFFFF"
                                                } catch (e) {
                                                    return "#FFFFFF"
                                                }
                                            }
                                            Button {
                                                id: modernDownloadButton
                                                anchors.centerIn: parent
                                                width: 70
                                                Layout.preferredHeight: 28 // 设定固定高度, 会影响表格的行高
                                                visible: {
                                                    // 之前第一次进入是无效的, 但是后面获取数据时，就会变得有效
                                                    // 构造的时候缺少数据, 访问 undefined, 这是 qml 的什么机制 ???
                                                    // 基本条件检查
                                                    if (tableView.inBucketMode) {
                                                        return false
                                                    }

                                                    if (!model) {
                                                        return false
                                                    }

                                                    // 获取文件名
                                                    var fileName = ""
                                                    try {
                                                        fileName = model.display
                                                                || ""
                                                    } catch (e) {
                                                        return false
                                                    }

                                                    if (!fileName) {
                                                        return false
                                                    }

                                                    // 简单判断：文件夹以 / 结尾
                                                    return !fileName.endsWith(
                                                                "/")
                                                }
                                                function updateVisibility() {
                                                    try {
                                                        if (tableView.inBucketMode) {
                                                            visible = false
                                                            return
                                                        }

                                                        // 检查模型数据是否有效
                                                        if (!model
                                                                || model.display === undefined) {
                                                            visible = false
                                                            return
                                                        }

                                                        var fileName = model.display
                                                                || ""
                                                        if (!fileName) {
                                                            visible = false
                                                            return
                                                        }

                                                        // 尝试从模型获取更详细的信息
                                                        var idx = tableView.model.index(
                                                                    row, 0)
                                                        if (idx && idx.isValid) {
                                                            var userData = tableView.model.data(
                                                                        idx,
                                                                        Qt.UserRole)
                                                            if (userData
                                                                    && userData.isFolder
                                                                    !== undefined) {
                                                                visible = !userData.isFolder
                                                                return
                                                            }
                                                        }

                                                        var isFolder = fileName.endsWith(
                                                                    "/")
                                                        visible = !isFolder
                                                    } catch (e) {
                                                        console.error(
                                                                    "updateVisibility 出错:",
                                                                    e)
                                                        visible = false
                                                    }
                                                }

                                                background: Rectangle {
                                                    radius: 6
                                                    color: parent.hovered ? "#EFF6FF" : "#F0F9FF"
                                                    border.color: parent.hovered ? "#3B82F6" : "transparent"
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
                                                    anchors.centerIn: parent
                                                    spacing: 4

                                                    Text {
                                                        text: "⬇"
                                                        font.pixelSize: 12
                                                        color: "#1D4ED8"
                                                        Layout.alignment: Qt.AlignVCenter
                                                    }

                                                    Text {
                                                        text: "下载"
                                                        font.pixelSize: 10
                                                        font.weight: Font.Medium
                                                        color: "#1D4ED8"
                                                        Layout.alignment: Qt.AlignVCenter
                                                        elide: Text.ElideRight
                                                    }
                                                }
                                                onClicked: {
                                                    try {
                                                        if (!tableView.model) {
                                                            console.error(
                                                                        "表格模型无效")
                                                            return
                                                        }
                                                        const totalRows = tableView.model.rowCount()
                                                        // 4. 验证行是否在当前分页范围内（使用显示行索引）
                                                        if (!tableView.isValidRow(
                                                                    row)) {
                                                            console.error(
                                                                        "行不在当前分页范围内:",
                                                                        row)
                                                            return
                                                        }
                                                        var fileInfo = {
                                                            "id": "obj" + row,
                                                            "name": model.display
                                                                    || "未知文件"
                                                        }
                                                        // 设置正确, 但是这里获取的是 行号, 而非 data 值
                                                        // 永远是 2 ???
                                                        // console.log("get the name: ",
                                                        //             fileInfo.name)
                                                        // 获取该行的有效数据
                                                        var idx = tableView.model.index(
                                                                    row, 0)
                                                        if (idx || idx.isValid) {
                                                            // fileInfo.name = tableView.model.data(
                                                            //             idx,
                                                            //             Qt.DisplayRole)
                                                            // // 读取的名字是正确的
                                                            // console.log("主动读取 display role: ",
                                                            //             fileInfo.name)

                                                            // }
                                                            var userData = tableView.model.data(
                                                                        idx,
                                                                        Qt.UserRole)
                                                            if (userData) {
                                                                fileInfo.key = userData.key
                                                                        || ""
                                                                fileInfo.size = userData.size
                                                                        || 0
                                                                fileInfo.isFolder
                                                                        = userData.isFolder
                                                                        || false
                                                                fileInfo.lastModified
                                                                        = userData.lastModified
                                                                        || ""
                                                            } else {
                                                                console.warn(
                                                                            "UserRole 数据无效，使用默认值:",
                                                                            fileInfo)
                                                            }
                                                        }
                                                        // name 是名字, key 是路径加+名字
                                                        console.log("点击下载按钮选择项目:",
                                                                    fileInfo.name,
                                                                    "key:",
                                                                    fileInfo.key,
                                                                    "size:",
                                                                    fileInfo.size)
                                                        rootItem.addDownloadTask(
                                                                    fileInfo)
                                                        // downloadPanel.open()
                                                    } catch (e) {
                                                        console.error(
                                                                    "下载处理错误:",
                                                                    e)
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
                                        }
                                    }
                                }
                                // 选择处理函数
                                function toggleSelection(item) {
                                    const index = selectedItems.findIndex(
                                                    i => i.id === item.id)
                                    if (index >= 0) {
                                        // 已选中，取消选择
                                        selectedItems.splice(index, 1)
                                    } else {
                                        // 未选中，添加选择
                                        selectedItems.push(item)
                                    }
                                    // 通知视图更新
                                    selectedItemsChanged()

                                    // 更新下载按钮状态
                                    downloadButton.enabled = selectedItems.length > 0
                                }

                                function clearSelection() {
                                    selectedItems = []
                                    selectedItemsChanged()
                                    downloadButton.enabled = false
                                }

                                function isItemSelected(id) {
                                    // 只有成功选择
                                    console.log("isItemSelected called with id:",
                                                id)
                                    return selectedItems.some(
                                                item => item.id === id)
                                }
                                // 上下文菜单
                                TtMenu {
                                    id: contextMenu
                                    property var rowData: null
                                    property int rowIndex: -1
                                    MenuItem {
                                        text: qsTr("编辑")
                                        onTriggered: {
                                            // 使用全局属性控制编辑状态，避免 DOM 访问
                                            tableView.editingRow = contextMenu.rowIndex
                                            tableView.editingColumn = 1 // 名称列

                                            // 通知视图更新
                                            tableView.forceLayout()

                                            console.log("开始编辑行:",
                                                        contextMenu.rowIndex)
                                        }
                                    }
                                    MenuItem {
                                        text: qsTr("删除对象")
                                        onTriggered: {
                                            // 返回的是 对象名, 缺少路径
                                            // BUG 缺少路径, 桶名正确
                                            console.log("删除项目:",
                                                        contextMenu.rowData ? contextMenu.rowData.name : "未知",
                                                        "桶名", currentBucket,
                                                        "路径",
                                                        contextMenu.rowData.key)
                                            ManagerGlobal.deleteFile(
                                                        currentBucket,
                                                        contextMenu.rowData.key)
                                        }
                                    }
                                }
                                Connections {
                                    target: contentPanel

                                    function onWidthChanged() {
                                        // 更新列宽计算
                                        // const availableWidth = contentPanel.width - 32
                                        const scrollBarWidth = 0
                                        const availableWidth = contentPanel.width - scrollBarWidth
                                        if (availableWidth > 500) {
                                            if (tableView.inBucketMode) {
                                                // 桶模型列宽
                                                rootItem.columnWidths
                                                        = [Math.max(
                                                               200,
                                                               availableWidth * 0.60), // 桶名称列占60%
                                                           Math.max(
                                                               150,
                                                               availableWidth * 0.20), // 创建时间列占20%
                                                           Math.max(
                                                               150,
                                                               availableWidth * 0.20) // 区域列占20%
                                                        ]
                                            } else {
                                                rootItem.columnWidths
                                                        = [Math.max(
                                                               200,
                                                               availableWidth * 0.45), // 名称列占45%
                                                           Math.max(
                                                               150,
                                                               availableWidth * 0.20), // 大小列占20%
                                                           Math.max(
                                                               150,
                                                               availableWidth * 0.20), // 更新时间列占20%
                                                           Math.max(
                                                               100,
                                                               availableWidth * 0.15) // 操作列占15%
                                                        ]
                                            }
                                            // 强制更新布局
                                            Qt.callLater(function () {
                                                tableView.forceLayout()
                                            })
                                        }
                                    }
                                }
                                // 确保在文件夹选择变化时刷新表格
                                Component.onCompleted: {
                                    ManagerGlobal.refreshBuckets()
                                    // bucketListView.currentIndexChanged.connect(
                                    //             function () {
                                    //                 // refreshData()
                                    //             })
                                }
                                // 添加响应窗口尺寸变化的逻辑
                            }
                        }
                        // 在表格或列表视图下方
                        TtPaginationNav {
                            id: pagination
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignBottom
                            // 选择某个桶的时候，计算总条数, 切换桶的时候对应的总条数也要改变
                            totalRecords: {
                                if (tableView.model
                                        && typeof tableView.model.rowCount === "function") {
                                    // 打印大只有一次, 后面变化了, 不会输出 log, 但会底部改变 totalRecord ??? 为什么
                                    console.log("get total ",
                                                tableView.model.rowCount())
                                    return tableView.model.rowCount()
                                }
                                console.log("return 0")
                                return 0
                            }
                            rowsPerPage: 20
                            currentPage: rootItem.currentPage

                            onPageRequested: function (page) {
                                // console.log("切换到页码:", page)
                                // 更新当前页码
                                rootItem.currentPage = page
                                // 重新计算分页范围
                                rootItem.pageStartRow = (page - 1) * currentPerPage
                                rootItem.pageEndRow = Math.min(
                                            rootItem.pageStartRow + currentPerPage,
                                            currentRecordCount) - 1
                                Qt.callLater(function () {
                                    tableView.contentY = 0
                                    tableView.forceLayout()
                                    tableView.contentY = 0
                                })
                            }
                            // 处理每页行数变化
                            onRowsPerPageRequested: function (rows) {
                                console.log("每页显示行数改为:", rows)
                                // 更新每页行数
                                rootItem.currentPerPage = rows

                                // 如果当前页超出新的页数范围，调整到第一页
                                const totalPages = Math.ceil(
                                                     currentRecordCount / rows)
                                if (currentPage > totalPages) {
                                    currentPage = 1
                                }

                                // 重新计算分页范围
                                rootItem.pageStartRow = (currentPage - 1) * rows
                                rootItem.pageEndRow = Math.min(
                                            rootItem.pageStartRow + rows,
                                            currentRecordCount) - 1

                                // 强制刷新表格
                                tableView.forceLayout()

                                // 滚动到顶部
                                tableView.contentY = 0
                            }
                        }
                    }
                }
            }
        }

        // 底部状态栏
        Rectangle {
            Layout.fillWidth: true
            height: 28
            color: "#F5F6FA"

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 16
                    rightMargin: 16
                }

                Label {
                    text: {
                        rootItem.getCurrentPageRowCount()
                        // 修复错误的模型引用
                        // const count = tableModel ? tableModel.rowCount : 0
                        // const selected = tableView.selectedItems.length
                        // return selected
                        //         > 0 ? `已选择 ${selected} 个项目，共 ${count} 个项目` : `共 ${count} 个项目`
                    }
                    // font.pixelSize: 12
                    // color: "#666666"
                }

                Item {
                    Layout.fillWidth: true
                }

                Label {
                    text: "2025 Cloud Storage Hub"
                    font.pixelSize: 12
                    color: "#666666"
                }
            }
        }
    }

    // 添加下载管理面板
    // DownloadPanel {
    //     id: downloadPanel
    //     parent: Overlay.overlay
    //     // 关键修改：传递模型给 DownloadPanel
    //     downloadModel: rootItem.downloadModel
    //     visible: downloadModel.count > 0
    //     activeDownloads: {
    //         let count = 0
    //         for (var i = 0; i < downloadModel.count; i++) {
    //             // if (downloadModel.get(i).progress < 1)
    //             //     count++
    //             const item = downloadModel.get(i)
    //             if (item && item.progress < 1 && item.status !== "错误") {
    //                 count++
    //             }
    //         }
    //         return count
    //     }
    // }
    Component.onCompleted: {
        const availableWidth = contentPanel.width
        if (tableView.inBucketMode) {
            // 桶模型列宽
            rootItem.columnWidths = [Math.max(
                                         200,
                                         availableWidth * 0.60), // 桶名称列占60%
                                     Math.max(
                                         150,
                                         availableWidth * 0.20), // 创建时间列占20%
                                     Math.max(150,
                                              availableWidth * 0.20) // 区域列占20%
                    ]
        } else {
            // 对象模型列宽
            rootItem.columnWidths = [Math.max(200,
                                              availableWidth * 0.50), // 名称列占50%
                                     Math.max(150,
                                              availableWidth * 0.25), // 大小列占25%
                                     Math.max(
                                         150,
                                         availableWidth * 0.20) // 更新时间列占25%
                    ]
        }
        // 强制更新布局
        Qt.callLater(function () {
            tableView.forceLayout()
        })

        // 还没有登录, 就已经进入分页状态的
        // 初始化完成后立即更新分页状态
        // updatePaginationState()

        // 设置一个延迟更新，确保在模型数据加载后更新分页状态
        Qt.callLater(function () {
            rootItem.currentRecordCount = updateRecordCount()
            updatePaginationState()
        })
        // 连接下载进度信号
        ManagerGlobal.downloadProgressUpdated.connect(
                    function (jobId, progress) {
                        // 这里没有执行?
                        // 缺少某些任务
                        // 1.0 的进度是完成任务
                        console.log("TEST 更新下载进度:", jobId, progress)
                        // 确保参数有效
                        if (!jobId || progress === undefined
                                || progress === null) {
                            console.warn("下载进度更新参数无效:", jobId, progress)
                            return
                        }
                        let found = false
                        // 查找对应的下载项并更新进度
                        for (var i = 0; i < downloadModel.count; i++) {
                            const item = downloadModel.get(i)
                            if (item && item.jobId === jobId) {
                                found = true
                                // 更新进度
                                downloadModel.setProperty(i,
                                                          "progress", progress)
                                downloadModel.setProperty(i, "lastUpdateTime",
                                                          new Date().getTime())
                                if (progress >= 1.0) {
                                    // 添加到历史模型中
                                    downloadModel.setProperty(i,
                                                              "status", "已完成")
                                    downloadModel.setProperty(i, "speed", "")
                                    // 文本更新放到 downloadwindow 中
                                    // 缺少 localPath
                                    console.log("下载完成并添加到历史模型中:", item.name,
                                                "本地路径:", item.localPath)
                                    // 添加的 name 也是没有问题的
                                    downloadHistoryModel.append({
                                                                    "name": item.name,
                                                                    "size": item.size,
                                                                    "progress": item.progress,
                                                                    "jobId": item.jobId,
                                                                    "status": "已完成",
                                                                    "speed": item.speed
                                                                             || "0 KB/s",
                                                                    "startTime": item.startTime,
                                                                    "lastUpdateTime": item.lastUpdateTime,
                                                                    "completedTime": new Date().getTime(),
                                                                    "bucketName": item.bucketName,
                                                                    "key": item.key,
                                                                    "localPath": item.localPath
                                                                })
                                    downloadModel.remove(i)
                                } else if (progress > 0) {
                                    downloadModel.setProperty(i,
                                                              "status", "下载中")
                                    // 计算下载速度（简化版）
                                    const currentTime = new Date().getTime()
                                    const startTime = item.startTime
                                                    || currentTime
                                    const elapsedSeconds = (currentTime - startTime) / 1000
                                    if (elapsedSeconds > 0) {
                                        const speed = Math.round(
                                                        (progress * 1024)
                                                        / elapsedSeconds) // 简化速度计算
                                        downloadModel.setProperty(
                                                    i, "speed", `${speed} KB/s`)
                                    }
                                } else {
                                    downloadModel.setProperty(i,
                                                              "status", "连接中")
                                    downloadModel.setProperty(i,
                                                              "speed", "0 KB/s")
                                }
                                break
                            }
                        }
                        if (!found) {
                            console.warn("找不到下载任务:", jobId)
                        }
                    })
        ManagerGlobal.bucketListLoaded.connect(function () {
            // 如何至链接一次 ???
            console.log("桶列表加载完成")
            // 重复触发
            if (rootItem) {
                console.log("初始化根项, 并发射信号")
                rootItem.initializationCompleted()
            }
        })

        // 添加下载错误处理
        if (typeof ManagerGlobal.downloadError !== 'undefined') {
            ManagerGlobal.downloadError.connect(function (jobId, errorMessage) {
                console.error("下载错误:", jobId, errorMessage)
                // 查找对应的下载项并标记错误
                for (var i = 0; i < downloadModel.count; i++) {
                    const item = downloadModel.get(i)
                    if (item && item.jobId === jobId) {
                        downloadModel.setProperty(i, "status", "错误")
                        downloadModel.setProperty(i, "speed", "")
                        break
                    }
                }
            })
        }
        console.log("组件构造完成")
        searchField.historyModel = ManagerGlobal.getBucketNames()
        console.log("SearchField HistoryModel: ", searchField.historyModel)

        // 连接上传相关信号
        ManagerGlobal.uploadProgressUpdated.connect(function (jobId, progress) {
            // updateUploadStatus(jobId, "上传中", progress)
            console.log("更新下载进度", jobId, progress)
            if (!jobId || progress === undefined || progress === null) {
                console.warn("下载进度更新参数无效:", jobId, progress)
                return
            }
            let found = false
            for (var i = 0; i < uploadModel.count; ++i) {
                const item = uploadModel.get(i)
                if (item && item.jobId === jobId) {
                    found = true
                    uploadModel.setProperty(i, "progress", progress)
                    uploadModel.setProperty(i, "lastUpdateTime",
                                            new Date().getTime())
                    if (progress >= 1.0) {
                        uploadModel.setProperty(i, "status", "已完成")
                        uploadModel.setProperty(i, "speed", "")
                        uploadHistoryModel.append({
                                                      "jobId": item.jobId,
                                                      "fileName": item.fileName,
                                                      "progress": item.progress,
                                                      "status": "已完成",
                                                      "bucket": item.bucket,
                                                      "size": item.size || 0
                                                  })
                    }
                }
            }
        })

        ManagerGlobal.deleteObjectSuccess.connect(function (bucket, key) {
            console.log("删除对象成功: ", bucket, key)

            tableView.clearSelection()

            // 提取目录路径
            var directoryPath = ""
            var lastSlashIndex = key.lastIndexOf("/")

            if (lastSlashIndex !== -1) {
                directoryPath = key.substring(0, lastSlashIndex + 1)
                console.log("提取的目录路径:", directoryPath) // 输出: "测试文件/"
            }

            // 刷新当前目录
            if (directoryPath) {
                // 会刷新多次
                console.log("刷新1")
                ManagerGlobal.refreshObjects(bucket, directoryPath)
            } else {
                console.log("刷新2")
                ManagerGlobal.refreshObjects(bucket)
            }
            resetPaginationOnFolderChange()
        })
        // 一开始就初始化文件历史记录
        initializeHistoryModels()
    }
    // 在 MainPage.qml 中的下载完成处理函数中添加
    // 根本没有调用
    function handleDownloadCompleted(jobId) {
        // 查找对应的下载任务
        for (var i = 0; i < downloadModel.count; i++) {
            var item = downloadModel.get(i)
            if (item.jobId === jobId) {
                // 第一个是 undefined
                console.log("下载完成:", item.name, item.jobId)
                // 保存到历史记录
                if (ManagerGlobal && ManagerGlobal.getHistoryManager) {
                    // 获取对象 obj
                    var historyManager = ManagerGlobal.getHistoryManager()
                    // 插入语句
                    if (historyManager) {
                        var record = {
                            "jobId": item.jobId,
                            "fileName": item.name,
                            "fileSize": item.fileSize || 0,
                            "bucketName": item.bucketName,
                            "objectKey": item.key,
                            "localPath": item.localPath,
                            "status": "已完成",
                            "startTime"// "startTime": item.startTime || Date.now(),
                            : item.startTime,
                            "completedTime": Date.now()
                        }

                        try {
                            historyManager.addDownloadRecord(record)
                            // 但是这里成功了 ???
                            console.log("下载历史保存成功:", item.name)
                        } catch (error) {
                            console.error("保存下载历史失败:", error)
                        }
                    }
                }
                break
            }
        }
    }
    function handleFolderDoubleClick(row) {
        try {
            console.log("📁 处理文件夹双击，行:", row)

            // 🔥 防止加载期间操作
            if (loadingOverlay.active) {
                console.log("⚠️ 正在加载中，忽略操作")
                return
            }

            var rowData = {
                "id": "obj" + row,
                "name": ""
            }

            // 🔥 安全获取行数据
            var currentObjectModel = tableView.model
            if (!currentObjectModel) {
                console.error("❌ 表格模型无效")
                return
            }

            var indexCol0 = currentObjectModel.index(row, 0)
            if (!indexCol0 || !indexCol0.valid) {
                console.error("❌ 无法获取有效索引，行:", row)
                return
            }

            // 🔥 获取显示名称
            rowData.name = currentObjectModel.data(indexCol0,
                                                   Qt.DisplayRole) || ""
            if (!rowData.name) {
                console.error("❌ 无法获取文件名")
                return
            }

            // 🔥 获取详细数据
            var userRoleDataMap = currentObjectModel.data(indexCol0,
                                                          Qt.UserRole)
            if (userRoleDataMap) {
                rowData.isFolder = userRoleDataMap.isFolder
                rowData.key = userRoleDataMap.key
                rowData.size = userRoleDataMap.size
                rowData.date = userRoleDataMap.lastModified
            } else {
                console.warn("⚠️ UserRole 数据缺失，使用备用方案")
                rowData.isFolder = rowData.name.endsWith('/')
                rowData.key = rowData.name
            }

            // 🔥 验证是否为文件夹
            if (!rowData.isFolder) {
                console.log("❌ 不是文件夹，忽略操作")
                return
            }

            // 🔥 显示加载状态
            const displayName = rowData.name.endsWith(
                                  '/') ? rowData.name.substring(
                                             0,
                                             rowData.name.length - 1) : rowData.name
            loadingOverlay.show("objects", `正在加载文件夹 ${displayName}...`)

            // 🔥 构建导航路径
            const keyToNavigate = rowData.key
                                || (rowData.name.endsWith(
                                        '/') ? rowData.name : rowData.name + '/')

            console.log("📁 打开文件夹:", displayName, "路径:", keyToNavigate)

            // 🔥 更新面包屑导航
            breadcrumbNav.addPathItem(keyToNavigate, displayName)

            // 🔥 重置分页状态
            resetPaginationOnFolderChange()

            // 🔥 清空选择
            tableView.clearSelection()

            // 🔥 延迟请求数据
            Qt.callLater(function () {
                if (rootItem.currentBucket) {
                    ManagerGlobal.refreshObjects(rootItem.currentBucket,
                                                 keyToNavigate)
                } else {
                    console.error("❌ 当前桶名无效")
                    loadingOverlay.hide()
                }
            })
        } catch (error) {
            console.error("❌ 处理文件夹双击失败:", error)
            loadingOverlay.hide()
        }
    }
    // 🔥 添加历史记录初始化函数
    function initializeHistoryModels() {
        console.log("🔄 初始化历史记录模型...")

        if (!ManagerGlobal || !ManagerGlobal.getHistoryManager) {
            console.warn("⚠️ ManagerGlobal 或 HistoryManager 不可用，稍后重试...")
            // 延迟重试
            Qt.callLater(function () {
                initializeHistoryModels()
            })
            return
        }

        var historyManager = ManagerGlobal.getHistoryManager()
        if (!historyManager) {
            console.warn("⚠️ 无法获取 HistoryManager 实例")
            return
        }

        try {
            loadDownloadHistoryToModel()
            loadUploadHistoryToModel()
            console.log("✅ 历史记录模型初始化完成")
        } catch (error) {
            console.error("❌ 初始化历史记录模型失败:", error)
        }
    }

    function loadDownloadHistoryToModel() {
        if (!ManagerGlobal || !ManagerGlobal.getHistoryManager) {
            return
        }

        var historyManager = ManagerGlobal.getHistoryManager()
        if (!historyManager) {
            return
        }

        try {
            downloadHistoryModel.clear()
            var historyList = historyManager.getDownloadHistory(100)

            console.log("📥 MainPage 从数据库获取到下载历史记录:", historyList.length, "条")

            for (var i = 0; i < historyList.length; i++) {
                var item = historyList[i]

                var record = {
                    "name": item.fileName || item.name || "未知文件",
                    "size": typeof item.size === 'number' ? item.size : (parseInt(item.size)
                                                                         || 0),
                    "progress": 1.0,
                    "jobId": item.jobId || "",
                    "status": "已完成",
                    "speed": "",
                    "startTime": typeof item.startTime
                                 === 'number' ? item.startTime : (parseInt(
                                                                      item.startTime)
                                                                  || 0),
                    "lastUpdateTime": typeof item.completedTime
                                      === 'number' ? item.completedTime : (parseInt(
                                                                               item.completedTime)
                                                                           || 0),
                    "completedTime": typeof item.completedTime
                                     === 'number' ? item.completedTime : (parseInt(
                                                                              item.completedTime)
                                                                          || 0),
                    "bucketName": item.bucketName || "",
                    "key": item.objectKey || "",
                    "localPath": item.localPath || ""
                }

                downloadHistoryModel.append(record)
            }

            console.log("✅ MainPage 下载历史记录加载完成，记录数:",
                        downloadHistoryModel.count)
        } catch (error) {
            console.error("❌ MainPage 加载下载历史失败:", error)
        }
    }
    function loadUploadHistoryToModel() {
        if (!ManagerGlobal || !ManagerGlobal.getHistoryManager) {
            return
        }
        var historyManager = ManagerGlobal.getHistoryManager()
        if (!historyManager) {
            return
        }

        try {
            uploadHistoryModel.clear()
            var historyList = historyManager.getUploadHistory(100)
            console.log("📥 MainPage 从数据库获取到上传历史记录:", historyList.length, "条")

            for (var i = 0; i < historyList.length; i++) {
                var item = historyList[i]
                var record = {
                    "name": item.fileName || item.name || "未知文件",
                    "size": typeof item.size === 'number' ? item.size : (parseInt(item.size)
                                                                         || 0),
                    "progress": 1.0,
                    "jobId": item.jobId || "",
                    "status": "已完成",
                    "speed": "",
                    "startTime": typeof item.startTime
                                 === 'number' ? item.startTime : (parseInt(
                                                                      item.startTime)
                                                                  || 0),
                    "lastUpdateTime": typeof item.completedTime
                                      === 'number' ? item.completedTime : (parseInt(
                                                                               item.completedTime)
                                                                           || 0),
                    "completedTime": typeof item.completedTime
                                     === 'number' ? item.completedTime : (parseInt(
                                                                              item.completedTime)
                                                                          || 0),
                    "bucketName": item.bucketName || "",
                    "key": item.objectKey || "",
                    "localPath": item.localPath || ""
                }

                uploadHistoryModel.append(record)
            }

            console.log("✅ MainPage 上传历史记录加载完成，记录数:", uploadHistoryModel.count)
        } catch (error) {
            console.error("❌ MainPage 加载上传历史失败:", error)
        }
    }
}

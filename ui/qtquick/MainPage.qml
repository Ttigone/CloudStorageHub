import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import QtQml.Models
import Qt.labs.qmlmodels
import QtQml
import Qt5Compat.GraphicalEffects

import "./Component"

// 后端的 model 以赋值形式填入, 始终都是值更新, 没办法捕获底层的 model 是否改变, 赋值给代理模型, 代理模型不知道是否改变
Item {
    id: rootItem
    anchors.fill: parent
    property var columnWidths: [300, 150, 150, 100] // 名称、大小、日期、操作按钮区
    property int currentPerPage: 20
    property ListModel downloadModel: ListModel {}
    // 在properties区域添加代理模型实例
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

    // 初始化完成
    signal initializationCompleted

    // 暴露的属性和信号
    property var folderModel: [] // 文件夹模型数据
    property var fileModel: [] // 文件模型数据

    property int sortColumn: -1 // -1表示未排序，0,1,2,3对应不同列
    property bool sortAscending: true // true为升序，false为降序
    // 没有定义
    property string currentBucket: "" // 当前选中的存储桶

    // 添加属性存储当前记录数
    property int currentRecordCount: updateRecordCount()
    property int currentPage: 1

    // 添加上传相关属性
    property ListModel uploadModel: ListModel {}
    property ListModel uploadHistoryModel: ListModel {}
    property var fileUploadDialog: null // 添加这个属性
    property var uploadPanel: null // 添加上传面板属性

    // 添加桶列表更新的监听
    Connections {
        target: ManagerGlobal
        function onBucketListLoaded() {
            console.log("桶列表加载完成，更新搜索框历史记录")
            if (searchField) {
                searchField.historyModel = ManagerGlobal.getBucketNames()
                console.log("更新后的历史记录:", searchField.historyModel)
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
                // 设置传输模型
                transferWindow.uploadModel = rootItem.uploadModel
                transferWindow.downloadModel = rootItem.downloadModel // 正在下载
                // transferWindow.uploadHistoryModel = Qt.createQmlObject(
                //             'import QtQuick; ListModel {}', transferWindow)
                transferWindow.uploadHistoryModel = rootItem.uploadHistoryModel
                transferWindow.downloadHistoryModel = rootItem.downloadHistoryModel // 历史下载

                // 连接传输控制信号
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
                    taskInfo.key, taskInfo.name)
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
                // 执行下载
                // name 有问题
                ManagerGlobal.downloadFile(jobId, bucketName, key, name)
                // 为该任务设置超时检测
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
        // console.log(`处理批次 ${Math.floor(
        //                 startIndex / downloadBatchTimer.batchSize) + 1}/${Math.ceil(
        //                 downloadBatchTimer.batchItems.length
        //                 / downloadBatchTimer.batchSize)}, 项目 ${startIndex + 1}-${endIndex}`)
        for (var i = startIndex; i < endIndex; i++) {
            // 逐个加入到任务队列中
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
    // 添加下载历史模型
    property ListModel downloadHistoryModel: ListModel {}

    // 添加下载管理窗口属性
    property var downloadWindow: null

    // 添加创建下载窗口的函数
    // function createDownloadWindow() {
    //     var component = Qt.createComponent("DownloadWindow.qml")
    //     console.log("创建下载窗口组件")
    //     if (component.status === Component.Ready) {
    //         // 引用关系
    //         downloadWindow = component.createObject(rootItem, {
    //                                                     "downloadModel": rootItem.downloadModel,
    //                                                     "historyModel": rootItem.downloadHistoryModel
    //                                                 })
    //     } else {
    //         console.error("无法创建下载管理窗口:", component.errorString())
    //     }
    // }

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
        // 创建临时数组存储所有数据
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
                // 处理日期排序 - 使用日期格式解析
                valueA = parseDateString(a.date)
                valueB = parseDateString(b.date)
            } else {
                return 0 // 不支持的列
            }

            // 升序/降序比较
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

        // 清除当前数据并按排序顺序重新添加
        tableModel.clear()
        for (var i = 0; i < rows.length; i++) {
            tableModel.appendRow(rows[i])
        }
    }
    function resetPaginationOnFolderChange() {
        // 重置到第一页
        rootItem.currentPage = 1
        // 清空选择
        tableView.clearSelection()
        rootItem.currentRecordCount = updateRecordCount()

        // 重新计算分页范围
        rootItem.pageStartRow = 0 // 从第一条记录开始
        rootItem.pageEndRow = Math.min(currentPerPage, currentRecordCount) - 1

        // 强制更新分页导航显示
        pagination.totalRecords = rootItem.currentRecordCount
        pagination.currentPage = 1
        rootItem.updatePaginationState()

        // 点击 root ，触发 2 次
        // 获取的记录数就有
        console.log("文件夹变更，重置分页状态：当前页=1，总记录数=", rootItem.currentRecordCount)
    }

    // 添加解析日期字符串的辅助函数
    function parseDateString(dateStr) {
        if (!dateStr) {
            return 0
        }
        try {
            // 尝试解析为日期对象
            const date = new Date(dateStr)
            if (isNaN(date.getTime())) {
                return dateStr.toLowerCase()
            }
            // 返回时间戳用于比较
            return date.getTime()
        } catch (e) {
            // 失败情况下返回原始字符串
            return dateStr.toLowerCase()
        }
    }

    // 切换到桶模型显示
    function switchToBucketsModel() {
        // 保存当前表格视图状态
        tableView.inBucketMode = true
        // 根据当前可用宽度计算桶模型的列宽
        const availableWidth = contentPanel.width
        if (availableWidth > 0) {
            // 为桶模型设置适合的列宽比例
            rootItem.columnWidths = [Math.max(
                                         200,
                                         availableWidth * 0.60), // 桶名称列占60%
                                     Math.max(
                                         150,
                                         availableWidth * 0.20), // 创建时间列占20%
                                     Math.max(150,
                                              availableWidth * 0.20) // 区域列占20%
                    ]
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

    // 更新对象数据模型
    function switchToObjectsModel(bucketName) {
        tableView.inBucketMode = false
        const availableWidth = contentPanel.width
        if (availableWidth > 0) {
            // rootItem.columnWidths = [Math.max(200,
            //                                   availableWidth * 0.50), Math.max(
            //                              150, availableWidth * 0.25), Math.max(
            //                              150, availableWidth * 0.25)]
            rootItem.columnWidths = [Math.max(200,
                                              availableWidth * 0.45), // 名称列占45%
                                     Math.max(150,
                                              availableWidth * 0.20), // 大小列占20%
                                     Math.max(
                                         150,
                                         availableWidth * 0.20), // 更新时间列占20%
                                     Math.max(100,
                                              availableWidth * 0.15) // 操作列占15%
                    ]
            console.log("对象模型列宽设置为:", rootItem.columnWidths)
            // 有获取到正确的列宽
            // 这里提供了
            console.log("操作列宽度: " + rootItem.columnWidths[3])
        } else {
            // rootItem.columnWidths = [300, 150, 150]
            rootItem.columnWidths = [300, 150, 150, 100] // 添加第4列
        }
        // headerBar.headerTitles = ["对象名称", "大小", "更新时间"]
        headerBar.headerTitles = ["对象名称", "大小", "更新时间", "操作"]
        // 点击左侧, 出现问题, 未定义的
        console.log("调用一次并刷新对象", bucketName)
        // 先刷新对象名
        // 先获取 model, 再刷新 model 里面的值 ???
        tableView.model = ManagerGlobal.getObjectsModel()
        ManagerGlobal.refreshObjects(bucketName)
        tableView.contentY = 0
        tableView.forceLayout()
    }
    // 添加分页控制属性 - 在根项目定义这些属性使它们全局可用
    // 初始 0
    property int pageStartRow: (currentPage - 1) * currentPerPage
    // 初始 0 + 20, 0   -> 0  - 1 -> -1
    property int pageEndRow: Math.min(pageStartRow + currentPerPage,
                                      currentRecordCount) - 1

    function getPageStartRow() {
        return (currentPage - 1) * currentPerPage
    }

    function getPageEndRow() {
        // console.log("获取当前页结束行: ", getPageStartRow(), currentPerPage,
        // currentRecordCount)
        // 0 + 1 , 3
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

    // 添加刷新记录数的函数
    function updateRecordCount() {
        if (!tableView.model) {
            return 0
        }

        // 优先使用 totalCount 属性获取总记录数
        if (typeof tableView.model.totalCount !== "undefined") {
            return tableView.model.totalCount
        }

        // 如果没有 totalCount，则尝试使用 rowCount 函数
        if (typeof tableView.model.rowCount === "function") {
            return tableView.model.rowCount()
        }

        return 0
    }
    // 添加获取当前页记录数的函数
    function getCurrentPageRowCount() {
        if (!tableView.model)
            return 0
        // 优先使用专门的当前页行数属性
        if (typeof tableView.model.currentPageRowCount !== "undefined") {
            return tableView.model.currentPageRowCount
        }
        // 回退方案：手动计算当前页行数
        const totalRecords = updateRecordCount()
        const rowsPerPage = pagination.rowsPerPage
        const currentPage = pagination.currentPage
        const firstRow = (currentPage - 1) * rowsPerPage

        // console.log("获取当前页行数: ", totalRecords, rowsPerPage,
        //             currentPage, firstRow)
        // console.log("计算当前页行数: ", Math.min(rowsPerPage, totalRecords - firstRow))
        return Math.min(rowsPerPage, totalRecords - firstRow)
    }

    // 在 rootItem 中定义处理函数
    function handleBucketDoubleClick(bucketName) {
        console.log("双击打开桶:", bucketName)
        switchToObjectsModel(bucketName)
        updateCurrentBucket(bucketName)
        // 设置左侧列表选中项
        for (var i = 0; i < bucketListView.count; i++) {
            if (bucketListView.model.data(bucketListView.model.index(
                                              i, 0)) === bucketName) {
                bucketListView.currentIndex = i
                break
            }
        }

        // 设置面包屑导航
        breadcrumbNav.resetToRoot()
        // 添加失败, 有效
        console.log("添加面包屑路径:", bucketName, bucketName)
        breadcrumbNav.addPathItem(bucketName, bucketName)

        // 重置分页
        resetPaginationOnFolderChange()
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
                                // 在 ItemDelegate 中添加
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    propagateComposedEvents: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: function (mouse) {
                                        if (mouse.button === Qt.RightButton) {
                                            // 右键单击
                                            folderContextMenu.folderData = modelData
                                            folderContextMenu.folderIndex = index
                                            folderContextMenu.popup()
                                        }
                                        mouse.accepted = false
                                    }
                                    onDoubleClicked: function (mouse) {
                                        // 发送给后端, 要请求的数据
                                        if (mouse.button === Qt.LeftButton) {
                                            console.log("Request Object by Current Bucket: ",
                                                        model.display)
                                            // 点击点击根图标, 刷新了
                                            if (model.display === currentBucket) {
                                                if (model.display !== breadcrumbNav.getCurrentPath(
                                                            )) {
                                                    console.log("非当前路径")
                                                    breadcrumbNav.resetToRoot()
                                                    breadcrumbNav.addPathItem(
                                                                model.display,
                                                                model.display)
                                                    switchToObjectsModel(
                                                                model.display)
                                                    mouse.accepted = true
                                                } else {
                                                    console.log("点击了当前已选中的桶，仅刷新")
                                                    switchToObjectsModel(
                                                                model.display)
                                                    mouse.accepted = true
                                                }
                                                return
                                            }
                                            console.log("切换到新桶:", model.display)
                                            breadcrumbNav.resetToRoot()
                                            var bucketName = model.display
                                            currentBucket = bucketName
                                            bucketListView.currentIndex = index
                                            breadcrumbNav.addPathItem(
                                                        bucketName, bucketName)
                                            switchToObjectsModel(bucketName)
                                            resetPaginationOnFolderChange()
                                            // 刷新对象的显示问题
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
                                                // BUG 删除之后, 刷新界面
                                                console.log("删除桶:",
                                                            folderContextMenu.folderData ? folderContextMenu.folderData.name : "未知")
                                                ManagerGlobal.deleteBucket(
                                                            folderContextMenu.folderData ? folderContextMenu.folderData.name : "")
                                                // switchToObjectsModel()
                                                // 路径名, 然后更新
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
                                        // console.log("行被删除")
                                        rootItem.updateRecordCount() // 更新记录数
                                    }
                                }
                                // 添加排序函数
                                function sortByColumn(column, ascending) {
                                    // 创建临时数组存储所有数据
                                    let rows = []
                                    for (var i = 0; i < tableModel.rowCount; i++) {
                                        rows.push(tableModel.getRow(i))
                                    }

                                    // 根据选定的列排序
                                    rows.sort(function (a, b) {
                                        let valueA, valueB

                                        // 根据列选择字段
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
                                            // 处理日期排序 - 使用日期格式解析
                                            valueA = rootItem.parseDateString(
                                                        a.date)
                                            valueB = rootItem.parseDateString(
                                                        b.date)
                                        } else {
                                            return 0 // 不支持的列
                                        }

                                        // 升序/降序比较
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

                                    // 清除当前数据并按排序顺序重新添加
                                    tableModel.clear()
                                    for (var i = 0; i < rows.length; i++) {
                                        tableModel.appendRow(rows[i])
                                    }
                                }
                                columnWidthProvider: function (column) {
                                    try {
                                        // console.log("Current column: ", column)
                                        if (column < 0
                                                || !rootItem.columnWidths) {
                                            return 0
                                        }

                                        // 特别处理操作列
                                        if (column === 3) {
                                            if (tableView.inBucketMode) {
                                                // console.log("桶模式下操作列宽度为0")
                                                return 0
                                            } else {
                                                var width = rootItem.columnWidths.length
                                                        > 3 ? rootItem.columnWidths[3] : 100
                                                // 这里没有输出
                                                // console.log("操作列宽度:", width)
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
                                                // 添加文本图标组件
                                                Text {
                                                    id: fileIcon
                                                    // 每次渲染时强制重新计算，不依赖于缓存的属性值
                                                    // 需要加一个 桶图标
                                                    text: {
                                                        if (tableView.inBucketMode) {
                                                            return "🪣" // 桶图标
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
                                                // 文本标签同样使用函数
                                                Text {
                                                    id: cellText
                                                    Layout.fillWidth: true
                                                    text: {
                                                        // 每次访问时重新计算
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

                                                    // 这里获取的数据是正确的
                                                    // 为什么数据是最后获取, 初始化完成后才会获取 ???
                                                    // if (row < 5) {
                                                    //     // 有时候会少一行, 但是模型存在
                                                    //     // 只有一行
                                                    //     console.debug(
                                                    //                 "渲染初始化, 行:",
                                                    //                 row, "名称:",
                                                    //                 model.display,
                                                    //                 "isFolder:",
                                                    //                 nameCell.isFolderType(
                                                    //                     ))
                                                    // }
                                                }
                                            }
                                            // 处理点击事件
                                            MouseArea {
                                                id: mouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                cursorShape: Qt.PointingHandCursor // 这里似乎失效了, 没有显示
                                                propagateComposedEvents: !nameCell.isEditing // 编辑时不传播事件
                                                property var root: rootItem
                                                // property var navBread: breadcrumbNav
                                                // property var bucketList: bucketListView
                                                // property var manager: ManagerGlobal
                                                onClicked: function (mouse) {
                                                    console.log("Clicked on row",
                                                                row)
                                                    try {
                                                        // 如果当前是桶模型模式，点击处理不同
                                                        if (tableView.inBucketMode) {
                                                            if (mouse.button === Qt.LeftButton) {
                                                                // 获取桶名
                                                                const bucketName = model.display
                                                                // console.log("选择桶:",
                                                                //             bucketName)
                                                                // 普通点击只是选择，不导航
                                                                tableView.clearSelection()
                                                                // // 给行添加选中效果
                                                                // const rowData = {
                                                                //     "id": "bucket" + row,
                                                                //     "name": bucketName
                                                                // }
                                                            } else if (mouse.button
                                                                       === Qt.RightButton) {
                                                                // 桶的右键菜单
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
                                                    // BUG 设置面包屑路径有问题
                                                    if (mouse.button === Qt.LeftButton) {
                                                        // 桶模式下的双击处理
                                                        if (tableView.inBucketMode) {
                                                            // 新的参数 未定义
                                                            console.log("打开桶列表: ",
                                                                        model.display)
                                                            root.handleBucketDoubleClick(
                                                                        model.display)
                                                            return
                                                        }
                                                        // 判断是否是文件夹, 否则不能下钻, 但是可以打开
                                                        const isFolder = nameCell.isFolderType()
                                                        // 获取有问题
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
                                                        // 获取模型
                                                        var currentObjectModel = tableView.model
                                                        // 获取当前名称列
                                                        var indexCol0 = currentObjectModel.index(
                                                                    row, 0)
                                                        // Index for the first column
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
                                                                // Fallback if UserRole data is not available or incomplete
                                                                console.warn(
                                                                            "UserRole data missing for row:",
                                                                            row,
                                                                            "name:",
                                                                            rowData.name)
                                                                rowData.isFolder = (rowData.name && rowData.name.endsWith('/')) // Infer from name
                                                                rowData.key = rowData.name // Simplistic fallback for key

                                                                // Attempt to get size/date from DisplayRole of other columns if not in UserRole
                                                                var indexCol1 = currentObjectModel.index(
                                                                            row,
                                                                            1)
                                                                // Assuming size is column 1
                                                                if (indexCol1
                                                                        && indexCol1.valid)
                                                                    rowData.size = currentObjectModel.data(indexCol1, Qt.DisplayRole)

                                                                var indexCol2 = currentObjectModel.index(
                                                                            row,
                                                                            2)
                                                                // Assuming date is column 2
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
                                                            // Cannot proceed without valid data
                                                        }
                                                        // Ensure rowData.isFolder is consistent with the earlier check
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
                                                        // 值正确的, 但是显示不正确移植是 /
                                                        console.log("双击打开文件夹和路径:",
                                                                    keyToNavigate,
                                                                    displayName)
                                                        breadcrumbNav.addPathItem(
                                                                    keyToNavigate,
                                                                    displayName)
                                                        // 重置分页状态
                                                        resetPaginationOnFolderChange()
                                                    }
                                                    // 发送给后端, 要请求的数据
                                                    // if (mouse.button === Qt.LeftButton) {
                                                    //     console.log("Request Object by Current Bucket: ",
                                                    //                 model.display)
                                                    //     if (model.display === currentBucket) {
                                                    //         if (model.display !== breadcrumbNav.getCurrentPath(
                                                    //                     )) {
                                                    //             breadcrumbNav.resetToRoot()
                                                    //             ManagerGlobal.refreshObjects(
                                                    //                         model.display)
                                                    //             breadcrumbNav.addPathItem(
                                                    //                         model.display,
                                                    //                         model.display)
                                                    //             mouse.accepted = true
                                                    //         } else {
                                                    //             console.log("点击了当前已选中的桶，仅刷新")
                                                    //             ManagerGlobal.refreshObjects(
                                                    //                         model.display)
                                                    //             mouse.accepted = true
                                                    //         }
                                                    //         return
                                                    //     }
                                                    //     // 修复的代码行
                                                    //     console.log("切换到新桶:",
                                                    //                 model.display)
                                                    //     breadcrumbNav.resetToRoot()
                                                    //     var bucketName = model.display
                                                    //     currentBucket
                                                    //             = bucketName // 直接引用属性，不通过rootItem
                                                    //     bucketListView.currentIndex = index
                                                    //     breadcrumbNav.addPathItem(
                                                    //                 bucketName,
                                                    //                 bucketName)
                                                    //     resetPaginationOnFolderChange()
                                                    //     // 先切换对象模型
                                                    //     switchToObjectsModel(
                                                    //                 model.display)
                                                    //     // 刷新对象的显示问题
                                                    //     // 出现未定义 ???
                                                    //     // if (ManagerGlobal) {
                                                    //     //     ManagerGlobal.refreshObjects(
                                                    //     //                 model.display)
                                                    //     // }
                                                    //     mouse.accepted = true
                                                    // }
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

                                                    // 安全地检查模型数据
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

                                                    // 如果文件名为空或未定义，不显示按钮
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

                                                        // 回退方案：通过文件名判断
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
                                                        // console.log("下载按钮被点击，行:",
                                                        //             row)
                                                        if (!tableView.model) {
                                                            console.error(
                                                                        "表格模型无效")
                                                            return
                                                        }
                                                        // 总行数也是对的
                                                        const totalRows = tableView.model.rowCount()
                                                        // 4. 验证行是否在当前分页范围内（使用显示行索引）
                                                        if (!tableView.isValidRow(
                                                                    row)) {
                                                            console.error(
                                                                        "行不在当前分页范围内:",
                                                                        row)
                                                            return
                                                        }
                                                        // 获取的 diaply 是该 row, 3 对应的 display 数据
                                                        // 加上 model 才正确
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
                                                        // console.log("点击下载按钮选择项目:",
                                                        //             fileInfo.name,
                                                        //             "key:",
                                                        //             fileInfo.key,
                                                        //             "size:",
                                                        //             fileInfo.size)
                                                        rootItem.addDownloadTask(
                                                                    fileInfo)
                                                        downloadPanel.open()
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
                        console.log("更新下载进度:", jobId, progress)
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
    }
    // 在 MainPage.qml 中的下载完成处理函数中添加
    function handleDownloadCompleted(jobId) {
        // 查找对应的下载任务
        for (var i = 0; i < downloadModel.count; i++) {
            var item = downloadModel.get(i)
            if (item.jobId === jobId) {
                // 保存到历史记录
                if (ManagerGlobal && ManagerGlobal.getHistoryManager) {
                    var historyManager = ManagerGlobal.getHistoryManager()
                    if (historyManager) {
                        var record = {
                            "jobId": item.jobId,
                            "fileName": item.fileName,
                            "fileSize": item.fileSize || 0,
                            "bucketName": item.bucketName,
                            "objectKey": item.objectKey,
                            "localPath": item.localPath,
                            "status": "已完成",
                            "startTime": item.startTime || Date.now(),
                            "completedTime": Date.now()
                        }

                        try {
                            historyManager.addDownloadRecord(record)
                            console.log("下载历史保存成功:", item.fileName)
                        } catch (error) {
                            console.error("保存下载历史失败:", error)
                        }
                    }
                }
                break
            }
        }
    }
}

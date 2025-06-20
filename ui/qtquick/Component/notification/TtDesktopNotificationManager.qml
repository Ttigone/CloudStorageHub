import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: notificationManager

    anchors.fill: parent

    property int maxNotifications: 5
    property int spacing: 12
    property int marginRight: 20
    property int marginTop: 20
    property string position: "topRight"

    property var activeNotifications: []
    property int nextId: 1
    property bool geometryInitialized: false
    property int defaultNotificationHeight: 80

    property real lastParentWidth: 0
    property real lastParentHeight: 0

    // 队列管理
    property var pendingNotifications: []
    property bool isProcessingQueue: false

    ParallelAnimation {
        id: slideInAnimationTemplate
        property var targetNotification: null
        property real targetX: 0
        property real targetY: 0

        NumberAnimation {
            target: slideInAnimationTemplate.targetNotification
            property: "x"
            to: slideInAnimationTemplate.targetX
            duration: 300
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: slideInAnimationTemplate.targetNotification
            property: "y"
            to: slideInAnimationTemplate.targetY
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: updateAnimationTemplate
        property var targetNotification: null
        property real targetX: 0
        property real targetY: 0

        NumberAnimation {
            target: updateAnimationTemplate.targetNotification
            property: "x"
            to: updateAnimationTemplate.targetX
            duration: 250
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: updateAnimationTemplate.targetNotification
            property: "y"
            to: updateAnimationTemplate.targetY
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        id: progressUpdateTimer
        interval: 100 // 每100ms更新一次进度
        running: false
        repeat: true

        property var activeProgressNotifications: []

        onTriggered: {
            updateNotificationProgress()
        }

        function startProgressTracking() {
            if (!running && activeProgressNotifications.length > 0) {
                running = true
            }
        }

        function stopProgressTracking() {
            running = false
            activeProgressNotifications = []
        }

        function addNotificationToTrack(notification) {
            if (activeProgressNotifications.indexOf(notification) === -1) {
                activeProgressNotifications.push(notification)
                startProgressTracking()
            }
        }

        function removeNotificationFromTrack(notification) {
            var index = activeProgressNotifications.indexOf(notification)
            if (index !== -1) {
                activeProgressNotifications.splice(index, 1)
            }

            if (activeProgressNotifications.length === 0) {
                stopProgressTracking()
            }
        }
    }

    function isActiveNotificationsValid() {
        return activeNotifications && Array.isArray(activeNotifications)
                && activeNotifications.length !== undefined
    }

    function getActiveNotificationsLength() {
        if (!isActiveNotificationsValid()) {
            activeNotifications = []
            return 0
        }
        return activeNotifications.length
    }

    onWidthChanged: {
        if (geometryInitialized && activeNotifications.length > 0) {
            lastParentWidth = width
            // 实时更新所有通知的X位置
            updateAllNotificationXPositions()
        }
    }

    onHeightChanged: {
        if (geometryInitialized && activeNotifications.length > 0) {
            lastParentHeight = height
            // 实时更新所有通知的Y位置
            updateAllNotificationPositions()
        }
    }
    function updateAllNotificationXPositions() {
        if (!isActiveNotificationsValid() || getActiveNotificationsLength(
                    ) === 0) {
            return
        }

        for (var i = 0; i < activeNotifications.length; i++) {
            var notification = activeNotifications[i]

            if (!notification) {
                continue
            }

            try {
                // 只更新X位置，保持Y位置不变
                var newX = calculateXPosition(notification)
                if (isNaN(newX)) {
                    continue
                }

                if (Math.abs(notification.x - newX) > 5) {
                    createQuickXAnimation(notification, newX)
                } else {
                    notification.x = newX
                }
            } catch (error) {

            }
        }
    }

    function createQuickXAnimation(notification, targetX) {
        var xAnimation = Qt.createQmlObject(`
                                            import QtQuick 2.15
                                            NumberAnimation {
                                            property: "x"
                                            to: ${targetX}
                                            duration: 200
                                            easing.type: Easing.OutCubic
                                            }
                                            `, notificationManager,
                                            "quickXAnimation")

        xAnimation.target = notification
        xAnimation.start()

        xAnimation.finished.connect(function () {
            xAnimation.destroy()
        })
    }
    function updateAllNotificationPositions() {
        if (!isActiveNotificationsValid() || getActiveNotificationsLength(
                    ) === 0) {
            return
        }

        console.log("🔄 更新所有通知位置")

        for (var i = 0; i < activeNotifications.length; i++) {
            var notification = activeNotifications[i]
            if (!notification)
                continue

            // 检查通知对象的必要属性
            if (typeof notification.x === 'undefined'
                    || typeof notification.y === 'undefined'
                    || typeof notification.width === 'undefined'
                    || typeof notification.height === 'undefined') {
                continue
            }

            try {
                var newX = calculateXPosition(notification)
                var newY = calculateYPosition(i)

                if (isNaN(newX) || isNaN(newY)) {
                    console.error("❌ 位置计算结果无效:", {
                                      "newX": newX,
                                      "newY": newY,
                                      "index": i
                                  })
                    continue
                }

                var deltaX = Math.abs(notification.x - newX)
                var deltaY = Math.abs(notification.y - newY)

                // 🔥 使用更灵敏的阈值
                if (deltaX > 3 || deltaY > 3) {
                    createSmoothPositionAnimation(notification, newX, newY)
                } else {
                    notification.x = newX
                    notification.y = newY
                }
            } catch (error) {
                console.error("❌ 更新通知位置时出错:", i, error)
            }
        }
    }
    function calculateXPosition(notification) {
        if (!notification || !parent) {
            console.error("calculateXPosition: notification 或 parent 无效")
            return marginRight
        }

        // 确保 notification.width 有效
        var notificationWidth = (notification.width
                                 && notification.width > 0) ? notification.width : 240 // 默认宽度

        var newX
        switch (position) {
        case "topRight":
        case "bottomRight":
            newX = parent.width - notificationWidth - marginRight
            break
        case "topLeft":
        case "bottomLeft":
            newX = marginRight
            break
        default:
            newX = marginRight
            break
        }

        // 边界检查
        if (isNaN(newX) || newX < 0) {
            newX = marginRight
        } else if (newX + notificationWidth > parent.width) {
            newX = parent.width - notificationWidth - marginRight
        }

        console.log("计算X位置:", newX, "通知宽度:", notificationWidth, "父容器宽度:",
                    parent.width)
        return newX
    }

    function calculateYPosition(index) {
        if (!isActiveNotificationsValid()) {
            activeNotifications = []
            return marginTop
        }

        if (index < 0 || index >= activeNotifications.length) {
            console.warn("calculateYPosition: 索引超出范围:", index, "数组长度:",
                         activeNotifications.length)
            return marginTop
        }

        console.log("calculateYPosition: 计算索引", index, "的Y位置")

        var baseY = position.startsWith(
                    "top") ? marginTop : (parent.height - marginTop)
        var totalHeight = 0

        console.log("  - 基础Y位置:", baseY)
        console.log("  - 当前数组长度:", activeNotifications.length)

        // 🔥 只累加前面的通知高度
        for (var i = 0; i < index; i++) {
            if (i < activeNotifications.length && activeNotifications[i]) {
                var prevNotification = activeNotifications[i]
                var notificationHeight = (prevNotification
                                          && prevNotification.height
                                          > 0) ? prevNotification.height : defaultNotificationHeight

                totalHeight += notificationHeight + spacing
                console.log("  - 累加第", i, "个通知高度:", notificationHeight,
                            "当前累计高度:", totalHeight)
            } else {
                console.warn("  - 跳过无效通知，索引:", i)
            }
        }

        var targetY
        if (position.startsWith("top")) {
            targetY = baseY + totalHeight
        } else {
            var currentNotification = activeNotifications[index]
            var currentHeight = (currentNotification
                                 && currentNotification.height
                                 > 0) ? currentNotification.height : defaultNotificationHeight
            targetY = baseY - totalHeight - currentHeight
        }

        console.log("  - 计算结果: 索引", index, "Y位置:", targetY, "累计高度:",
                    totalHeight)
        return targetY
    }

    function showNotification(options) {
        if (!isActiveNotificationsValid()) {
            activeNotifications = []
        }

        // 🔥 如果正在处理队列或超出最大数量，加入待处理队列
        if (isProcessingQueue || getActiveNotificationsLength(
                    ) >= maxNotifications) {
            pendingNotifications.push(options)
            if (!isProcessingQueue) {
                processQueue()
            }
            return null
        }

        return createAndShowNotification(options)
    }
    function processQueue() {
        if (isProcessingQueue || pendingNotifications.length === 0) {
            return
        }

        console.log("📝 处理通知队列，待处理数量:", pendingNotifications.length)

        isProcessingQueue = true

        // 如果当前通知数量已满，移除最旧的
        if (getActiveNotificationsLength() >= maxNotifications) {
            console.log("📝 通知数量已满，移除最旧的通知")
            removeOldestNotification()

            // 🔥 延迟处理队列，等待移除动画完成
            Qt.callLater(function () {
                continueProcessingQueue()
            })
        } else {
            continueProcessingQueue()
        }
    }
    function continueProcessingQueue() {
        if (pendingNotifications.length > 0) {
            var options = pendingNotifications.shift()
            console.log("📝 从队列中取出通知:", options.title)

            createAndShowNotification(options)
            isProcessingQueue = false

            // 继续处理队列
            if (pendingNotifications.length > 0) {
                Qt.callLater(processQueue)
            }
        } else {
            isProcessingQueue = false
        }
    }
    function removeOldestNotification() {
        if (getActiveNotificationsLength() > 0) {
            var oldestNotification = activeNotifications[0]
            if (oldestNotification) {
                removeNotification(oldestNotification)
            }
        }
    }

    function createAndShowNotification(options) {
        // 清理无效的通知引用
        cleanupNotificationArray()

        console.log("创建通知，当前活动通知数:", activeNotifications.length)

        var notification = notificationComponent.createObject(
                    notificationManager, {
                        "title": options.title || "通知",
                        "message": options.message || "",
                        "type": options.type || "info",
                        "duration": options.duration || 5000,
                        "visible": false,
                        "showProgress": options.showProgress
                                        !== undefined ? options.showProgress : true,
                        "autoClose": options.autoClose !== undefined ? options.autoClose : true,
                        "showCloseButton": options.showCloseButton
                                           !== undefined ? options.showCloseButton : true,
                        "clickable": options.clickable || false,
                        "_isShowing": true
                    })

        if (!notification) {
            console.error("创建通知失败")
            return null
        }

        notification.notificationId = nextId++
        activeNotifications.push(notification)

        // if (notification.closed) {
        //     notification.closed.connect(function() {
        //         removeNotification(notification)
        //     })
        // }
        if (notification.closed) {
            notification.closedConnection = notification.closed.connect(
                        function () {
                            removeNotification(notification)
                        })
        }

        console.log("通知创建成功，ID:", notification.notificationId, "标题:",
                    notification.title)

        Qt.callLater(function () {
            if (!notification) {
                console.error("通知对象在延迟调用时已无效")
                return
            }

            var targetX = calculateXPosition(notification)
            var notificationIndex = activeNotifications.indexOf(notification)
            var targetY = calculateYPosition(notificationIndex)

            console.log("设置通知位置 索引:", notificationIndex, "位置:",
                        targetX, targetY)

            // 🔥 设置初始位置（从右侧滑入）
            notification.x = targetX + (notification.width || 240)
            notification.y = targetY
            notification.visible = true

            // 滑入动画
            createSlideInAnimation(notification, targetX, targetY)

            // 启动进度条
            Qt.callLater(function () {
                if (notification && notification._isShowing
                        && notification.show) {
                    notification.show()
                }
            })
        })

        return notification
    }

    function cleanupNotificationArray() {
        if (!isActiveNotificationsValid()) {
            activeNotifications = []
            return
        }

        var cleanArray = []
        var needsCleanup = false

        for (var i = 0; i < activeNotifications.length; i++) {
            var notification = activeNotifications[i]
            if (notification && notification.visible) {
                cleanArray.push(notification)
            } else {
                needsCleanup = true
                console.log("发现无效通知，索引:", i)
                // 🔥 安全清理无效通知
                if (notification) {
                    cleanupNotificationSafely(notification)
                }
            }
        }

        if (needsCleanup) {
            activeNotifications = cleanArray
            console.log("数组清理完成，有效通知数:", activeNotifications.length)
            gc()
        }
    }

    // 🔥 修复快捷方法
    function showSuccess(title, message, duration, showProgress) {
        return showNotification({
                                    "title": title || "成功",
                                    "message": message || "",
                                    "type": "success",
                                    "duration": duration || 3000,
                                    "showProgress": showProgress
                                                    !== undefined ? showProgress : true,
                                    "autoClose": true
                                })
    }

    function showWarning(title, message, duration, showProgress) {
        return showNotification({
                                    "title": title || "警告",
                                    "message": message || "",
                                    "type": "warning",
                                    "duration": duration || 4000,
                                    "showProgress": showProgress
                                                    !== undefined ? showProgress : true,
                                    "autoClose": true
                                })
    }

    function showError(title, message, duration, showProgress) {
        return showNotification({
                                    "title": title || "错误",
                                    "message": message || "",
                                    "type": "error",
                                    "duration": duration || 5000,
                                    "showProgress": showProgress
                                                    !== undefined ? showProgress : true,
                                    "autoClose": true
                                })
    }

    function showInfo(title, message, duration, showProgress) {
        return showNotification({
                                    "title": title || "信息",
                                    "message": message || "",
                                    "type": "info",
                                    "duration": duration || 3000,
                                    "showProgress": showProgress
                                                    !== undefined ? showProgress : true,
                                    "autoClose": true
                                })
    }

    function createSlideInAnimation(notification, targetX, targetY) {
        if (!notification)
            return

        try {
            slideInAnimationTemplate.targetNotification = notification
            slideInAnimationTemplate.targetX = targetX
            slideInAnimationTemplate.targetY = targetY

            // 🔥 修复信号连接和断开方式
            function onAnimationFinished() {
                slideInAnimationTemplate.targetNotification = null
                // 🔥 不要手动断开连接，让 QML 自动处理
            }

            slideInAnimationTemplate.finished.connect(onAnimationFinished)
            slideInAnimationTemplate.start()
        } catch (error) {
            console.error("创建滑入动画时出错:", error.toString())
            // 直接设置位置
            notification.x = targetX
            notification.y = targetY
        }
    }

    function createMoveAnimation(notification, targetX, targetY) {
        var xAnimation = Qt.createQmlObject(`
                                            import QtQuick 2.15
                                            NumberAnimation {
                                            duration: 300
                                            easing.type: Easing.OutCubic
                                            property: "x"
                                            to: ${targetX}
                                            }
                                            `, notificationManager)

        var yAnimation = Qt.createQmlObject(`
                                            import QtQuick 2.15
                                            NumberAnimation {
                                            duration: 300
                                            easing.type: Easing.OutCubic
                                            property: "y"
                                            to: ${targetY}
                                            }
                                            `, notificationManager)

        xAnimation.target = notification
        yAnimation.target = notification

        xAnimation.start()
        yAnimation.start()

        xAnimation.finished.connect(function () {
            xAnimation.destroy()
        })
        yAnimation.finished.connect(function () {
            yAnimation.destroy()
        })
    }

    function createQuickAnimation(target, property, to, duration) {
        var animation = Qt.createQmlObject(`
                                           import QtQuick 2.15
                                           NumberAnimation {
                                           property: "${property}"
                                           to: ${to}
                                           duration: ${duration || 150}
                                           easing.type: Easing.OutCubic
                                           }
                                           `, target, "quickAnimation")

        animation.start()
        animation.finished.connect(function () {
            animation.destroy()
        })
    }

    function closeAll() {
        if (!isActiveNotificationsValid()) {
            return
        }

        console.log("关闭所有通知，当前数量:", activeNotifications.length)

        if (progressUpdateTimer) {
            progressUpdateTimer.stopProgressTracking()
        }

        // 🔥 安全清理所有通知
        for (var i = activeNotifications.length - 1; i >= 0; i--) {
            var notification = activeNotifications[i]
            if (notification) {
                cleanupNotificationSafely(notification)
            }
        }

        activeNotifications = []
        pendingNotifications = []
        isProcessingQueue = false
        nextId = 1
        gc()

        console.log("所有通知已清理完毕")
    }

    function createPositionUpdateAnimation(notification, targetX, targetY) {
        // 检查是否需要移动
        var deltaX = Math.abs(notification.x - targetX)
        var deltaY = Math.abs(notification.y - targetY)

        if (deltaX < 5 && deltaY < 5) {
            // 位置变化很小，直接设置
            notification.x = targetX
            notification.y = targetY
            return
        }

        // 创建平滑的位置更新动画
        var xAnimation = Qt.createQmlObject(`
                                            import QtQuick 2.15
                                            NumberAnimation {
                                            property: "x"
                                            to: ${targetX}
                                            duration: 250
                                            easing.type: Easing.OutCubic
                                            }
                                            `, notificationManager,
                                            "updateXAnimation")

        var yAnimation = Qt.createQmlObject(`
                                            import QtQuick 2.15
                                            NumberAnimation {
                                            property: "y"
                                            to: ${targetY}
                                            duration: 250
                                            easing.type: Easing.OutCubic
                                            }
                                            `, notificationManager,
                                            "updateYAnimation")

        xAnimation.target = notification
        yAnimation.target = notification

        xAnimation.start()
        yAnimation.start()

        xAnimation.finished.connect(function () {
            xAnimation.destroy()
        })

        yAnimation.finished.connect(function () {
            yAnimation.destroy()
        })
    }

    function removeNotification(notification) {
        if (!notification) {
            console.warn("removeNotification: notification 为空")
            return
        }

        var index = activeNotifications.indexOf(notification)
        if (index === -1) {
            console.warn("removeNotification: 通知不在活动列表中")
            return
        }

        var title = notification.title || "未知通知"
        console.log("移除通知:", title, "索引:", index, "移除前数组长度:",
                    activeNotifications.length)

        // 停止进度跟踪
        if (progressUpdateTimer
                && progressUpdateTimer.removeNotificationFromTrack) {
            progressUpdateTimer.removeNotificationFromTrack(notification)
        }

        // 🔥 先从数组中移除
        activeNotifications.splice(index, 1)
        console.log("从数组中移除完成，新数组长度:", activeNotifications.length)

        // 🔥 立即为剩余通知重新计算并应用新位置（向上移动）
        updateRemainingNotificationsPositionsImmediate()

        // 🔥 然后执行被移除通知的退出动画
        var targetX = (notification.x || 0) + (notification.width || 240)

        try {
            var exitAnimation = Qt.createQmlObject(`
                                                   import QtQuick 2.15
                                                   ParallelAnimation {
                                                   NumberAnimation {
                                                   property: "x"
                                                   to: ${targetX}
                                                   duration: 250
                                                   easing.type: Easing.InCubic
                                                   }
                                                   NumberAnimation {
                                                   property: "opacity"
                                                   to: 0
                                                   duration: 200
                                                   easing.type: Easing.InCubic
                                                   }
                                                   }
                                                   `, notificationManager)

            if (exitAnimation) {
                exitAnimation.target = notification
                exitAnimation.start()

                exitAnimation.finished.connect(function () {
                    console.log("通知退出动画完成，开始清理")
                    cleanupNotificationSafely(notification)

                    if (exitAnimation) {
                        exitAnimation.destroy()
                        exitAnimation = null
                    }

                    gc()

                    if (pendingNotifications.length > 0) {
                        Qt.callLater(processQueue)
                    }
                })
            } else {
                cleanupNotificationSafely(notification)
            }
        } catch (error) {
            console.error("创建退出动画时出错:", error.toString())
            cleanupNotificationSafely(notification)
        }
    }

    function updateRemainingNotificationsPositionsImmediate() {
        if (!isActiveNotificationsValid() || getActiveNotificationsLength(
                    ) === 0) {
            console.log("没有需要更新的通知")
            return
        }

        console.log("立即更新剩余通知位置，当前数量:", activeNotifications.length)

        // 🔥 为每个剩余通知重新计算位置
        for (var i = 0; i < activeNotifications.length; i++) {
            var notification = activeNotifications[i]
            if (!notification) {
                console.warn("通知对象无效，索引:", i)
                continue
            }

            if (typeof notification.x === 'undefined'
                    || typeof notification.y === 'undefined') {
                console.warn("通知对象缺少位置属性，索引:", i)
                continue
            }

            try {
                var newX = calculateXPosition(notification)
                var newY = calculateYPosition(i) // 🔥 使用新的索引重新计算Y位置

                if (isNaN(newX) || isNaN(newY)) {
                    console.error("位置计算结果无效:", newX, newY, "索引:", i)
                    continue
                }

                console.log("通知", i, "标题:", notification.title || "未知")
                console.log("  - 当前位置:", notification.x, notification.y)
                console.log("  - 目标位置:", newX, newY)

                var deltaX = Math.abs(notification.x - newX)
                var deltaY = Math.abs(notification.y - newY)

                console.log("  - 位置变化: X =", deltaX, "Y =", deltaY)

                // 🔥 如果Y位置需要向上移动，立即启动动画
                if (deltaY > 5) {
                    console.log("通知", i, "需要向上移动，Y变化:", deltaY)
                    createUpwardMoveAnimation(notification, newX, newY)
                } else if (deltaX > 5) {
                    // 只有X位置变化
                    createSmoothPositionAnimation(notification, newX, newY)
                } else {
                    // 位置变化很小，直接设置
                    notification.x = newX
                    notification.y = newY
                }
            } catch (error) {
                console.error("更新通知位置时出错:", error.toString())
            }
        }
    }
    function createUpwardMoveAnimation(notification, targetX, targetY) {
        if (!notification) {
            console.error("createUpwardMoveAnimation: notification 无效")
            return
        }

        if (isNaN(targetX) || isNaN(targetY)) {
            console.error("createUpwardMoveAnimation: 目标位置无效", targetX, targetY)
            return
        }

        console.log("创建向上移动动画，目标位置:", targetX, targetY)

        try {
            var upwardAnimation = Qt.createQmlObject(`
                                                     import QtQuick 2.15
                                                     ParallelAnimation {
                                                     NumberAnimation {
                                                     property: "x"
                                                     to: ${targetX}
                                                     duration: 300
                                                     easing.type: Easing.OutCubic
                                                     }
                                                     NumberAnimation {
                                                     property: "y"
                                                     to: ${targetY}
                                                     duration: 350
                                                     easing.type: Easing.OutCubic
                                                     }
                                                     }
                                                     `, notificationManager)

            if (!upwardAnimation) {
                console.error("创建向上移动动画失败")
                notification.x = targetX
                notification.y = targetY
                return
            }

            upwardAnimation.target = notification
            upwardAnimation.start()

            console.log("向上移动动画已启动")

            upwardAnimation.finished.connect(function () {
                console.log("向上移动动画完成")
                if (upwardAnimation) {
                    upwardAnimation.destroy()
                    upwardAnimation = null
                }
            })

            upwardAnimation.stopped.connect(function () {
                if (upwardAnimation) {
                    upwardAnimation.destroy()
                    upwardAnimation = null
                }
            })
        } catch (error) {
            console.error("创建向上移动动画时出错:", error.toString())
            notification.x = targetX
            notification.y = targetY
        }
    }

    function cleanupNotificationSafely(notification) {
        if (!notification)
            return

        try {
            // 停止进度跟踪
            if (progressUpdateTimer
                    && progressUpdateTimer.removeNotificationFromTrack) {
                progressUpdateTimer.removeNotificationFromTrack(notification)
            }

            // 🔥 直接销毁对象，QML 会自动断开信号连接
            notification.destroy()
            notification = null
        } catch (error) {
            console.error("清理通知对象时出错:", error.toString())
        }
    }
    function createSimpleSlideInAnimation(notification, targetX, targetY) {
        if (!notification)
            return

        try {
            // 创建独立的动画对象
            var slideAnimation = Qt.createQmlObject(`
                                                    import QtQuick 2.15
                                                    ParallelAnimation {
                                                    NumberAnimation {
                                                    property: "x"
                                                    to: ${targetX}
                                                    duration: 300
                                                    easing.type: Easing.OutCubic
                                                    }
                                                    NumberAnimation {
                                                    property: "y"
                                                    to: ${targetY}
                                                    duration: 200
                                                    easing.type: Easing.OutCubic
                                                    }
                                                    }
                                                    `, notificationManager)

            if (slideAnimation) {
                slideAnimation.target = notification
                slideAnimation.start()

                slideAnimation.finished.connect(function () {
                    if (slideAnimation) {
                        slideAnimation.destroy()
                        slideAnimation = null
                    }
                })
            }
        } catch (error) {
            console.error("创建简单滑入动画失败:", error.toString())
            notification.x = targetX
            notification.y = targetY
        }
    }

    function updateRemainingNotificationsPositions() {
        // 使用立即更新版本
        updateRemainingNotificationsPositionsImmediate()
    }

    function cleanupNotification(notification) {
        if (!notification)
            return

        try {
            // 停止进度跟踪
            if (progressUpdateTimer
                    && progressUpdateTimer.removeNotificationFromTrack) {
                progressUpdateTimer.removeNotificationFromTrack(notification)
            }

            // 🔥 不要手动断开信号连接，让对象销毁时自动处理
            // 直接销毁对象
            notification.destroy()
            notification = null

            // 强制垃圾回收
            gc()

            // 处理待处理队列
            if (pendingNotifications.length > 0) {
                Qt.callLater(processQueue)
            }
        } catch (error) {
            console.error("清理通知对象时出错:", error.toString())
        }
    }

    function createSmoothPositionAnimation(notification, targetX, targetY) {
        if (!notification) {
            console.error("createSmoothPositionAnimation: notification 无效")
            return
        }

        if (isNaN(targetX) || isNaN(targetY)) {
            console.error("createSmoothPositionAnimation: 目标位置无效",
                          targetX, targetY)
            return
        }

        try {
            var positionAnimation = Qt.createQmlObject(`
                                                       import QtQuick 2.15
                                                       ParallelAnimation {
                                                       NumberAnimation {
                                                       property: "x"
                                                       to: ${targetX}
                                                       duration: 250
                                                       easing.type: Easing.OutCubic
                                                       }
                                                       NumberAnimation {
                                                       property: "y"
                                                       to: ${targetY}
                                                       duration: 300
                                                       easing.type: Easing.OutCubic
                                                       }
                                                       }
                                                       `, notificationManager)

            if (!positionAnimation) {
                console.error("创建位置动画失败")
                notification.x = targetX
                notification.y = targetY
                return
            }

            positionAnimation.target = notification
            positionAnimation.start()

            // 🔥 确保动画对象被正确销毁
            positionAnimation.finished.connect(function () {
                if (positionAnimation) {
                    positionAnimation.destroy()
                    positionAnimation = null
                }
            })

            // 🔥 添加停止处理
            positionAnimation.stopped.connect(function () {
                if (positionAnimation) {
                    positionAnimation.destroy()
                    positionAnimation = null
                }
            })
        } catch (error) {
            console.error("创建位置动画时出错:", error.toString())
            notification.x = targetX
            notification.y = targetY
        }
    }

    function positionNotification(notification) {
        var newX = calculateXPosition(notification)
        var newY = marginTop
        notification.x = newX
        notification.y = newY
    }

    function updateNotificationPositions() {
        if (!isActiveNotificationsValid()) {
            return
        }

        for (var i = 0; i < activeNotifications.length; i++) {
            var notification = activeNotifications[i]
            if (!notification)
                continue

            var targetY = calculateYPosition(i)

            if (Math.abs(notification.y - targetY) > 5) {
                createQuickAnimation(notification, "y", targetY, 150)
            } else {
                notification.y = targetY
            }
        }
    }

    NumberAnimation {
        id: moveAnimation
        property: "y"
        duration: 300
        easing.type: Easing.OutCubic
    }

    Component {
        id: notificationComponent
        TtDesktopNotification {
            property int notificationId: 0
            onClosed: {
                removeNotification(this)
            }
        }
    }

    Component.onCompleted: {
        geometryInitialized = true
        lastParentWidth = width
        lastParentHeight = height
    }
}

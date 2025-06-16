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

    function isActiveNotificationsValid() {
        return activeNotifications && Array.isArray(activeNotifications)
                && activeNotifications.length !== undefined
    }

    function getActiveNotificationsLength() {
        if (!isActiveNotificationsValid()) {
            console.warn("⚠️ activeNotifications 数组无效，重新初始化")
            activeNotifications = []
            return 0
        }
        return activeNotifications.length
    }

    onWidthChanged: {
        if (geometryInitialized && getActiveNotificationsLength() > 0) {
            updateAllNotificationPositions()
        }
    }

    onHeightChanged: {
        if (geometryInitialized && getActiveNotificationsLength() > 0) {
            updateAllNotificationPositions()
        }
    }

    // function updateAllNotificationPositions() {
    //     if (!isActiveNotificationsValid() || getActiveNotificationsLength(
    //                 ) === 0) {
    //         console.log("📝 没有活跃通知需要更新位置")
    //         return
    //     }

    //     console.log("🔄 实时更新所有通知位置，活跃通知数:", getActiveNotificationsLength())

    //     for (var i = 0; i < activeNotifications.length; i++) {
    //         var notification = activeNotifications[i]

    //         if (!notification) {
    //             console.error("❌ 通知对象为 null:", i)
    //             continue
    //         }

    //         // 检查通知对象的必要属性
    //         if (typeof notification.x === 'undefined'
    //                 || typeof notification.y === 'undefined'
    //                 || typeof notification.width === 'undefined'
    //                 || typeof notification.height === 'undefined') {
    //             console.error("❌ 通知对象缺少必要属性:", i)
    //             continue
    //         }

    //         try {
    //             var newX = calculateXPosition(notification)
    //             var newY = calculateYPosition(i)

    //             if (isNaN(newX) || isNaN(newY)) {
    //                 console.error("❌ 位置计算结果无效:", {
    //                                   "newX"// 直接设置新位置
    //                                   // 🔥 使用安全的数组检查
    //                                   // 使用默认高度
    //                                   // 🔥 确保数组有效

    //                                   // 限制同时显示的通知数量

    //                                   // 设置通知ID

    //                                   // 🔥 等待组件完全初始化后再设置位置
    //                                   // 计算初始位置

    //                                   // 🔥 不使用 _targetX 属性，直接设置位置
    //                                   // 从右侧开始动画

    //                                   // 添加到活动通知列表

    //                                   // 显示通知（包含入场动画到正确位置）

    //                                   // 🔥 使用动画移动到最终位置

    //                                   // 🔥 创建移动动画函数

    //                                   // 清理动画对象

    //                                   // 🔥 添加缺失的 createQuickAnimation 函数
    //                                   // 🔥 安全关闭所有通知
    //                                   // 🔥 安全移除通知
    //                                   // 实时更新剩余通知位置
    //                                   // 🔥 确保数组正确初始化
    //                                   : newX,
    //                                   "newY": newY,
    //                                   "index": i
    //                               })
    //                 continue
    //             }
    //             notification.x = newX
    //             notification.y = newY

    //             console.log("✅ 更新通知位置:", i, "->", newX, newY)
    //         } catch (error) {
    //             console.error("❌ 更新通知位置时出错:", i, error)
    //         }
    //     }
    // }
    function updateAllNotificationPositions() {
        if (!isActiveNotificationsValid() || getActiveNotificationsLength(
                    ) === 0) {
            console.log("📝 没有活跃通知需要更新位置")
            return
        }

        console.log("🔄 更新所有通知位置，活跃通知数:", getActiveNotificationsLength())

        // 🔥 分批更新，避免同时更新造成的闪烁
        for (var i = 0; i < activeNotifications.length; i++) {
            var notification = activeNotifications[i]

            if (!notification) {
                console.error("❌ 通知对象为 null:", i)
                continue
            }

            // 检查通知对象的必要属性
            if (typeof notification.x === 'undefined'
                    || typeof notification.y === 'undefined'
                    || typeof notification.width === 'undefined'
                    || typeof notification.height === 'undefined') {
                console.error("❌ 通知对象缺少必要属性:", i)
                continue
            }

            try {
                var newX = calculateXPosition(notification)
                var newY = calculateYPosition(i)

                if (isNaN(newX) || isNaN(newY)) {
                    console.error("❌ 位置计算结果无效:", {
                                      "newX"// 🔥 使用动画更新位置，让重排更自然

                                      // function calculateYPosition(index) {
                                      //     if (!isActiveNotificationsValid()) {
                                      //         console.error("❌ activeNotifications 数组无效，重新初始化")
                                      //         activeNotifications = []
                                      //         return marginTop
                                      //     }

                                      //     if (index < 0 || index >= activeNotifications.length) {
                                      //         console.error("❌ index 超出范围:", index, "数组长度:",
                                      //                       activeNotifications.length)
                                      //         return marginTop
                                      //     }

                                      //     var baseY = position.startsWith(
                                      //                 "top") ? marginTop : (parent.height - marginTop)
                                      //     var totalHeight = 0

                                      //     for (var i = 0; i <= index; i++) {
                                      //         if (i < activeNotifications.length && activeNotifications[i]) {
                                      //             var notification = activeNotifications[i]

                                      //             if (notification
                                      //                     && typeof notification.height !== 'undefined') {
                                      //                 totalHeight += notification.height + (i > 0 ? spacing : 0)
                                      //             } else {
                                      //                 console.error("❌ 通知对象无效或缺少 height 属性:", i)
                                      //                 totalHeight += 80 + (i > 0 ? spacing : 0)
                                      //             }
                                      //         }
                                      //     }

                                      //     var targetNotification = activeNotifications[index]
                                      //     if (!targetNotification
                                      //             || typeof targetNotification.height === 'undefined') {
                                      //         console.error("❌ 目标通知无效:", index)
                                      //         return baseY
                                      //     }

                                      //     if (position.startsWith("top")) {
                                      //         return baseY + totalHeight - targetNotification.height
                                      //     } else {
                                      //         return baseY - totalHeight
                                      //     }
                                      // }

                                      // 🔥 改进的高度计算，确保即使在初始化期间也能正确排列

                                      // 🔥 使用实际高度或默认高度
                                      // 🔥 获取当前通知的高度
                                      // 🔥 先添加到数组，再计算位置

                                      // Qt.callLater(function () {
                                      //     try {
                                      //         var initialX = calculateXPosition(notification)
                                      //         var initialY = calculateYPosition(activeNotifications.length)
                                      //         notification.x = parent.width
                                      //         notification.y = initialY
                                      //         activeNotifications.push(notification)
                                      //         notification.show()
                                      //         createMoveAnimation(notification, initialX, initialY)

                                      //         console.log("📢 通知显示完成:", options.title)
                                      //     } catch (error) {
                                      //         console.error("❌ 设置通知位置时出错:", error)
                                      //         if (notification) {
                                      //             notification.destroy()
                                      //         }
                                      //     }
                                      // })
                                      // 🔥 使用延迟确保组件完全初始化
                                      // 重新计算当前通知的索引（因为可能在等待期间有变化）

                                      // 计算正确位置

                                      // 🔥 设置初始位置（从右侧飞入）
                                      // 从屏幕右侧外开始
                                      // 但Y位置要正确

                                      // 显示通知（会触发飞入动画）

                                      // 🔥 创建飞入动画到正确X位置
                                      // 从数组中移除失败的通知
                                      // 移动进入动画
                                      // function createSlideInAnimation(notification, targetX, targetY) {
                                      //     var slideAnimation = Qt.createQmlObject(`
                                      //         import QtQuick 2.15
                                      //         ParallelAnimation {
                                      //             NumberAnimation {
                                      //                 target: notification
                                      //                 property: "x"
                                      //                 to: ${targetX}
                                      //                 duration: 300
                                      //                 easing.type: Easing.OutCubic
                                      //             }
                                      //             NumberAnimation {
                                      //                 target: notification
                                      //                 property: "y"
                                      //                 to: ${targetY}
                                      //                 duration: 200
                                      //                 easing.type: Easing.OutCubic
                                      //             }
                                      //         }
                                      //     `, notificationManager, "slideInAnimation")

                                      //     slideAnimation.start()
                                      //     slideAnimation.finished.connect(function() {
                                      //         slideAnimation.destroy()
                                      //     })
                                      // }
                                      // 🔥 替代方案：使用 JavaScript 创建动画组件
                                      // 🔥 创建 X 轴动画

                                      // 🔥 创建 Y 轴动画

                                      // 🔥 设置动画参数

                                      // 🔥 启动动画

                                      // 🔥 清理

                                      //  function createPositionUpdateAnimation(notification, targetX, targetY) {
                                      //         // 检查是否需要移动
                                      //         var deltaX = Math.abs(notification.x - targetX)
                                      //         var deltaY = Math.abs(notification.y - targetY)

                                      //         if (deltaX < 5 && deltaY < 5) {
                                      //             // 位置变化很小，直接设置
                                      //             notification.x = targetX
                                      //             notification.y = targetY
                                      //             return
                                      //         }

                                      //         // 创建平滑的位置更新动画
                                      //         var updateAnimation = Qt.createQmlObject(`
                                      //             import QtQuick 2.15
                                      //             ParallelAnimation {
                                      //                 NumberAnimation {
                                      //                     target: notification
                                      //                     property: "x"
                                      //                     to: ${targetX}
                                      //                     duration: 250
                                      //                     easing.type: Easing.OutCubic
                                      //                 }
                                      //                 NumberAnimation {
                                      //                     target: notification
                                      //                     property: "y"
                                      //                     to: ${targetY}
                                      //                     duration: 250
                                      //                     easing.type: Easing.OutCubic
                                      //                 }
                                      //             }
                                      //         `, notificationManager, "updateAnimation")

                                      //         updateAnimation.start()
                                      //         updateAnimation.finished.connect(function() {
                                      //             updateAnimation.destroy()
                                      //         })
                                      //     }
                                      // 🔥 修复位置更新动画函数
                                      // 检查是否需要移动
                                      // 位置变化很小，直接设置

                                      // 🔥 修复：分别创建动画

                                      // 设置动画参数

                                      // 启动动画

                                      // 清理

                                      // 🔥 延迟更新位置，让退场动画完成
                                      : newX,
                                      "newY": newY,
                                      "index": i
                                  })
                    continue
                }
                createPositionUpdateAnimation(notification, newX, newY)

                console.log("✅ 更新通知位置:", i, "->", newX, newY)
            } catch (error) {
                console.error("❌ 更新通知位置时出错:", i, error)
            }
        }
    }

    function calculateXPosition(notification) {
        switch (position) {
        case "topRight":
        case "bottomRight":
            return parent.width - notification.width - marginRight
        case "topLeft":
        case "bottomLeft":
            return marginRight
        default:
            return marginRight
        }
    }
    function calculateYPosition(index) {
        if (!isActiveNotificationsValid()) {
            console.error("❌ activeNotifications 数组无效，重新初始化")
            activeNotifications = []
            return marginTop
        }

        if (index < 0 || index >= activeNotifications.length) {
            console.error("❌ index 超出范围:", index, "数组长度:",
                          activeNotifications.length)
            return marginTop
        }

        var baseY = position.startsWith(
                    "top") ? marginTop : (parent.height - marginTop)
        var totalHeight = 0
        for (var i = 0; i < index; i++) {
            if (i < activeNotifications.length && activeNotifications[i]) {
                var notification = activeNotifications[i]
                var notificationHeight = (notification && notification.height
                                          > 0) ? notification.height : defaultNotificationHeight

                totalHeight += notificationHeight + spacing

                console.log("📏 计算位置 - 通知", i, "高度:", notificationHeight,
                            "累计高度:", totalHeight)
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

        console.log("📍 计算Y位置 - 索引:", index, "结果:", targetY, "总高度:",
                    totalHeight)
        return targetY
    }

    function showNotification(options) {
        if (!isActiveNotificationsValid()) {
            console.warn("⚠️ 重新初始化 activeNotifications 数组")
            activeNotifications = []
        }
        if (getActiveNotificationsLength() >= maxNotifications) {
            if (getActiveNotificationsLength() > 0 && activeNotifications[0]) {
                activeNotifications[0].close()
            }
        }

        var notification = notificationComponent.createObject(
                    notificationManager, {
                        "title": options.title || "通知",
                        "message": options.message || "",
                        "type": options.type || "info",
                        "duration": options.duration !== undefined ? options.duration : 4000,
                        "showCloseButton": options.showCloseButton
                                           !== undefined ? options.showCloseButton : true,
                        "showIcon": options.showIcon !== undefined ? options.showIcon : true,
                        "clickable": options.clickable || false,
                        "onClicked": options.onClicked || null,
                        "onClosed": function () {
                            removeNotification(notification)
                            if (options.onClosed) {
                                options.onClosed()
                            }
                        }
                    })
        if (!notification) {
            console.error("❌ 无法创建通知组件")
            return null
        }
        notification.notificationId = nextId++
        activeNotifications.push(notification)
        Qt.callLater(function () {
            try {
                var currentIndex = activeNotifications.indexOf(notification)
                if (currentIndex === -1) {
                    console.error("❌ 通知已被移除")
                    return
                }
                var finalX = calculateXPosition(notification)
                var finalY = calculateYPosition(currentIndex)
                notification.x = parent.width + 20
                notification.y = finalY
                notification.show()
                createSlideInAnimation(notification, finalX, finalY)

                console.log("📢 通知显示完成:", options.title, "位置:", finalX, finalY)
            } catch (error) {
                console.error("❌ 设置通知位置时出错:", error)
                var failedIndex = activeNotifications.indexOf(notification)
                if (failedIndex >= 0) {
                    activeNotifications.splice(failedIndex, 1)
                }
                if (notification) {
                    notification.destroy()
                }
            }
        })

        return notification
    }
    // function createSlideInAnimation(notification, targetX, targetY) {
    //     var xAnimation = Qt.createQmlObject(
    //                 'import QtQuick 2.15; NumberAnimation { property: "x"; duration: 300; easing.type: Easing.OutCubic }',
    //                 notificationManager, "slideInXAnimation")
    //     var yAnimation = Qt.createQmlObject(
    //                 'import QtQuick 2.15; NumberAnimation { property: "y"; duration: 200; easing.type: Easing.OutCubic }',
    //                 notificationManager, "slideInYAnimation")
    //     xAnimation.target = notification
    //     xAnimation.to = targetX

    //     yAnimation.target = notification
    //     yAnimation.to = targetY
    //     xAnimation.start()
    //     yAnimation.start()
    //     xAnimation.finished.connect(function () {
    //         xAnimation.destroy()
    //     })

    //     yAnimation.finished.connect(function () {
    //         yAnimation.destroy()
    //     })

    //     console.log("🎬 滑入动画已启动:", targetX, targetY)
    // }
    // 🔥 使用预定义动画的函数
    function createSlideInAnimation(notification, targetX, targetY) {
        slideInAnimationTemplate.targetNotification = notification
        slideInAnimationTemplate.targetX = targetX
        slideInAnimationTemplate.targetY = targetY
        slideInAnimationTemplate.start()

        console.log("🎬 滑入动画已启动:", targetX, targetY)
    }

    function createMoveAnimation(notification, targetX, targetY) {
        var xAnimation = Qt.createQmlObject(`
                                            import QtQuick 2.15
                                            NumberAnimation {
                                            target: null
                                            property: "x"
                                            to: ${targetX}
                                            duration: 300
                                            easing.type: Easing.OutCubic
                                            }
                                            `, notificationManager,
                                            "xAnimation")

        xAnimation.target = notification
        xAnimation.start()
        xAnimation.finished.connect(function () {
            xAnimation.destroy()
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

    function showSuccess(title, message, duration) {
        return showNotification({
                                    "title": title,
                                    "message": message,
                                    "type": "success",
                                    "duration": duration
                                })
    }

    function showWarning(title, message, duration) {
        return showNotification({
                                    "title": title,
                                    "message": message,
                                    "type": "warning",
                                    "duration": duration
                                })
    }

    function showError(title, message, duration) {
        return showNotification({
                                    "title": title,
                                    "message": message,
                                    "type": "error",
                                    "duration": duration !== undefined ? duration : 6000
                                })
    }

    function showInfo(title, message, duration) {
        return showNotification({
                                    "title": title,
                                    "message": message,
                                    "type": "info",
                                    "duration": duration
                                })
    }

    function closeAll() {
        if (!isActiveNotificationsValid()) {
            return
        }

        for (var i = activeNotifications.length - 1; i >= 0; i--) {
            if (activeNotifications[i]) {
                activeNotifications[i].close()
            }
        }
    }
    // function createPositionUpdateAnimation(notification, targetX, targetY) {
    //     var deltaX = Math.abs(notification.x - targetX)
    //     var deltaY = Math.abs(notification.y - targetY)

    //     if (deltaX < 5 && deltaY < 5) {
    //         notification.x = targetX
    //         notification.y = targetY
    //         return
    //     }
    //     var xAnimation = Qt.createQmlObject(
    //                 'import QtQuick 2.15; NumberAnimation { property: "x"; duration: 250; easing.type: Easing.OutCubic }',
    //                 notificationManager, "updateXAnimation")

    //     var yAnimation = Qt.createQmlObject(
    //                 'import QtQuick 2.15; NumberAnimation { property: "y"; duration: 250; easing.type: Easing.OutCubic }',
    //                 notificationManager, "updateYAnimation")
    //     xAnimation.target = notification
    //     xAnimation.to = targetX

    //     yAnimation.target = notification
    //     yAnimation.to = targetY
    //     xAnimation.start()
    //     yAnimation.start()
    //     xAnimation.finished.connect(function () {
    //         xAnimation.destroy()
    //     })

    //     yAnimation.finished.connect(function () {
    //         yAnimation.destroy()
    //     })
    // }
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

        updateAnimationTemplate.targetNotification = notification
        updateAnimationTemplate.targetX = targetX
        updateAnimationTemplate.targetY = targetY
        updateAnimationTemplate.start()
    }

    function removeNotification(notification) {
        if (!isActiveNotificationsValid()) {
            console.warn("⚠️ activeNotifications 数组无效，无法移除通知")
            return
        }

        var index = activeNotifications.indexOf(notification)
        if (index >= 0) {
            activeNotifications.splice(index, 1)
            Qt.callLater(function () {
                updateAllNotificationPositions()
            })
        }
    }

    function positionNotification(notification) {
        var newX = calculateXPosition(notification)
        var newY = marginTop

        notification.x = newX
        notification.y = newY

        console.log("📍 初始通知位置:", notification.notificationId, newX, newY)
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

            Component.onCompleted: {
                console.log("📋 通知组件创建完成")
            }
        }
    }

    Component.onCompleted: {
        activeNotifications = []
        geometryInitialized = true
        console.log("📱 通知管理器初始化完成:", width, "x", height)
    }
}

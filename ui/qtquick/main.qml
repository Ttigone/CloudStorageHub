import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import Qt.labs.platform 1.1
import QWindowKit 1.0

import "./Component"

Window {
    property bool showWhenReady: true
    property var mainPageInstance: null
    property bool oneInit: false

    id: window
    width: 960
    height: 720
    color: darkStyle.windowBackgroundColor
    title: qsTr("Cloud Storage Hub")

    Component.onCompleted: {
        // 显示后, 才会
        // 默认显示的
        console.log("代理设置窗口")
        windowAgent.setup(window)
        windowAgent.setWindowAttribute("dark-mode", true)
        showLoginDialog() // 使用函数代替内联代码
    }

    QtObject {
        id: lightStyle
    }

    QtObject {
        id: darkStyle
        readonly property color windowBackgroundColor: "#1E1E1E"
    }

    WindowAgent {
        id: windowAgent
    }

    Rectangle {
        id: titleBar
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: 32
        color: window.active ? "#3C3C3C" : "#505050"
        // color: "transparent"
        // color: "#2D2D2D" // 深灰色背景而非透明
        // 添加底部边框线
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 1
            color: "#505050" // 蓝色分隔线
            opacity: 0.5
        }
        Component.onCompleted: windowAgent.setTitleBar(titleBar)
        z: 100

        Image {
            id: iconButton
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                leftMargin: 10
            }
            width: 18
            height: 18
            mipmap: true
            source: "qrc:/resources/app/storage.png"
            fillMode: Image.PreserveAspectFit
            Component.onCompleted: windowAgent.setSystemButton(
                                       WindowAgent.WindowIcon, iconButton)
        }

        Text {
            anchors {
                verticalCenter: parent.verticalCenter
                left: iconButton.right
                leftMargin: 10
            }
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: window.title
            font.pixelSize: 14
            color: "#ECECEC"
        }

        Row {
            anchors {
                top: parent.top
                right: parent.right
            }
            height: parent.height

            QWKButton {
                id: minButton
                height: parent.height
                source: "qrc:/resources/window-bar/minimize.svg"
                onClicked: window.showMinimized()
                Component.onCompleted: windowAgent.setSystemButton(
                                           WindowAgent.Minimize, minButton)
            }

            QWKButton {
                id: maxButton
                height: parent.height
                source: window.visibility === Window.Maximized ? "qrc:/resources/window-bar/restore.svg" : "qrc:/resources/window-bar/maximize.svg"
                onClicked: {
                    if (window.visibility === Window.Maximized) {
                        window.showNormal()
                    } else {
                        window.showMaximized()
                    }
                }
                Component.onCompleted: windowAgent.setSystemButton(
                                           WindowAgent.Maximize, maxButton)
            }

            QWKButton {
                id: closeButton
                height: parent.height
                source: "qrc:/resources/window-bar/close.svg"
                background: Rectangle {
                    color: {
                        if (!closeButton.enabled) {
                            return "gray"
                        }
                        if (closeButton.pressed) {
                            return "#e81123"
                        }
                        if (closeButton.hovered) {
                            return "#e81123"
                        }
                        return "transparent"
                    }
                }
                onClicked: {
                    // console.log("点击关闭按钮")
                    window.close()
                }
                Component.onCompleted: windowAgent.setSystemButton(
                                           WindowAgent.Close, closeButton)
            }
        }
    }

    // 添加LoadingOverlay
    LoadingOverlay {
        id: loadingOverlay
        anchors {
            top: titleBar.bottom // 从标题栏下方开始，而不是覆盖整个窗口
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        z: 999 // 确保在最上层
        message: "正在准备您的云空间..."
        active: false
    }

    // 占位容器, 放置 MainPage, 确保登录成功后, 才会创建
    Item {
        id: mainPageContainer
        anchors {
            top: titleBar.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
    }

    function showLoginDialog() {
        // 确保窗口内容已清理干净
        // dialog 收到 加载页面影响 ???
        var component = Qt.createComponent("LoginDialog.qml")
        if (component.status === Component.Ready) {
            var dialog = component.createObject(null)
            dialog.visible = true
            loadingOverlay.visible = false
            // 登录成功
            dialog.onLoginSuccess.connect(function () {
                console.log("登录成功")
                // 登录成功
                dialog.visible = false
                dialog.destroy() // 销毁登录对话框
                createMainPage()
            })
            dialog.onCancelled.connect(function () {
                dialog.destroy()
                Qt.quit()
            })
        } else {
            console.log("登录对话框加载失败: " + component.errorString())
        }
    }

    function createMainPage() {
        window.visible = false
        mainPageContainer.visible = false // 隐藏容器以防止旧内容闪现
        console.info("显示动画")
        loadingOverlay.active = true
        loadingOverlay.visible = true
        loadingOverlay.message = "正在准备您的云空间..."

        // 确保清理旧实例
        if (mainPageInstance != null) {
            mainPageInstance.parent = null // 先从父容器中移除
            mainPageInstance.destroy()
            mainPageInstance = null
        }

        console.info("创建组件实例")
        var component = Qt.createComponent("MainPage.qml")

        // 组件状态检查
        if (component.status === Component.Error) {
            // 处理组件加载错误
            console.error("组件加载错误:", component.errorString())
            loadingOverlay.active = false
            loadingOverlay.message = "加载失败: " + component.errorString()
            return
        }

        // 等待组件准备好
        if (component.status === Component.Loading) {
            component.statusChanged.connect(function () {
                if (component.status === Component.Ready) {
                    finishCreateMainPage(component)
                } else if (component.status === Component.Error) {
                    console.error("组件加载错误:", component.errorString())
                    loadingOverlay.active = false
                    loadingOverlay.message = "加载失败: " + component.errorString()
                }
            })
        } else if (component.status === Component.Ready) {
            finishCreateMainPage(component)
        }
    }

    // 将创建实例和连接信号的逻辑分离到一个新函数
    function finishCreateMainPage(component) {
        try {
            // 创建了 MainPage 实例
            mainPageInstance = component.createObject(mainPageContainer)

            if (!mainPageInstance) {
                console.error("无法创建 MainPage 实例")
                loadingOverlay.active = false
                return
            }

            console.log("创建实例完成")
            mainPageInstance.visible = false

            // mainPageConnection.target = mainPageInstance
            mainPageConnections.target = mainPageInstance
            console.log("✅ Connections 目标设置完成")

            // 现在加载动画和标题栏都已准备好，可以显示窗口了
            if (window.showWhenReady) {
                console.info("现在可以安全显示窗口 - 标题栏和加载动画已准备")
                window.visible = true
            }

            // 连接初始化完成信号
            mainPageInstance.initializationCompleted.connect(function () {
                if (!oneInit) {
                    console.info("初始化完成-------------")
                    // 显示 mainpage 窗口
                    mainPageContainer.visible = true
                    mainPageInstance.visible = true
                    loadingOverlay.active = false

                    // 使用延迟隐藏，确保淡出动画完成
                    let hideTimer = Qt.createQmlObject(
                            'import QtQuick; Timer {interval: 300; running: true; repeat: false;}',
                            window)

                    hideTimer.triggered.connect(function () {
                        // 完全隐藏 LoadingOverlay 组件
                        loadingOverlay.visible = false
                        console.log("LoadingOverlay 已隐藏")
                    })
                    oneInit = true
                }
            })
            // 设置连接目标
            // connectionsComponent.target = mainPageInstance

            // 连接其他信号
            // connectMainPageSignals()

            // 添加超时保护，确保界面最终会显示出来
            let timeoutTimer = Qt.createQmlObject(
                    'import QtQuick; Timer {interval: 5000; running: true; repeat: false;}',
                    window)

            timeoutTimer.triggered.connect(function () {
                console.warn("初始化超时，检查状态...")
                console.warn("mainPageInstance:",
                             mainPageInstance ? "存在" : "不存在")
                console.warn("loadingOverlay.active:", loadingOverlay.active)
                console.warn("mainPageContainer.visible:",
                             mainPageContainer.visible)

                if (loadingOverlay.active) {
                    console.warn("初始化超时，强制显示界面")
                    mainPageContainer.visible = true
                    loadingOverlay.active = false
                    if (mainPageInstance) {
                        mainPageInstance.visible = true
                    }
                }
                timeoutTimer.destroy()
            })
        } catch (e) {
            console.error("创建MainPage时发生错误:", e)
            loadingOverlay.active = false
        }
    }

    Connections {
        id: mainPageConnections
        target: mainPageInstance
        enabled: mainPageInstance !== null

        function onUploadRequested() {
            console.log("✅ Connections: 收到上传请求")
            // openFileDialog()
        }

        function onDownloadRequested(selectedItems) {
            console.log("✅ Connections: 收到下载请求，项目数:", selectedItems.length)
            // handleDownloadRequest(selectedItems)
        }

        function onSearchRequested(query) {
            console.log("✅ Connections: 收到搜索请求:", query)
            // handleSearchRequest(query)
        }

        function onFolderSelected(folderId) {
            console.log("✅ Connections: 收到文件夹选择:", folderId)
            // handleFolderSelection(folderId)
        }

        function onLogoutRequested() {
            console.log("✅ Connections: 收到退出登录请求")
            // handleLogoutRequest()
        }
    }
}

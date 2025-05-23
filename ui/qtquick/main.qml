import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "./Component"

ApplicationWindow {
    id: mainWindow
    width: 640
    height: 480
    visible: false
    title: "Cloud Storage Hub"

    // 主界面，默认隐藏
    Item {
        id: mainPage
        visible: false
        anchors.fill: parent
        Label {
            anchors.centerIn: parent
            text: "欢迎使用主界面！"
        }
    }

    Component.onCompleted: {
        var component = Qt.createComponent("LoginDialog.qml")
        if (component.status === Component.Ready) {
            var dialog = component.createObject(null)
            dialog.visible = true
            dialog.onLoginSuccess.connect(function () {
                dialog.visible = false
                mainWindow.visible = true // 登录成功后显示主窗口
            })
        } else {
            console.log("登录对话框加载失败: " + component.errorString())
        }
    }
}

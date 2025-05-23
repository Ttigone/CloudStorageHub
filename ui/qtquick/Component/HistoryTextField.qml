import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

TextField {
    id: control

    // 公开属性
    property var historyModel: [] // 历史记录模型
    property bool passwordMode: false // 是否为密码输入模式
    property string historyIconText: "⟳" // 历史记录图标

    // 私有属性
    property bool showingHistory: false // 防止循环触发



    // 设置样式
    color: "#FFFFFF"
    placeholderTextColor: "#8A8A8A"
    selectByMouse: true
    height: 40

    // 密码模式
    echoMode: passwordMode ? TextInput.Password : TextInput.Normal

    // 背景
    background: Rectangle {
        radius: 4
        color: "#3E3E42"
        border.color: control.focus ? "#3498db" : "#555555"
        border.width: 1
    }

    // 按键处理
    Keys.onDownPressed: {
        if (!historyPopup.visible && historyModel.length > 0) {
            historyPopup.open()
        } else {
            event.accepted = false
        }
    }

    // 焦点变化处理
    onActiveFocusChanged: {
        // if (activeFocus && !text && historyModel.length > 0) {
        //     historyPopup.open()
        // }
        if (activeFocus) {
            // 获得焦点时，如果有历史记录则显示 popup
            if (historyModel.length > 0 && !text) {
                historyPopup.open()
            }
        } else {
            // 失去焦点时，关闭 popup
            if (historyPopup.visible) {
                historyPopup.close()
            }
        }
    }
    // 添加点击处理
    TapHandler {
        onTapped: {
            console.log("TapHandler clicked")
            // 当用户点击输入框且有历史记录时显示 popup
            if (control.historyModel.length > 0 && !historyPopup.visible) {
                console.log("open popup")
                historyPopup.open()
            }
        }
    }

    // 添加鼠标区域来处理右键点击
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        propagateComposedEvents: true
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor

        onClicked: function (mouse) {
            console.log("button on lcicked")
            if (mouse.button === Qt.RightButton) {
                if (control.historyModel.length > 0) {
                    console.log("open popup")
                    historyPopup.open()
                }
                mouse.accepted = true
            } else {
                console.log("不是右键按下, 但是 popup 会关闭")
                mouse.accepted = false
            }
        }

        // 确保鼠标事件传递给 TextField
        onPressed: function (mouse) {
            console.log("press")
            mouse.accepted = false // 让事件继续传递
        }
        onReleased: function (mouse) {
            console.log("release")
            mouse.accepted = false
        }
        onPositionChanged: function (mouse) {
            mouse.accepted = false
        }
    }

    // 文本变化处理
    onTextChanged: {
        if (text && !showingHistory && historyModel.length > 0) {
            // 如果有匹配项，显示下拉菜单
            let foundMatch = false
            for (var i = 0; i < historyModel.length; i++) {
                if (historyModel[i].startsWith(text)) {
                    foundMatch = true
                    break
                }
            }

            if (foundMatch && !historyPopup.visible) {
                historyPopup.open()
            } else if (!foundMatch && historyPopup.visible) {
                historyPopup.close()
            }
        }
    }

    // 历史记录弹出菜单
    Popup {
        id: historyPopup
        y: control.height
        width: control.width
        implicitHeight: Math.min(220, contentItem.contentHeight)
        padding: 1
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        focus: true
        modal: false

        // 添加进入/退出动画
        enter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 150
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "scale"
                from: 0.95
                to: 1.0
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: 100
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                property: "scale"
                from: 1.0
                to: 0.95
                duration: 100
                easing.type: Easing.InCubic
            }
        }
        // 添加打开和关闭处理
        onOpened: {
            // // 防止打开后立即关闭
            // control.forceActiveFocus()
            // 简单地确保输入框有焦点，不再强制处理
            if (!control.activeFocus) {
                control.forceActiveFocus()
            }
        }
        // 添加这段代码
        onClosed: {

            // 重置 popup 状态，确保下次可以打开
            // control.forceActiveFocus();
            // 确保关闭后可以再次打开
            // if (control.activeFocus) {
            //     // 如果控件仍有焦点，恢复焦点以便再次打开
            //     control.focus = false
            //     control.focus = true
            // }
        }
        // 设定变换原点在顶部中心
        transformOrigin: Popup.Top

        // 美化背景
        background: Rectangle {
            color: "#3E3E42"
            border.color: "#555555"
            border.width: 1
            radius: 6

            // 添加阴影效果
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: 2
                radius: 8.0
                samples: 17
                color: Qt.rgba(0, 0, 0, 0.5)
            }
        }

        contentItem: ListView {
            id: historyList
            clip: true
            implicitHeight: contentHeight
            model: {
                if (!control.text)
                    return control.historyModel
                return control.historyModel.filter(
                            item => item.toLowerCase().includes(
                                control.text.toLowerCase()))
            }

            // 添加顶部标题
            header: Rectangle {
                width: historyList.width
                height: 30
                color: "#2D2D30"

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    text: "历史记录"
                    color: "#AAAAAA"
                    font.pixelSize: 12
                }
            }

            delegate: ItemDelegate {
                id: historyItem
                width: historyList.width
                height: 40

                // 高亮动画
                Rectangle {
                    id: highlightRect
                    anchors.fill: parent
                    color: "#4080C0"
                    opacity: 0
                    radius: 4

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }
                }

                contentItem: Item {
                    anchors.fill: parent

                    // 图标
                    Rectangle {
                        id: iconCircle
                        anchors {
                            left: parent.left
                            leftMargin: 10
                            verticalCenter: parent.verticalCenter
                        }
                        width: 22
                        height: 22
                        radius: 11
                        color: "#3498DB"
                        opacity: 0.7

                        Text {
                            anchors.centerIn: parent
                            text: control.historyIconText
                            color: "#FFFFFF"
                            font.pixelSize: 14
                        }
                    }

                    // 文本
                    Text {
                        anchors {
                            left: iconCircle.right
                            leftMargin: 10
                            right: deleteButton.left
                            rightMargin: 5
                            verticalCenter: parent.verticalCenter
                        }
                        text: modelData
                        color: "#ECECEC"
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }

                    // 删除按钮
                    Rectangle {
                        id: deleteButton
                        anchors {
                            right: parent.right
                            rightMargin: 8
                            verticalCenter: parent.verticalCenter
                        }
                        width: 20
                        height: 20
                        radius: 10
                        color: deleteMouseArea.containsMouse ? "#e74c3c" : "transparent"
                        border.color: deleteMouseArea.containsMouse ? "#c0392b" : "#AAAAAA"
                        border.width: 1
                        visible: historyItem.hovered

                        // 添加动画
                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 100
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: deleteMouseArea.containsMouse ? "#FFFFFF" : "#AAAAAA"
                            font.pixelSize: 14
                            font.bold: true
                        }

                        // 删除按钮鼠标区域
                        MouseArea {
                            id: deleteMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onPressed: {
                                parent.scale = 0.9
                            }

                            onReleased: {
                                parent.scale = 1.0
                            }

                            // 每个项点击后的动作
                            onClicked: {
                                deleteAnimation.start()
                            }
                        }

                        // 删除动画
                        SequentialAnimation {
                            id: deleteAnimation

                            // 红色闪动
                            ColorAnimation {
                                target: highlightRect
                                property: "color"
                                to: "#e74c3c"
                                duration: 150
                            }

                            // 缩放退出
                            ParallelAnimation {
                                NumberAnimation {
                                    target: historyItem
                                    property: "opacity"
                                    to: 0
                                    duration: 200
                                    easing.type: Easing.InQuad
                                }
                                NumberAnimation {
                                    target: historyItem
                                    property: "height"
                                    to: 0
                                    duration: 200
                                    easing.type: Easing.InQuad
                                }
                            }
                            // 执行删除
                            ScriptAction {
                                script: {
                                    try {
                                        // 向外部发出删除信号
                                        var textField = historyPopup.parent
                                        // control.requestRemoveHistory(modelData)
                                        textField.requestRemoveHistory(
                                                    modelData)
                                    } catch (e) {
                                        console.error("删除历史记录失败: " + e)
                                    }
                                }
                            }
                        }
                    }
                }

                // 悬停效果
                onHoveredChanged: {
                    highlightRect.opacity = hovered ? 0.3 : 0
                }

                background: Rectangle {
                    color: hovered ? "#505050" : "transparent"
                }

                // 点击效果
                onClicked: {
                    highlightRect.opacity = 0.5
                    // 为什么都需要这样操作 ???
                    // 使用变量引用控件
                    var textField = historyPopup.parent
                    // control.showingHistory = true
                    // control.text = modelData
                    // control.showingHistory = false
                    textField.showingHistory = true
                    textField.text = modelData
                    textField.showingHistory = false
                    // 点击动画
                    clickAnimation.start()
                }

                SequentialAnimation {
                    id: clickAnimation
                    PropertyAnimation {
                        target: historyItem
                        property: "scale"
                        from: 1.0
                        to: 0.97
                        duration: 50
                    }
                    PropertyAnimation {
                        target: historyItem
                        property: "scale"
                        from: 0.97
                        to: 1.0
                        duration: 100
                    }
                    ScriptAction {
                        script: {
                            historyPopup.close()
                        }
                    }
                }
            }

            // 滚动指示器
            ScrollIndicator.vertical: ScrollIndicator {
                active: historyList.contentHeight > historyList.height
                contentItem: Rectangle {
                    implicitWidth: 4
                    implicitHeight: 100
                    color: "#777777"
                    radius: 2
                }
            }
            // // 空列表显示
            // footer: Rectangle {
            //     width: historyList.width
            //     height: 40
            //     visible: historyList.count === 0
            //     color: "transparent"

            //     Text {
            //         anchors.centerIn: parent
            //         text: "没有匹配的历史记录"
            //         color: "#888888"
            //         font.pixelSize: 12
            //         font.italic: true
            //     }
            // }
        }
    }
    // 删除历史记录信号
    signal requestRemoveHistory(string value)
}

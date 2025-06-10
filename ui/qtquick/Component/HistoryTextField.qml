import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

TextField {
    id: control

    // 现有属性
    property var historyModel: [] // 数组形式
    property bool passwordMode: false
    property string historyIconText: "⟳"
    property bool showingHistory: false

    // 补全
    property var completionModel: []
    property bool enableCompletion: true
    property string completionIconText: "📁"
    property int maxCompletionItems: 8

    // 设置样式
    color: "transparent"
    placeholderTextColor: "#8A8A8A"
    selectByMouse: true
    height: 40
    echoMode: passwordMode ? TextInput.Password : TextInput.Normal

    // 信号
    signal historyItemSelected(string value)
    signal completionItemSelected(string value)
    signal requestRemoveHistory(string value)

    // 删除历史记录信号
    function getFilteredCompletions(inputText) {
        if (!inputText || inputText.length === 0) {
            return []
        }

        var filtered = []
        var lowerInput = inputText.toLowerCase()

        for (var i = 0; i < completionModel.length
             && filtered.length < maxCompletionItems; i++) {
            var item = completionModel[i]
            if (item && typeof item === 'string') {
                if (item.toLowerCase().startsWith(lowerInput)) {
                    filtered.push(item)
                }
            } else if (item && item.name) {
                if (item.name.toLowerCase().startsWith(lowerInput)) {
                    filtered.push(item.name)
                }
            }
        }

        return filtered
    }

    // 切换弹窗函数
    function togglePopup(forceState) {
        var hasHistory = historyModel.length > 0
        var hasCompletions = enableCompletion && getFilteredCompletions(
                    text).length > 0

        if (!hasHistory && !hasCompletions) {
            return
        }

        if (forceState === true) {
            if (!historyPopup.visible) {
                historyPopup.open()
            }
        } else if (forceState === false) {
            if (historyPopup.visible) {
                historyPopup.close()
            }
        } else {
            if (historyPopup.visible) {
                historyPopup.close()
            } else {
                historyPopup.open()
            }
        }
    }

    // 背景样式
    background: Rectangle {
        radius: 4
        color: "#3E3E42"
        border.color: control.focus ? "#3498db" : "#555555"
        border.width: 1
    }

    // // 键盘事件处理
    // Keys.onDownPressed: {
    //     if (historyPopup.visible && historyPopup.listView) {
    //         if (historyPopup.listView.currentIndex < historyPopup.listView.count - 1) {
    //             historyPopup.listView.currentIndex++
    //         }
    //     }
    // }
        // ✅ 修复4: 优化键盘事件处理
    Keys.onDownPressed: function(event) {
        if (historyPopup.visible && historyPopup.listView) {
            if (historyPopup.listView.currentIndex < historyPopup.listView.count - 1) {
                historyPopup.listView.currentIndex++
            }
            event.accepted = true
        }
    }

    // Keys.onUpPressed: {
    //     if (historyPopup.visible && historyPopup.listView) {
    //         if (historyPopup.listView.currentIndex > 0) {
    //             historyPopup.listView.currentIndex--
    //         }
    //     }
    // }
        Keys.onUpPressed: function(event) {
        if (historyPopup.visible && historyPopup.listView) {
            if (historyPopup.listView.currentIndex > 0) {
                historyPopup.listView.currentIndex--
            }
            event.accepted = true
        }
    }

    // Keys.onReturnPressed: {
    //     if (historyPopup.visible && historyPopup.listView
    //             && historyPopup.listView.currentIndex >= 0) {
    //         var currentData = historyPopup.getCurrentItemData()
    //         if (currentData) {
    //             if (currentData.isCompletion) {
    //                 completionItemSelected(currentData.text)
    //                 text = currentData.text
    //             } else {
    //                 historyItemSelected(currentData.text)
    //                 text = currentData.text
    //             }
    //             historyPopup.close()
    //         }
    //     } else {
    //         accepted()
    //     }
    // }
        Keys.onReturnPressed: function(event) {
        if (historyPopup.visible && historyPopup.listView && historyPopup.listView.currentIndex >= 0) {
            var currentData = historyPopup.getCurrentItemData()
            if (currentData) {
                if (currentData.isCompletion) {
                    completionItemSelected(currentData.text)
                } else {
                    historyItemSelected(currentData.text)
                }
                control.text = currentData.text
                historyPopup.close()
            }
            event.accepted = true
        } else {
            accepted()
        }
    }

    // 鼠标区域处理
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        propagateComposedEvents: true
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor

        onClicked: function (mouse) {
            if (mouse.button === Qt.RightButton) {
                mouse.accepted = true
            } else {
                mouse.accepted = false
            }
        }

        onPressed: function (mouse) {
            mouse.accepted = mouse.button === Qt.RightButton
        }
        onReleased: function (mouse) {
            mouse.accepted = mouse.button === Qt.RightButton
        }
        onDoubleClicked: function (mouse) {
            mouse.accepted = false
        }
        onPositionChanged: function (mouse) {
            mouse.accepted = false
        }
    }

    // 文本变化处理
    // onTextChanged: {
    //     if (!showingHistory) {
    //         var hasHistory = historyModel.length > 0
    //         console.log("hasHistory", hasHistory)
    //         // 都是 false
    //         var hasCompletions = enableCompletion && getFilteredCompletions(
    //                     text).length > 0
    //         console.log("hasCompletions: ", hasCompletions)
    //         if ((hasHistory || hasCompletions) && !historyPopup.visible
    //                 && text.length > 0) {
    //             historyPopup.open()
    //         } else if (!hasHistory && !hasCompletions && historyPopup.visible) {
    //             historyPopup.close()
    //         }
    //     }
    // }

    // ✅ 修复6: 优化文本变化处理
    onTextChanged: {
        // 简化文本变化处理，避免影响输入
        if (enableCompletion || historyModel.length > 0) {
            // 延迟处理，避免影响当前输入
            Qt.callLater(function() {
                var hasHistory = historyModel.length > 0
                var hasCompletions = enableCompletion && getFilteredCompletions(text).length > 0
                
                if (hasHistory || hasCompletions) {
                    if (!historyPopup.visible && text.length > 0) {
                        historyPopup.open()
                    }
                } else if (historyPopup.visible) {
                    historyPopup.close()
                }
            })
        }
    }

    // 美化的历史记录/补全弹出菜单
    Popup {
        id: historyPopup
        y: control.height + 2
        width: control.width
        implicitHeight: Math.min(320, contentItem.contentHeight)
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        // focus: true
        focus: false
        modal: false

        property alias listView: popupListView

        function getCurrentItemData() {
            if (popupListView.currentIndex >= 0
                    && popupListView.currentIndex < popupListView.count) {
                return popupListView.model[popupListView.currentIndex]
            }
            return null
        }
        enter: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 200
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "scale"
                    from: 0.95
                    to: 1.0
                    duration: 200
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "y"
                    from: control.height - 5
                    to: control.height + 2
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
        }

        exit: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 150
                }
                NumberAnimation {
                    property: "scale"
                    from: 1.0
                    to: 0.95
                    duration: 150
                }
            }
        }

        onOpened: {
            popupListView.currentIndex = 0
        }

        onClosed: {
            popupListView.currentIndex = -1
        }

        transformOrigin: Popup.Top

        background: Rectangle {
            color: "#2A2A2A" 
            radius: 8
            border.color: "#404040"
            border.width: 1

            // 顶部指示器
            Rectangle {
                width: 20
                height: 3
                radius: 1.5
                color: "#505050" // 深色指示器
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 6
            }

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 8
                radius: 16
                samples: 33
                color: "#40000000" // 加深阴影
                spread: 0.1
            }
        }

        contentItem: ListView {
            id: popupListView
            clip: true
            // 修改模型构建逻辑 - 确保所有项目都有完整的属性结构
            model: {
                var result = []
                // 添加自动补全项
                if (enableCompletion && control.text.length > 0) {
                    var completions = getFilteredCompletions(control.text)
                    for (var i = 0; i < completions.length; i++) {
                        result.push({
                                        "text": completions[i],
                                        "icon": completionIconText,
                                        "isCompletion": true,
                                        "description": "文件/文件夹",
                                        "showDelete": false,
                                        "isSeparator": false // 明确设置为 false
                                    })
                    }
                }

                // 添加分隔符（如果两种类型都有）
                if (result.length > 0 && historyModel.length > 0) {
                    result.push({
                                    "text": "",
                                    "icon": "",
                                    "isCompletion": false,
                                    "isSeparator": true,
                                    "description"// 明确设置为 true
                                    : "",
                                    "showDelete": false
                                })
                }

                // 添加历史记录项 - 重要：处理字符串数组
                for (var j = 0; j < historyModel.length; j++) {
                    var historyItem = historyModel[j]
                    // 如果 historyModel 的项目是字符串，需要包装成对象
                    var itemText = typeof historyItem
                            === 'string' ? historyItem : (historyItem.text
                                                          || historyItem.toString(
                                                              ))

                    result.push({
                                    "text": itemText,
                                    "icon": historyIconText,
                                    "isCompletion": false,
                                    "description": "历史记录",
                                    "showDelete": true,
                                    "isSeparator"// 历史记录显示删除按钮
                                    : false // 明确设置为 false
                                })
                }

                return result
            }

            delegate: Item {
                width: popupListView.width
                height: (modelData && modelData.isSeparator) ? 9 : 48
                // 分隔线 - 添加安全检查
                Rectangle {
                    visible: modelData && modelData.isSeparator === true
                    anchors.centerIn: parent
                    width: parent.width - 24
                    height: 1
                    color: "#E0E6ED"
                    z: 1
                }

                Rectangle {
                    id: itemBackground
                    visible: modelData && modelData.isSeparator !== true
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: 6

                    color: {
                        if (popupListView.currentIndex === index) {
                            return (modelData
                                    && modelData.isCompletion) ? "#EBF3FF" : "#F8F9FA"
                        }
                        return itemMouseArea.containsMouse ? "#F5F7FA" : "transparent"
                    }

                    border.color: {
                        if (popupListView.currentIndex === index) {
                            return (modelData
                                    && modelData.isCompletion) ? "#3B82F6" : "#6B7280"
                        }
                        return "transparent"
                    }
                    border.width: popupListView.currentIndex === index ? 1 : 0

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 100
                        }
                    }

                    Row {
                        visible: modelData && modelData.isSeparator !== true
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: (modelData
                                        && modelData.showDelete) ? deleteButton.left : parent.right
                        anchors.rightMargin: (modelData
                                              && modelData.showDelete) ? 8 : 12
                        spacing: 10
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: modelData ? (modelData.text || "") : ""
                                // text: "测试"
                                font.pixelSize: 14
                                color: "#000000" // 白色文字在深色背景上
                                font.weight: (modelData
                                              && modelData.isCompletion) ? Font.Medium : Font.Normal
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                            // 描述文字 - 浅灰色
                            Text {
                                text: modelData ? (modelData.description
                                                   || "") : ""
                                font.pixelSize: 11
                                color: "#9CA3AF" // 浅灰色描述文字
                                visible: modelData && modelData.description
                                         && modelData.description !== ""
                            }
                        }
                    }

                    // 删除按钮 - 添加安全检查
                    Button {
                        id: deleteButton
                        visible: modelData && modelData.showDelete === true
                                 && modelData.isSeparator !== true
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28

                        background: Rectangle {
                            radius: 6
                            color: {
                                if (deleteButton.pressed)
                                    return "#FEE2E2"
                                if (deleteButton.hovered)
                                    return "#FEF2F2"
                                return "transparent"
                            }
                            border.color: deleteButton.hovered ? "#FECACA" : "transparent"
                            border.width: 1

                            Behavior on color {
                                ColorAnimation {
                                    duration: 100
                                }
                            }
                        }

                        contentItem: Text {
                            text: "🗑️"
                            font.pixelSize: 12
                            color: deleteButton.hovered ? "#DC2626" : "#9CA3AF"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter

                            Behavior on color {
                                ColorAnimation {
                                    duration: 100
                                }
                            }
                        }

                        onClicked: {
                            if (modelData && modelData.text) {
                                console.log("删除历史记录:", modelData.text)
                                control.requestRemoveHistory(modelData.text)
                                historyPopup.close()
                            }
                        }

                        onHoveredChanged: {
                            if (hovered) {
                                itemBackground.color = "#FEF2F2"
                            }
                        }

                        ToolTip.visible: hovered
                        ToolTip.text: "删除此历史记录"
                        ToolTip.delay: 500
                    }

                    MouseArea {
                        id: itemMouseArea
                        visible: modelData && modelData.isSeparator !== true
                        anchors.fill: parent
                        anchors.rightMargin: (modelData
                                              && modelData.showDelete) ? 36 : 0
                        hoverEnabled: true

                        onClicked: {
                            if (!modelData || !modelData.text)
                                return

                            if (modelData.isCompletion) {
                                completionItemSelected(modelData.text)
                                control.text = modelData.text
                            } else {
                                historyItemSelected(modelData.text)
                                control.text = modelData.text
                            }
                            historyPopup.close()
                        }

                        onEntered: {
                            popupListView.currentIndex = index
                        }
                    }
                }
                // 项目进入动画 - 添加安全检查
                Component.onCompleted: {
                }
            }

            // 自定义滚动条保持不变
            ScrollBar.vertical: ScrollBar {
                width: 6
                policy: ScrollBar.AsNeeded

                background: Rectangle {
                    color: "#F3F4F6"
                    radius: 3
                }

                contentItem: Rectangle {
                    radius: 3
                    color: parent.pressed ? "#9CA3AF" : (parent.hovered ? "#D1D5DB" : "#E5E7EB")

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }
                }
            }
        }
    }
}

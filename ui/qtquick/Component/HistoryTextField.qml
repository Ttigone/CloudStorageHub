import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

TextField {
    id: control

    // 现有属性
    property var historyModel: []
    property bool passwordMode: false
    property string historyIconText: "⟳"
    property bool showingHistory: false

    // 补全相关
    property var completionModel: []
    property bool enableCompletion: true
    property string completionIconText: "📁"
    property int maxCompletionItems: 8

    // 新增美化属性
    property bool showClearButton: true
    property bool showHistoryButton: true
    property color accentColor: "#3B82F6"
    property color backgroundColor: "#FFFFFF"
    property color borderColor: "#E5E7EB"
    property color focusColor: "#3B82F6"

    // 设置样式
    color: "#1F2937"
    placeholderTextColor: "#9CA3AF"
    selectByMouse: true
    height: 44
    echoMode: passwordMode ? TextInput.Password : TextInput.Normal
    leftPadding: 16
    rightPadding: actionButtonsRow.width + 16

    // 信号
    signal historyItemSelected(string value)
    signal completionItemSelected(string value)
    signal requestRemoveHistory(string value)
    signal requestClearAllHistory
    signal requestClearAllCompletions

    // 获取过滤的补全建议
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
                if (item.toLowerCase().includes(lowerInput)) {
                    filtered.push(item)
                }
            } else if (item && item.name) {
                if (item.name.toLowerCase().includes(lowerInput)) {
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

    // 美化的背景样式
    background: Rectangle {
        radius: 8
        color: control.backgroundColor
        border.color: {
            if (control.focus)
                return control.focusColor
            if (control.hovered)
                return "#D1D5DB"
            return control.borderColor
        }
        border.width: control.focus ? 2 : 1

        // 渐变背景效果
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: control.focus ? "#F8FAFC" : control.backgroundColor
            }
            GradientStop {
                position: 1.0
                color: control.backgroundColor
            }
        }

        // 聚焦时的光晕效果
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.color: control.focusColor
            border.width: control.focus ? 3 : 0
            opacity: control.focus ? 0.2 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: 200
            }
        }

        Behavior on border.width {
            NumberAnimation {
                duration: 200
            }
        }
    }

    // 右侧操作按钮区域
    Row {
        id: actionButtonsRow
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        Button {
            id: clearTextButton
            visible: control.showClearButton && control.text.length > 0
            width: 28
            height: 28

            anchors.verticalCenter: parent.verticalCenter

            background: Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                radius: 14
                color: {
                    if (parent.pressed)
                        return "#FEE2E2"
                    if (parent.hovered)
                        return "#FEF2F2"
                    return "transparent"
                }
                border.color: {
                    if (parent.hovered)
                        return "#F87171"
                    return "transparent"
                }
                border.width: 1

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                Behavior on border.color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }

            contentItem: Text {
                text: "✕"
                font.pixelSize: 10 // 从 12 调整到 10，使其更协调
                font.weight: Font.Bold
                color: {
                    if (parent.pressed)
                        return "#DC2626"
                    if (parent.hovered)
                        return "#EF4444"
                    return "#9CA3AF"
                }
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }

            onClicked: {
                control.text = ""
                control.forceActiveFocus()
            }

            // ToolTip.visible: hovered
            // ToolTip.text: "清除文本"
            // ToolTip.delay: 500
            TtToolTip {
                visible: parent.hovered
                text: qsTr("清楚文本")
                delay: 500
            }
        }

        // 历史记录按钮保持不变，但为了对比，这里是完整版本
        Button {
            id: historyButton
            visible: control.showHistoryButton && (historyModel.length > 0
                                                   || enableCompletion)
            width: 28 // 稍大一些，因为它是主要功能按钮
            height: 28

            background: Rectangle {
                radius: 14 // 保持完美圆形 (width/2)
                color: {
                    if (parent.pressed)
                        return control.accentColor
                    if (parent.hovered)
                        return "#EBF4FF"
                    if (historyPopup.visible)
                        return "#DBEAFE"
                    return "transparent"
                }
                border.color: {
                    if (historyPopup.visible)
                        return control.accentColor
                    if (parent.hovered)
                        return "#93C5FD"
                    return "transparent"
                }
                border.width: 1

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                Behavior on border.color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }

            contentItem: Text {
                text: historyPopup.visible ? "▲" : "▼"
                font.pixelSize: 10
                font.weight: Font.Bold
                color: {
                    if (parent.pressed)
                        return "#FFFFFF"
                    if (historyPopup.visible)
                        return control.accentColor
                    if (parent.hovered)
                        return control.accentColor
                    return "#6B7280"
                }
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }

            onClicked: {
                togglePopup()
            }

            TtToolTip {
                visible: parent.hovered && !historyPopup.visible
                text: qsTr("显示历史记录和建议")
                delay: 500
                // arrowPosition: "left"
            }
            // ToolTip.visible: hovered && !historyPopup.visible
            // ToolTip.text: "显示历史记录和建议"
            // ToolTip.delay: 500
        }
    }

    // 键盘事件处理
    Keys.onDownPressed: function (event) {
        if (historyPopup.visible && historyPopup.listView) {
            if (historyPopup.listView.currentIndex < historyPopup.listView.count - 1) {
                historyPopup.listView.currentIndex++
            }
            event.accepted = true
        }
    }

    Keys.onUpPressed: function (event) {
        if (historyPopup.visible && historyPopup.listView) {
            if (historyPopup.listView.currentIndex > 0) {
                historyPopup.listView.currentIndex--
            }
            event.accepted = true
        }
    }

    // Keys.onReturnPressed: function (event) {
    //     if (historyPopup.visible && historyPopup.listView
    //             && historyPopup.listView.currentIndex >= 0) {
    //         var currentData = historyPopup.getCurrentItemData()
    //         if (currentData) {
    //             if (currentData.isCompletion) {
    //                 completionItemSelected(currentData.text)
    //             } else {
    //                 historyItemSelected(currentData.text)
    //             }
    //             control.text = currentData.text
    //             historyPopup.close()
    //         }
    //         event.accepted = true
    //     } else {
    //         accepted()
    //     }
    // }
    // 修复键盘事件处理逻辑
    Keys.onReturnPressed: function (event) {
        if (historyPopup.visible && historyPopup.listView) {
            var currentIndex = historyPopup.listView.currentIndex
            var model = historyPopup.listView.model

            // 修复：确保选中的是有效的数据项，而不是分组标题或分隔符
            if (currentIndex >= 0 && currentIndex < model.length) {
                var currentData = model[currentIndex]

                // 跳过分组标题和分隔符，找到第一个有效项
                while (currentIndex < model.length) {
                    currentData = model[currentIndex]

                    // 检查是否是有效的数据项（不是标题或分隔符）
                    if (currentData && !currentData.isGroupHeader
                            && !currentData.isSeparator && currentData.text
                            && currentData.text !== "") {

                        // 找到有效项，使用它
                        if (currentData.isCompletion) {
                            completionItemSelected(currentData.text)
                        } else {
                            historyItemSelected(currentData.text)
                        }
                        control.text = currentData.text
                        historyPopup.close()
                        event.accepted = true
                        return
                    }

                    // 如果当前项无效，尝试下一项
                    currentIndex++
                }
            }

            // 如果没有找到有效项，或者没有选中任何项，选择第一个有效项
            if (model && model.length > 0) {
                for (var i = 0; i < model.length; i++) {
                    var item = model[i]
                    if (item && !item.isGroupHeader && !item.isSeparator
                            && item.text && item.text !== "") {

                        // 找到第一个有效项
                        if (item.isCompletion) {
                            completionItemSelected(item.text)
                        } else {
                            historyItemSelected(item.text)
                        }
                        control.text = item.text
                        historyPopup.close()
                        event.accepted = true
                        return
                    }
                }
            }

            event.accepted = true
        } else {
            // 如果弹窗不可见，正常处理回车事件
            accepted()
        }
    }

    Keys.onEscapePressed: function (event) {
        if (historyPopup.visible) {
            historyPopup.close()
            event.accepted = true
        }
    }

    // 鼠标区域处理
    MouseArea {
        anchors.fill: parent
        anchors.rightMargin: actionButtonsRow.width + 12
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
    }

    // 文本变化处理
    onTextChanged: {
        if (enableCompletion || historyModel.length > 0) {
            Qt.callLater(function () {
                var hasHistory = historyModel.length > 0
                var hasCompletions = enableCompletion && getFilteredCompletions(
                            text).length > 0

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
    // 修改 Popup 部分 - 缩小尺寸版本
    Popup {
        id: historyPopup
        y: control.height + 4
        width: control.width
        implicitHeight: Math.min(280,
                                 contentColumn.implicitHeight) // 从 400 缩小到 280
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

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

        // 保持原有动画...
        enter: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 200 // 从 250 缩短到 200
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "scale"
                    from: 0.95
                    to: 1.0
                    duration: 200 // 从 250 缩短到 200
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.1 // 从 1.2 减小到 1.1
                }
                NumberAnimation {
                    property: "y"
                    from: control.height - 6 // 从 -8 改为 -6
                    to: control.height + 4
                    duration: 200 // 从 250 缩短到 200
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
            color: "#FFFFFF"
            radius: 10 // 从 12 缩小到 10
            border.color: "#E5E7EB"
            border.width: 1

            // 阴影效果 - 减小
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 6 // 从 8 缩小到 6
                radius: 18 // 从 24 缩小到 18
                samples: 36 // 从 48 缩小到 36
                color: "#18000000" // 从 "#20000000" 减淡到 "#18000000"
                spread: 0
            }

            // 顶部装饰线 - 缩小
            Rectangle {
                width: 28 // 从 32 缩小到 28
                height: 3 // 从 4 缩小到 3
                radius: 1.5 // 从 2 缩小到 1.5
                color: "#D1D5DB"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 6 // 从 8 缩小到 6
            }
        }

        contentItem: Column {
            id: contentColumn
            spacing: 0

            // 弹窗头部 - 缩小高度
            Rectangle {
                width: parent.width
                height: 40 // 从 48 缩小到 40
                color: "#F9FAFB"

                Rectangle {
                    anchors.fill: parent
                    color: parent.color
                    radius: 10 // 从 12 缩小到 10
                }

                // 用一个矩形遮盖底部，使其变成直角
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 10 // 从 12 缩小到 10
                    color: parent.color
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12 // 从 16 缩小到 12
                    anchors.rightMargin: 12 // 从 16 缩小到 12
                    anchors.topMargin: 16 // 从 20 缩小到 16

                    Text {
                        text: "历史记录与建议"
                        font.pixelSize: 12 // 从 14 缩小到 12
                        font.weight: Font.Medium
                        color: "#374151"
                        Layout.fillWidth: true
                    }

                    // 清除历史记录按钮 - 缩小
                    Button {
                        visible: historyModel.length > 0
                        text: "清除历史"
                        flat: true
                        Layout.preferredHeight: 20 // 从 24 缩小到 20

                        background: Rectangle {
                            radius: 4 // 从 6 缩小到 4
                            color: {
                                if (parent.pressed)
                                    return "#FEE2E2"
                                if (parent.hovered)
                                    return "#FEF2F2"
                                return "transparent"
                            }
                            border.color: parent.hovered ? "#F87171" : "transparent"
                            border.width: 1
                        }

                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 10 // 从 11 缩小到 10
                            color: parent.hovered ? "#EF4444" : "#9CA3AF"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            clearHistoryDialog.open()
                        }
                    }

                    // 清除补全按钮 - 缩小
                    Button {
                        visible: completionModel.length > 0
                        text: "清除补全"
                        flat: true
                        Layout.preferredHeight: 20 // 从 24 缩小到 20

                        background: Rectangle {
                            radius: 4 // 从 6 缩小到 4
                            color: {
                                if (parent.pressed)
                                    return "#FEF3C7"
                                if (parent.hovered)
                                    return "#FFFBEB"
                                return "transparent"
                            }
                            border.color: parent.hovered ? "#FCD34D" : "transparent"
                            border.width: 1
                        }

                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 10 // 从 11 缩小到 10
                            color: parent.hovered ? "#D97706" : "#9CA3AF"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            clearCompletionDialog.open()
                        }
                    }
                }
            }

            // 分隔线
            Rectangle {
                width: parent.width
                height: 1
                color: "#E5E7EB"
            }

            // 列表视图 - 修复悬浮效果并缩小尺寸
            ListView {
                id: popupListView
                width: parent.width
                height: Math.min(220, contentHeight) // 从 300 缩小到 220
                clip: true

                model: {
                    // 保持原有的 model 逻辑不变...
                    var result = []

                    // 添加自动补全项
                    if (enableCompletion && control.text.length > 0) {
                        var completions = getFilteredCompletions(control.text)
                        if (completions.length > 0) {
                            // 补全分组标题
                            result.push({
                                            "text": "补全建议",
                                            "icon": "",
                                            "isCompletion": false,
                                            "description": "",
                                            "showDelete": false,
                                            "isSeparator": false,
                                            "isGroupHeader": true
                                        })

                            for (var i = 0; i < completions.length; i++) {
                                result.push({
                                                "text": completions[i],
                                                "icon": completionIconText,
                                                "isCompletion": true,
                                                "description": "文件/文件夹",
                                                "showDelete": false,
                                                "isSeparator": false,
                                                "isGroupHeader": false
                                            })
                            }
                        }
                    }

                    // 添加历史记录项
                    if (historyModel.length > 0) {
                        if (result.length > 0) {
                            // 分隔符
                            result.push({
                                            "text": "",
                                            "icon": "",
                                            "isCompletion": false,
                                            "isSeparator": true,
                                            "description": "",
                                            "showDelete": false,
                                            "isGroupHeader": false
                                        })
                        }

                        // 历史记录分组标题
                        result.push({
                                        "text": "历史记录",
                                        "icon": "",
                                        "isCompletion": false,
                                        "description": "",
                                        "showDelete": false,
                                        "isSeparator": false,
                                        "isGroupHeader": true
                                    })

                        for (var j = 0; j < historyModel.length; j++) {
                            var historyItem = historyModel[j]
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
                                            "isSeparator": false,
                                            "isGroupHeader": false
                                        })
                        }
                    }

                    return result
                }

                delegate: Item {
                    width: popupListView.width
                    height: {
                        if (modelData && modelData.isSeparator)
                            return 12
                        if (modelData && modelData.isGroupHeader)
                            return 28
                        return 44
                    }

                    Rectangle {
                        visible: modelData && modelData.isGroupHeader === true
                        anchors.fill: parent
                        color: "#F3F4F6"

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData ? modelData.text : ""
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: "#6B7280"
                        }
                    }

                    Rectangle {
                        visible: modelData && modelData.isSeparator === true
                        anchors.centerIn: parent
                        width: parent.width - 24
                        height: 1
                        color: "#E5E7EB"
                    }

                    Rectangle {
                        id: itemBackground
                        visible: modelData && modelData.isSeparator !== true
                                 && modelData.isGroupHeader !== true
                        anchors.fill: parent
                        anchors.margins: 3
                        radius: 6
                        property bool isHovered: itemMouseArea.containsMouse
                        property bool isSelected: popupListView.currentIndex === index
                        property bool isCompletion: modelData
                                                    && modelData.isCompletion

                        property bool isActive: popupListView.currentIndex === index
                        color: {
                            if (isActive) {
                                return (modelData
                                        && modelData.isCompletion) ? "#EBF4FF" : "#F0FDF4"
                            }
                            return "transparent"
                        }

                        border.color: {
                            if (isActive) {
                                return (modelData
                                        && modelData.isCompletion) ? "#3B82F6" : "#22C55E"
                            }
                            return "transparent"
                        }

                        border.width: (popupListView.currentIndex === index
                                       || itemMouseArea.containsMouse) ? 1 : 0

                        // Behavior on color {
                        //     ColorAnimation {
                        //         duration: 120 // 从 150 缩短到 120
                        //     }
                        // }
                        // // 修复：使用更平滑的动画过渡
                        // Behavior on color {
                        //     ColorAnimation {
                        //         duration: 200 // 增加持续时间使过渡更平滑
                        //         easing.type: Easing.OutQuad // 使用更平滑的缓动
                        //     }
                        // }

                        // Behavior on border.color {
                        //     ColorAnimation {
                        //         duration: 120
                        //     }
                        // }
                        // Behavior on border.color {
                        //     ColorAnimation {
                        //         duration: 200
                        //         easing.type: Easing.OutQuad
                        //     }
                        // }

                        // Behavior on border.width {
                        //     NumberAnimation {
                        //         duration: 200
                        //         easing.type: Easing.OutQuad
                        //     }
                        // }

                        Rectangle {
                            visible: modelData && modelData.isSeparator !== true
                                     && modelData.isGroupHeader !== true
                            width: 3
                            height: parent.height - 12
                            anchors.left: parent.left
                            anchors.leftMargin: 3
                            anchors.verticalCenter: parent.verticalCenter
                            radius: 1.5
                            color: (modelData
                                    && modelData.isCompletion) ? "#3B82F6" : "#22C55E"
                            opacity: (popupListView.currentIndex === index
                                      || itemMouseArea.containsMouse) ? 1.0 : 0.3

                            // Behavior on opacity {
                            //     NumberAnimation {
                            //         duration: 120
                            //     }
                            // }
                        }

                        RowLayout {
                            visible: modelData && modelData.isSeparator !== true
                                     && modelData.isGroupHeader !== true
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 8
                            spacing: 8

                            // 图标 - 缩小
                            Text {
                                text: modelData ? (modelData.icon || "📄") : ""
                                font.pixelSize: 14 // 从 16 缩小到 14
                                Layout.preferredWidth: 16 // 从 20 缩小到 16
                            }

                            // 文本信息 - 缩小
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1 // 从 2 缩小到 1

                                Text {
                                    text: modelData ? (modelData.text
                                                       || "") : ""
                                    font.pixelSize: 12 // 从 14 缩小到 12
                                    color: "#1F2937"
                                    font.weight: (modelData
                                                  && modelData.isCompletion) ? Font.Medium : Font.Normal
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: modelData ? (modelData.description
                                                       || "") : ""
                                    font.pixelSize: 10 // 从 11 缩小到 10
                                    color: "#9CA3AF"
                                    visible: modelData && modelData.description
                                             && modelData.description !== ""
                                    Layout.fillWidth: true
                                }
                            }

                            // 快捷键提示 - 缩小
                            Text {
                                visible: popupListView.currentIndex === index
                                text: "↵"
                                font.pixelSize: 10 // 从 12 缩小到 10
                                color: "#9CA3AF"
                                Layout.preferredWidth: 12 // 从 16 缩小到 12
                            }

                            // 删除按钮 - 缩小
                            Button {
                                id: deleteButton
                                visible: modelData
                                         && modelData.showDelete === true
                                width: 28 // 从 32 缩小到 28
                                height: 28 // 从 32 缩小到 28

                                background: Rectangle {
                                    radius: 6 // 从 8 缩小到 6
                                    color: {
                                        if (deleteButton.pressed)
                                            return "#FEE2E2"
                                        if (deleteButton.hovered)
                                            return "#FEF2F2"
                                        return "transparent"
                                    }
                                    border.color: deleteButton.hovered ? "#F87171" : "transparent"
                                    border.width: 1

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 120 // 从 150 缩短到 120
                                        }
                                    }
                                }

                                contentItem: Text {
                                    text: "🗑️"
                                    font.pixelSize: 10 // 从 12 缩小到 10
                                    color: deleteButton.hovered ? "#DC2626" : "#9CA3AF"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 120
                                        }
                                    }
                                }

                                onClicked: {
                                    if (modelData && modelData.text) {
                                        control.requestRemoveHistory(
                                                    modelData.text)
                                        historyPopup.close()
                                    }
                                }

                                ToolTip.visible: hovered
                                ToolTip.text: "删除此记录"
                                ToolTip.delay: 500
                            }
                        }

                        // 修复后的鼠标区域 - 关键修复
                        MouseArea {
                            id: itemMouseArea
                            visible: modelData && modelData.isSeparator !== true
                                     && modelData.isGroupHeader !== true
                            anchors.fill: parent
                            anchors.rightMargin: (modelData
                                                  && modelData.showDelete) ? 32 : 0 // 从 40 缩小到 32
                            hoverEnabled: true

                            propagateComposedEvents: false
                            preventStealing: true // 防止手势被窃取

                            onClicked: {
                                if (!modelData || !modelData.text)
                                    return

                                if (modelData.isCompletion) {
                                    completionItemSelected(modelData.text)
                                } else {
                                    historyItemSelected(modelData.text)
                                }
                                control.text = modelData.text
                                historyPopup.close()
                            }

                            onEntered: {
                                // 只设置当前项为选中状态
                                popupListView.currentIndex = index
                            }
                            // 不在 onExited 中做任何操作，让键盘导航控制选中状态
                        }
                    }
                }

                // 美化的滚动条 - 缩小
                ScrollBar.vertical: ScrollBar {
                    width: 6 // 从 8 缩小到 6
                    policy: ScrollBar.AsNeeded

                    background: Rectangle {
                        color: "#F3F4F6"
                        radius: 3 // 从 4 缩小到 3
                    }

                    contentItem: Rectangle {
                        radius: 3 // 从 4 缩小到 3
                        color: parent.pressed ? "#6B7280" : (parent.hovered ? "#9CA3AF" : "#D1D5DB")

                        Behavior on color {
                            ColorAnimation {
                                duration: 120 // 从 150 缩短到 120
                            }
                        }
                    }
                }
            }
        }
    }

    // 确认清除历史记录对话框
    Dialog {
        id: clearHistoryDialog
        title: "确认清除历史记录"
        modal: true
        standardButtons: Dialog.Yes | Dialog.No

        anchors.centerIn: parent

        background: Rectangle {
            color: "#FFFFFF"
            radius: 12
            border.color: "#E5E7EB"
            border.width: 1

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 8
                radius: 24
                samples: 48
                color: "#20000000"
            }
        }

        ColumnLayout {
            spacing: 16

            Text {
                text: `确定要清除所有 ${historyModel.length} 条历史记录吗？`
                font.pixelSize: 14
                color: "#374151"
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Text {
                text: "此操作无法撤销"
                font.pixelSize: 12
                color: "#EF4444"
                Layout.fillWidth: true
            }
        }

        onAccepted: {
            control.requestClearAllHistory()
            historyPopup.close()
        }
    }

    // 确认清除补全对话框
    Dialog {
        id: clearCompletionDialog
        title: "确认清除补全建议"
        modal: true
        standardButtons: Dialog.Yes | Dialog.No

        anchors.centerIn: parent

        background: Rectangle {
            color: "#FFFFFF"
            radius: 12
            border.color: "#E5E7EB"
            border.width: 1

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 8
                radius: 24
                samples: 48
                color: "#20000000"
            }
        }

        ColumnLayout {
            spacing: 16

            Text {
                text: `确定要清除所有 ${completionModel.length} 条补全建议吗？`
                font.pixelSize: 14
                color: "#374151"
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Text {
                text: "此操作无法撤销"
                font.pixelSize: 12
                color: "#D97706"
                Layout.fillWidth: true
            }
        }

        onAccepted: {
            control.requestClearAllCompletions()
            historyPopup.close()
        }
    }
}

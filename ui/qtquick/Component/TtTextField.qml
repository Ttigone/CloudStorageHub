// SecureTextField.qml
TextField {
    id: secureField
    selectByMouse: true
    color: "#FFFFFF"
    placeholderTextColor: "#8A8A8A"
    
    property bool disableCopyPaste: false
    
    // 禁用复制粘贴
    Keys.onPressed: function(event) {
        if (disableCopyPaste && 
            (event.modifiers & Qt.ControlModifier) &&
            (event.key === Qt.Key_C || event.key === Qt.Key_V || event.key === Qt.Key_X)) {
            event.accepted = true;
        }
    }
    
    // 重写粘贴行为
    onPaste: {
        if (disableCopyPaste) {
            // 阻止粘贴
        } else {
            // 允许默认粘贴行为
            paste();
        }
    }
    
    // 屏蔽上下文菜单
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        propagateComposedEvents: true
        onClicked: function(mouse) {
            if (disableCopyPaste) {
                mouse.accepted = true;
            } else {
                mouse.accepted = false;
            }
        }
        onPressed: function(mouse) {
            mouse.accepted = false;
        }
    }
    
    background: Rectangle {
        radius: 4
        color: "#3E3E42"
        border.color: secureField.focus ? "#3498db" : "#555555"
        border.width: 1
    }
}
import QtQuick 2.15

Rectangle {
    id: root

    property string message: "加载中..."
    property bool active: false

    color: active ? "#80000000" : "transparent"
    visible: active

    Behavior on color {
        ColorAnimation { duration: 200 }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.active
    }

    Rectangle {
        anchors.centerIn: parent
        width: 180
        height: 80
        radius: 8
        color: "#FFFFFF"
        
        opacity: root.active ? 1.0 : 0.0
        scale: root.active ? 1.0 : 0.9
        
        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }
        
        Behavior on scale {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        Row {
            anchors.centerIn: parent
            spacing: 12

            // 🔥 Material Design 风格的圆形进度指示器
            Rectangle {
                width: 20
                height: 20
                radius: 10
                color: "transparent"
                border.width: 2
                border.color: "#E0E0E0"

                Rectangle {
                    width: parent.width
                    height: parent.height
                    radius: parent.radius
                    color: "transparent"
                    border.width: 2
                    border.color: "#2196F3"
                    
                    // 🔥 使用简单的变换创建圆弧
                    transformOrigin: Item.Center
                    clip: true
                    
                    Rectangle {
                        width: parent.width / 2
                        height: parent.height
                        color: "#FFFFFF"
                        anchors.left: parent.left
                    }

                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 800
                        loops: Animation.Infinite
                        running: root.active
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.message
                color: "#424242"
                font.pixelSize: 14
            }
        }
    }

    function show(msg) {
        if (msg) message = msg
        active = true
    }

    function hide() {
        active = false
    }
}
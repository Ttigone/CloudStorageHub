// import QtQuick
// import QtQuick.Controls

// SplitView {
//     id: root
//     property alias splitOrientation: root.orientation
//     orientation: Qt.Horizontal
//     // handle: Rectangle {
//     //     id: handleItem
//     //     implicitWidth: root.orientation === Qt.Horizontal ? 8 : root.width
//     //     implicitHeight: root.orientation === Qt.Vertical ? 8 : root.height
//     //     color: "transparent" 
//     //     property bool hovering: SplitHandle.hovered

//     //     Item {
//     //         anchors.centerIn: parent
//     //         width: root.orientation === Qt.Horizontal ? 6 : 36
//     //         height: root.orientation === Qt.Horizontal ? 36 : 6

//     //         Rectangle {
//     //             width: root.orientation === Qt.Horizontal ? 2 : parent.width
//     //             height: root.orientation === Qt.Horizontal ? parent.height : 2

//     //             anchors {
//     //                 left: root.orientation === Qt.Horizontal ? parent.left : undefined
//     //                 top: root.orientation === Qt.Vertical ? parent.top : undefined
//     //                 verticalCenter: root.orientation
//     //                                 === Qt.Horizontal ? parent.verticalCenter : undefined
//     //                 horizontalCenter: root.orientation
//     //                                   === Qt.Vertical ? parent.horizontalCenter : undefined
//     //             }

//     //             color: "#3498DB"
//     //             opacity: 0.8
//     //             radius: 1
//     //         }

//     //         Rectangle {
//     //             width: root.orientation === Qt.Horizontal ? 2 : parent.width
//     //             height: root.orientation === Qt.Horizontal ? parent.height : 2

//     //             anchors {
//     //                 right: root.orientation === Qt.Horizontal ? parent.right : undefined
//     //                 bottom: root.orientation === Qt.Vertical ? parent.bottom : undefined
//     //                 verticalCenter: root.orientation
//     //                                 === Qt.Horizontal ? parent.verticalCenter : undefined
//     //                 horizontalCenter: root.orientation
//     //                                   === Qt.Vertical ? parent.horizontalCenter : undefined
//     //             }

//     //             color: "#3498DB"
//     //             opacity: 0.8
//     //             radius: 1
//     //         }
//     //     }

//     //     // 添加动画效果
//     //     states: [
//     //         State {
//     //             name: "hovered"
//     //             when: handleItem.hovering && !SplitHandle.pressed
//     //             PropertyChanges {
//     //                 target: handleItem
//     //                 implicitWidth: root.orientation === Qt.Horizontal ? 10 : root.width
//     //                 implicitHeight: root.orientation === Qt.Vertical ? 10 : root.height
//     //             }
//     //         },
//     //         State {
//     //             name: "pressed"
//     //             when: SplitHandle.pressed
//     //             PropertyChanges {
//     //                 target: handleItem
//     //                 implicitWidth: root.orientation === Qt.Horizontal ? 10 : root.width
//     //                 implicitHeight: root.orientation === Qt.Vertical ? 10 : root.height
//     //             }
//     //         }
//     //     ]

//     //     transitions: Transition {
//     //         NumberAnimation {
//     //             properties: "implicitWidth,implicitHeight"
//     //             duration: 100
//     //             easing.type: Easing.OutQuad
//     //         }
//     //     }

//     //     // 鼠标经过时显示不同光标
//     //     MouseArea {
//     //         anchors.fill: parent
//     //         anchors.margins: -4 // 增大点击区域
//     //         cursorShape: root.orientation === Qt.Horizontal ? Qt.SplitHCursor : Qt.SplitVCursor
//     //         enabled: false // 不处理事件，只改变光标
//     //     }

//     //     // 触摸区域指示器 - 仅在鼠标悬停时显示
//     //     Rectangle {
//     //         anchors.fill: parent
//     //         color: "#3498DB"
//     //         opacity: 0.1
//     //         visible: handleItem.hovering || SplitHandle.pressed
//     //     }
//     // }
//     // ...existing code...
// // handle: Rectangle {
// //     id: handleItem
// //     implicitWidth: root.orientation === Qt.Horizontal ? 8 : root.width
// //     implicitHeight: root.orientation === Qt.Vertical ? 8 : root.height
// //     color: "transparent" // 透明背景
// //     property bool hovering: SplitHandle.hovered

// //     // 默认显示双线分隔线（原来悬浮时的样式）
// //     Item {
// //         id: handleLines
// //         anchors.centerIn: parent
// //         width: root.orientation === Qt.Horizontal ? 6 : 36
// //         height: root.orientation === Qt.Horizontal ? 36 : 6
        
// //         // 添加颜色属性，用于状态变化
// //         property color lineColor: "#3498DB"
// //         property real lineOpacity: 0.8

// //         Rectangle {
// //             width: root.orientation === Qt.Horizontal ? 2 : parent.width
// //             height: root.orientation === Qt.Horizontal ? parent.height : 2

// //             anchors {
// //                 left: root.orientation === Qt.Horizontal ? parent.left : undefined
// //                 top: root.orientation === Qt.Vertical ? parent.top : undefined
// //                 verticalCenter: root.orientation
// //                                 === Qt.Horizontal ? parent.verticalCenter : undefined
// //                 horizontalCenter: root.orientation
// //                                   === Qt.Vertical ? parent.horizontalCenter : undefined
// //             }

// //             color: handleLines.lineColor
// //             opacity: handleLines.lineOpacity
// //             radius: 1
// //         }

// //         Rectangle {
// //             width: root.orientation === Qt.Horizontal ? 2 : parent.width
// //             height: root.orientation === Qt.Horizontal ? parent.height : 2

// //             anchors {
// //                 right: root.orientation === Qt.Horizontal ? parent.right : undefined
// //                 bottom: root.orientation === Qt.Vertical ? parent.bottom : undefined
// //                 verticalCenter: root.orientation
// //                                 === Qt.Horizontal ? parent.verticalCenter : undefined
// //                 horizontalCenter: root.orientation
// //                                   === Qt.Vertical ? parent.horizontalCenter : undefined
// //             }

// //             color: handleLines.lineColor
// //             opacity: handleLines.lineOpacity
// //             radius: 1
// //         }
// //     }

// //     // 添加动画效果
// //     states: [
// //         State {
// //             name: "hovered"
// //             when: handleItem.hovering && !SplitHandle.pressed
// //             PropertyChanges {
// //                 target: handleItem
// //                 implicitWidth: root.orientation === Qt.Horizontal ? 10 : root.width
// //                 implicitHeight: root.orientation === Qt.Vertical ? 10 : root.height
// //             }
// //         },
// //         State {
// //             name: "pressed"
// //             when: SplitHandle.pressed
// //             PropertyChanges {
// //                 target: handleItem
// //                 implicitWidth: root.orientation === Qt.Horizontal ? 10 : root.width
// //                 implicitHeight: root.orientation === Qt.Vertical ? 10 : root.height
// //             }
// //             PropertyChanges {
// //                 target: handleLines
// //                 lineColor: "#2980B9"  // 按下时颜色加深
// //                 lineOpacity: 1.0      // 按下时不透明度增加
// //             }
// //         }
// //     ]

// //     transitions: Transition {
// //         NumberAnimation {
// //             properties: "implicitWidth,implicitHeight"
// //             duration: 100
// //             easing.type: Easing.OutQuad
// //         }
// //         ColorAnimation {
// //             properties: "lineColor"
// //             duration: 150
// //             easing.type: Easing.OutQuad
// //         }
// //         NumberAnimation {
// //             properties: "lineOpacity"
// //             duration: 150
// //             easing.type: Easing.OutQuad
// //         }
// //     }

// //     // 鼠标经过时显示不同光标
// //     MouseArea {
// //         anchors.fill: parent
// //         anchors.margins: -4 // 增大点击区域
// //         cursorShape: root.orientation === Qt.Horizontal ? Qt.SplitHCursor : Qt.SplitVCursor
// //         enabled: false // 不处理事件，只改变光标
// //     }

// //     // 触摸区域指示器 - 仅在鼠标悬停时显示
// //     Rectangle {
// //         anchors.fill: parent
// //         color: "#3498DB"
// //         opacity: 0.1
// //         visible: handleItem.hovering || SplitHandle.pressed
// //     }
// // }

// }
import QtQuick
import QtQuick.Controls

SplitView {
    id: root
    property alias splitOrientation: root.orientation
    orientation: Qt.Horizontal
    
    handle: Rectangle {
        id: handleItem
        implicitWidth: root.orientation === Qt.Horizontal ? 8 : root.width
        implicitHeight: root.orientation === Qt.Vertical ? 8 : root.height
        color: "transparent" // 透明背景
        property bool hovering: SplitHandle.hovered

        // 默认显示双线分隔线（原来悬浮时的样式）
        Item {
            id: handleLines
            anchors.centerIn: parent
            width: root.orientation === Qt.Horizontal ? 6 : 36
            height: root.orientation === Qt.Horizontal ? 36 : 6
            
            // 添加颜色属性，用于状态变化 - 保持白色底色方案
            property color lineColor: "#CCCCCC"  // 默认浅灰色
            property real lineOpacity: 0.8       // 稍微透明

            Rectangle {
                width: root.orientation === Qt.Horizontal ? 2 : parent.width
                height: root.orientation === Qt.Horizontal ? parent.height : 2

                anchors {
                    left: root.orientation === Qt.Horizontal ? parent.left : undefined
                    top: root.orientation === Qt.Vertical ? parent.top : undefined
                    verticalCenter: root.orientation
                                    === Qt.Horizontal ? parent.verticalCenter : undefined
                    horizontalCenter: root.orientation
                                      === Qt.Vertical ? parent.horizontalCenter : undefined
                }

                color: handleLines.lineColor
                opacity: handleLines.lineOpacity
                radius: 1
            }

            Rectangle {
                width: root.orientation === Qt.Horizontal ? 2 : parent.width
                height: root.orientation === Qt.Horizontal ? parent.height : 2

                anchors {
                    right: root.orientation === Qt.Horizontal ? parent.right : undefined
                    bottom: root.orientation === Qt.Vertical ? parent.bottom : undefined
                    verticalCenter: root.orientation
                                    === Qt.Horizontal ? parent.verticalCenter : undefined
                    horizontalCenter: root.orientation
                                      === Qt.Vertical ? parent.horizontalCenter : undefined
                }

                color: handleLines.lineColor
                opacity: handleLines.lineOpacity
                radius: 1
            }
        }

        // 添加动画效果
        states: [
            State {
                name: "hovered"
                when: handleItem.hovering && !SplitHandle.pressed
                PropertyChanges {
                    target: handleItem
                    implicitWidth: root.orientation === Qt.Horizontal ? 10 : root.width
                    implicitHeight: root.orientation === Qt.Vertical ? 10 : root.height
                }
                PropertyChanges {
                    target: handleLines
                    lineColor: "#3498DB"  // 悬停时蓝色
                    lineOpacity: 0.9
                }
            },
            State {
                name: "pressed"
                when: SplitHandle.pressed
                PropertyChanges {
                    target: handleItem
                    implicitWidth: root.orientation === Qt.Horizontal ? 10 : root.width
                    implicitHeight: root.orientation === Qt.Vertical ? 10 : root.height
                }
                PropertyChanges {
                    target: handleLines
                    lineColor: "#2980B9"  // 按下时深蓝色
                    lineOpacity: 1.0      // 完全不透明
                }
            }
        ]

        transitions: Transition {
            NumberAnimation {
                properties: "implicitWidth,implicitHeight"
                duration: 100
                easing.type: Easing.OutQuad
            }
            ColorAnimation {
                properties: "lineColor"
                duration: 150
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                properties: "lineOpacity"
                duration: 150
                easing.type: Easing.OutQuad
            }
        }

        // 鼠标经过时显示不同光标
        MouseArea {
            anchors.fill: parent
            anchors.margins: -4 // 增大点击区域
            cursorShape: root.orientation === Qt.Horizontal ? Qt.SplitHCursor : Qt.SplitVCursor
            enabled: false // 不处理事件，只改变光标
        }

        // 触摸区域指示器 - 透明蓝色背景
        Rectangle {
            anchors.fill: parent
            color: "#3498DB"  // 蓝色背景
            opacity: 0.1      // 透明度
            visible: handleItem.hovering || SplitHandle.pressed
        }
    }
}
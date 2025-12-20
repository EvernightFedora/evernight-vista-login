import QtQuick 2.2
import QtQuick.Layouts 1.2
import QtQuick.Controls 2.4

TextField {
    placeholderTextColor: config.color
    color: "#000000"
    font.pointSize: config.fontSize
    font.family: config.font
    width: parent.width
    background: Rectangle {
        color: "#FFFFFF"
        radius: 10
        width: parent.width
        height: parent.height
    
        anchors.fill: parent
    }

    Rectangle {
        id: inputBorder
        width: parent.width + 4
        height: parent.height + 4
        radius: 10
        anchors.centerIn: parent
        visible: parent.focus
        z: -1

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#00FFFF" }
            GradientStop { position: 1.0; color: "#00FFFF" }
        }
    }

}

import "components"

import QtQuick 2.2
import QtQuick.Layouts 1.2
import QtQuick.Controls 2.4

import org.kde.plasma.plasma5support 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents

import org.kde.kirigami 2.20 as Kirigami
import Qt5Compat.GraphicalEffects

Item {

    id: root

        /*
     * Any message to be displayed to the user, visible above the text fields
     */
    property alias notificationMessage: notificationsLabel.text

    /*
     * A model with a list of users to show in the view
     * The following roles should exist:
     *  - name
     *  - iconSource
     *
     * The following are also handled:
     *  - vtNumber
     *  - displayNumber
     *  - session
     *  - isTty
     */
    property alias userListModel: userListView.model

    /*
     * Self explanatory
     */
    property alias userListCurrentIndex: userListView.currentIndex
    property alias userListCurrentItem: userListView.currentItem
    property var userListCurrentModelData: userListView.currentItem === null ? [] : userListView.currentItem.m
    property bool showUserList: true

    property alias userList: userListView

    property Item mainPasswordBox: passwordBox

    property bool showUsernamePrompt: !showUserList

    property string lastUserName
    property bool loginScreenUiVisible: false

    //the y position that should be ensured visible when the on screen keyboard is visible
    property int visibleBoundary: mapFromItem(loginButton, 0, 0).y
    onHeightChanged: visibleBoundary = mapFromItem(loginButton, 0, 0).y + loginButton.height + Kirigami.Units.smallSpacing

    signal loginRequest(string username, string password, int sessionIndex)

    onShowUsernamePromptChanged: {
        if (!showUsernamePrompt) {
            lastUserName = ""
        }
    }

    StackView.onActivating: {
        // Controls are not visible yet.
        Qt.callLater(focusFirstVisibleFormControl);
    }

    function focusFirstVisibleFormControl() {
        const nextControl = (userNameInput.visible
            ? userNameInput
            : (passwordBox.visible
                ? passwordBox
                : loginButton));
        // Using TabFocusReason, so that the loginButton gets the visual highlight.
        nextControl.forceActiveFocus(Qt.TabFocusReason);
    }

    /*
    * Login has been requested with the following username and password
    * If username field is visible, it will be taken from that, otherwise from the "name" property of the currentIndex
    */
    function startLogin() {
        var username = showUsernamePrompt ? userNameInput.text : userListView.selectedUser
        var password = passwordBox.text

        //this is partly because it looks nicer
        //but more importantly it works round a Qt bug that can trigger if the app is closed with a TextField focused
        //DAVE REPORT THE FRICKING THING AND PUT A LINK
        loginButton.forceActiveFocus();
        loginRequest(username, password, sessionButton.currentIndex);
    }

    // Gets the system time to determinate the correct greeting
    property int hours

    PlasmaCore.DataSource {
        id: timeSource
        engine: "time"
        connectedSources: ["Local"]
        interval: 1000
        onDataChanged: {
            var date = new Date(data["Local"]["DateTime"]);
            hours = date.getHours();
            // minutes = date.getMinutes();
            // seconds = date.getSeconds();
        }
        Component.onCompleted: {
            onDataChanged();
            root.focusFirstVisibleFormControl();
        }
    }

    //goal is to show the prompts, in ~16 grid units high, then the action buttons
    //but collapse the space between the prompts and actions if there's no room
    //ui is constrained to 16 grid units wide, or the screen
             
    // Avatar image and user list column
    Item {
        id: userListColumn

        anchors.centerIn: parent
        anchors.verticalCenterOffset: -(width)
        
        width: 230
        height: width

        UserImage {
            id: userImage
            avatarPath: userListCurrentModelData.icon || ""
            iconSource: userListCurrentModelData.iconName || "user-identity"
            anchors.centerIn: parent
            //anchors.verticalCenterOffset: -(userListView.height / 2)
            width: 150
            height: width
        }

        // Semi-transparent border aroud user image

        DropShadow {
            anchors.fill: userImage
            horizontalOffset: 0
            verticalOffset: 0
            radius: 70
            samples: 100
            color: "#4E27A9"
            source: userImage
        }

        DropShadow {
            anchors.fill: userImage
            horizontalOffset: 0
            verticalOffset: 0
            radius: 100
            samples: 100
            color: "#4E27A9"
            source: userImage
            z: -1
        }

        // Display username below the greeting label to correctly manage the label size in case that User-Name isn't available
        Label {
            id: userName
            
            anchors.centerIn: parent
            
            anchors.verticalCenterOffset: userImage.height + userList.height
            text: userListCurrentModelData.realName || userListCurrentModelData.name
            color: "#00C7FD"
            style: softwareRendering ? Text.Outline : Text.Normal
            styleColor: softwareRendering ? ColorScope.backgroundColor : "transparent" //no outline, doesn't matter
            font.pointSize: userListCurrentModelData.realName ? 20 : 14
            font.family: config.font
            font.bold: true
            wrapMode: Text.WordWrap
        }

        UserList {
            id: userListView
            visible: showUserList && y > 0
            anchors {
                top: userImage.bottom
                left: parent.left
                right: parent.right
                margins: height / 2
            }
            fontSize: 13
            onUserSelected: root.focusFirstVisibleFormControl()
        }
        
    }
    RowLayout {
        id: prompts
        
        anchors.fill: parent

        // Greeting, password and username prompts column
        ColumnLayout {
            Layout.maximumWidth: parent.width / 2
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.topMargin: 220
            spacing: 15
            // User name input in case user is not included in user-list
            Input {
                id: userNameInput
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                text: lastUserName
                visible: showUsernamePrompt
                focus: showUsernamePrompt && !lastUserName //if there's a username prompt it gets focus first, otherwise password does
                Layout.topMargin: 50
                placeholderText: i18nd("plasma-desktop-sddm-theme", "Username")

                onAccepted:
                    if (root.loginScreenUiVisible) {
                        passwordBox.forceActiveFocus()
                    }
            }

            // Passwrod and login button row
            RowLayout {
                
                Layout.fillWidth: true
                Layout.topMargin: 20

                Input {
                    id: passwordBox
                    placeholderText: i18nd("plasma-desktop-sddm-theme", "Password")
                    focus: !showUsernamePrompt || lastUserName
                    echoMode: TextInput.Password

                    Layout.fillWidth: true
                    Layout.preferredHeight: 40

                    onAccepted: {
                        if (root.loginScreenUiVisible) {
                            startLogin();
                        }
                    }

                    Keys.onEscapePressed: {
                        mainStack.currentItem.forceActiveFocus();
                    }

                    //if empty and left or right is pressed change selection in user switch
                    //this cannot be in keys.onLeftPressed as then it doesn't reach the password box
                    Keys.onPressed: {
                        if (event.key == Qt.Key_Left && !text) {
                            userListView.decrementCurrentIndex();
                            event.accepted = true
                        }
                        if (event.key == Qt.Key_Right && !text) {
                            userListView.incrementCurrentIndex();
                            event.accepted = true
                        }
                    }

                    Connections {
                        target: sddm
                        onLoginFailed: {
                            passwordBox.selectAll()
                            passwordBox.forceActiveFocus()
                        }
                    }
                }

           
                Button {
                    id: loginButton

                    Layout.leftMargin: 10
                    Layout.preferredHeight: passwordBox.height + 4
                    Layout.preferredWidth: text.length === 0 ? loginButton.Layout.preferredHeight + 10 : -1
                    Accessible.name: i18nd("plasma-desktop-sddm-theme", "Log In")

                    font.pointSize: config.fontSize
                    font.family: config.font

                    Kirigami.Icon {
                        id: settingsImage
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.leftMargin: (loginButton.focus || mouseArea.containsMouse) ? 5 : 0
                        anchors.fill: parent
                        source: Qt.resolvedUrl("assets/button_arrow.svg")
                        Behavior on anchors.leftMargin { 
                            PropertyAnimation {
                                duration: 100
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }
                    text: root.showUsernamePrompt || userList.currentItem.needsPassword ? "" : i18n("Log In")

                    background: Rectangle {
                        id: buttonBackground
                        radius: 10
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#CF90A1" }
                            GradientStop { position: 1.0; color: "#CF90A1" }
                            orientation: Gradient.Horizontal
                        }
                    }

                    onClicked: startLogin();

                    MouseArea {
                        id: mouseArea
                        hoverEnabled: true
                        onClicked: loginButton.clicked()
                        anchors.fill: parent
                    }
                }
                
            }

            // Notifications - login state label
            PlasmaComponents.Label {
                id: notificationsLabel
                Layout.maximumWidth: Kirigami.Units.gridUnit * 16
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                font.italic: true
            }

            RowLayout {
                id: footer

                Layout.alignment: Qt.AlignHCenter

                Behavior on opacity {
                    OpacityAnimator {
                        duration: Kirigami.Units.longDuration
                    }
                }

                PlasmaComponents.ToolButton {
                    id: virtualKeyboardButton
                    // text: i18ndc("plasma-desktop-sddm-theme", "Button to show/hide virtual keyboard", "Virtual Keyboard")
                    icon.name: inputPanel.keyboardActive ? "input-keyboard-virtual-on" : "input-keyboard-virtual-off"
                    visible: inputPanel.status == Loader.Ready

                    onClicked: {
                        // Otherwise the password field loses focus and virtual keyboard
                        // keystrokes get eaten
                        mainPasswordBox.forceActiveFocus();
                        inputPanel.showHide()
                    }
                }

                KeyboardButton {
                }

                SessionButton {
                    id: sessionButton
                    onSessionChanged: {
                        // Otherwise the password field loses focus and virtual keyboard
                        // keystrokes get eaten
                        mainPasswordBox.forceActiveFocus();
                    }
                }
            }
        }

    }
}

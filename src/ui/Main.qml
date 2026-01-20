import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt.labs.platform as Platform
import Qt5Compat.GraphicalEffects

ApplicationWindow {
    id: root
    width: 900
    minimumWidth: 800
    minimumHeight: 400
    visible: true
    title: qsTr("PS4 PKG Unpacker")

    SystemPalette { id: systemPalette; colorGroup: SystemPalette.Active }

    // Auto-size height to content
    height: Math.min(contentLayout.implicitHeight + menuBar.height + 60, Screen.desktopAvailableHeight * 0.9)

    Timer {
        id: resizeTimer
        interval: 50
        onTriggered: root.height = Qt.binding(function() {
            return Math.min(contentLayout.implicitHeight + menuBar.height + 60, Screen.desktopAvailableHeight * 0.9)
        })
    }

    Connections {
        target: unpacker
        function onPkgInfoChanged() {
            resizeTimer.restart();
        }
        function onStatusChanged() {
            resizeTimer.restart();
        }
    }

    // Native platform dialogs
    Platform.FileDialog {
        id: pkgFileDialog
        title: qsTr("Select PKG file")
        nameFilters: [qsTr("PKG files (*.pkg)"), qsTr("All files (*)")]
        onAccepted: {
            let path = file.toString();
            if (path.startsWith("file://")) {
                path = path.substring(7);
            }
            // Decode URL encoding (e.g., %5B -> [, %5D -> ])
            path = decodeURIComponent(path);
            pkgPathField.text = path;
            unpacker.openPkg(path);
        }
    }

    Platform.FolderDialog {
        id: destDirDialog
        title: qsTr("Select destination directory")
        onAccepted: {
            let path = folder.toString();
            if (path.startsWith("file://")) {
                path = path.substring(7);
            }
            // Decode URL encoding
            path = decodeURIComponent(path);
            destPathField.text = path;
        }
    }

    Dialog {
        id: msgDialog
        title: qsTr("Extraction Finished")
        modal: true
        anchors.centerIn: parent
        width: 500
        standardButtons: Dialog.Ok

        property alias text: messageLabel.text

        Label {
            id: messageLabel
            anchors.fill: parent
            anchors.margins: 20
            wrapMode: Text.WordWrap
            verticalAlignment: Text.AlignVCenter
        }
    }

    Dialog {
        id: patchDialog
        title: qsTr("Patch Detected!")
        modal: true
        anchors.centerIn: parent
        width: Math.min(patchMessageLabel.implicitWidth + 80, 500)
        height: Math.min(patchMessageLabel.implicitHeight + 120, 300)
        standardButtons: Dialog.Yes | Dialog.No

        property string patchVersion: ""
        property string installedVersion: ""
        property string compareResult: ""

        Label {
            id: patchMessageLabel
            width: parent.width - 40
            anchors.centerIn: parent
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignLeft
        }

        onAccepted: {
            unpacker.extract(destPathField.text, deleteAfterCheck.checked);
        }
    }

    // System themed background
    background: Rectangle {
        color: systemPalette.window
    }

    menuBar: MenuBar {
        Menu {
            title: qsTr("File")
            Action {
                text: qsTr("&Open PKG...")
                shortcut: StandardKey.Open
                onTriggered: pkgFileDialog.open()
            }
            MenuSeparator {}
            Action {
                text: qsTr("&Quit")
                shortcut: StandardKey.Quit
                onTriggered: Qt.quit()
            }
        }

        Menu {
            title: qsTr("Help")
            Action {
                text: qsTr("&About")
                onTriggered: aboutDialog.open()
            }
        }
    }

    // Main content
    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.margins: 30
        spacing: 20

        // Hero title
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 90

            Rectangle {
                anchors.fill: parent
                radius: 10
                color: systemPalette.highlight
                opacity: 0.1
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 5

                Label {
                    text: "🎮 PS4 PKG UNPACKER"
                    font.pixelSize: 28
                    font.bold: true
                    font.letterSpacing: 1.5
                    color: systemPalette.highlight
                    Layout.alignment: Qt.AlignHCenter
                }

                Label {
                    text: "Extract PlayStation 4 Package Files"
                    font.pixelSize: 12
                    font.italic: true
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // File selection card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: fileSelectionLayout.implicitHeight + 40
            color: systemPalette.base
            radius: 8
            border.color: systemPalette.mid
            border.width: 1

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 2
                radius: 6
                samples: 13
                color: "#30000000"
            }

            ColumnLayout {
                id: fileSelectionLayout
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15

                Label {
                    text: "📁 FILE SELECTION"
                    font.pixelSize: 14
                    font.bold: true
                    font.letterSpacing: 0.5
                    color: systemPalette.highlight
                }

                // PKG File Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Label {
                        text: "PKG File:"
                        font.pixelSize: 12
                        Layout.preferredWidth: 85
                    }

                    TextField {
                        id: pkgPathField
                        Layout.fillWidth: true
                        placeholderText: qsTr("Select a PKG file...")
                        readOnly: true
                    }

                    Button {
                        text: "Browse"
                        Layout.preferredWidth: 90
                        onClicked: pkgFileDialog.open()
                    }
                }

                // Destination Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Label {
                        text: "Destination:"
                        font.pixelSize: 12
                        Layout.preferredWidth: 85
                    }

                    TextField {
                        id: destPathField
                        Layout.fillWidth: true
                        placeholderText: qsTr("Select destination directory...")
                        readOnly: true
                    }

                    Button {
                        text: "Browse"
                        Layout.preferredWidth: 90
                        onClicked: destDirDialog.open()
                    }
                }

                // Cleanup option
                CheckBox {
                    id: deleteAfterCheck
                    text: qsTr("Delete PKG file after successful extraction")
                    font.pixelSize: 11
                }
            }
        }

        // PKG Information card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: pkgInfoLayout.implicitHeight + 40
            visible: unpacker.titleId !== ""
            color: systemPalette.base
            radius: 8
            border.color: systemPalette.mid
            border.width: 1

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 2
                radius: 6
                samples: 13
                color: "#30000000"
            }

            ColumnLayout {
                id: pkgInfoLayout
                anchors.fill: parent
                anchors.margins: 20
                spacing: 10

                Label {
                    text: "ℹ️ PKG INFORMATION"
                    font.pixelSize: 14
                    font.bold: true
                    font.letterSpacing: 0.5
                    color: systemPalette.highlight
                }

                GridLayout {
                    columns: 2
                    rowSpacing: 8
                    columnSpacing: 15
                    Layout.fillWidth: true

                    Label {
                        text: "Title ID:"
                        font.pixelSize: 12
                        font.bold: true
                    }
                    Label {
                        text: unpacker.titleId
                        font.pixelSize: 12
                        Layout.fillWidth: true
                    }

                    Label {
                        text: "Title:"
                        font.pixelSize: 12
                        font.bold: true
                    }
                    Label {
                        text: unpacker.title
                        font.pixelSize: 12
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        // Progress card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: progressLayout.implicitHeight + 40
            visible: unpacker.isExtracting || unpacker.progress > 0
            color: systemPalette.base
            radius: 8
            border.color: systemPalette.mid
            border.width: 1

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 2
                radius: 6
                samples: 13
                color: "#30000000"
            }

            ColumnLayout {
                id: progressLayout
                anchors.fill: parent
                anchors.margins: 20
                spacing: 10

                Label {
                    text: "⚡ EXTRACTION PROGRESS"
                    font.pixelSize: 14
                    font.bold: true
                    font.letterSpacing: 0.5
                    color: systemPalette.highlight
                }

                ProgressBar {
                    id: progressBar
                    Layout.fillWidth: true
                    value: unpacker.progress / 100.0
                }

                Label {
                    text: unpacker.status
                    font.pixelSize: 11
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Extract/Cancel buttons
        RowLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: 450
            Layout.alignment: Qt.AlignHCenter
            spacing: 15

            Button {
                text: "🚀 Extract PKG"
                font.pixelSize: 14
                font.bold: true
                Layout.fillWidth: true
                Layout.preferredHeight: 45
                enabled: pkgPathField.text !== "" && destPathField.text !== "" && !unpacker.isExtracting
                highlighted: true

                onClicked: {
                    // Check if this is a patch and if it needs confirmation
                    var patchStatus = unpacker.checkPatchStatus(destPathField.text);

                    if (patchStatus === "notinstalled") {
                        msgDialog.title = qsTr("Error");
                        msgDialog.text = qsTr("This PKG is a patch, but the game is not installed in the selected directory.\n\nPlease install the base game first.");
                        msgDialog.open();
                        return;
                    }

                    if (patchStatus !== "") {
                        // Parse the status string: "type|pkgVer|installedVer"
                        var parts = patchStatus.split("|");
                        var compareType = parts[0];
                        var pkgVer = parts[1];
                        var instVer = parts[2];

                        patchDialog.patchVersion = pkgVer;
                        patchDialog.installedVersion = instVer;

                        if (compareType === "match") {
                            patchMessageLabel.text = qsTr("Patch detected!\n\nPKG and Game versions match: ") + pkgVer + qsTr("\n\nWould you like to overwrite?");
                        } else if (compareType === "older") {
                            patchMessageLabel.text = qsTr("Patch detected!\n\nPKG Version ") + pkgVer + qsTr(" is older than installed version: ") + instVer + qsTr("\n\nWould you like to overwrite?");
                        } else {
                            patchMessageLabel.text = qsTr("Patch detected!\n\nGame is installed: ") + instVer + qsTr("\nWould you like to install Patch: ") + pkgVer + " ?";
                        }

                        patchDialog.open();
                    } else {
                        // Not a patch or no conflict, proceed directly
                        unpacker.extract(destPathField.text, deleteAfterCheck.checked);
                    }
                }
            }

            Button {
                text: "⏹ Cancel"
                font.pixelSize: 14
                font.bold: true
                Layout.preferredWidth: 120
                Layout.preferredHeight: 45
                visible: unpacker.isExtracting
                enabled: unpacker.status !== "Cancelling..."

                onClicked: {
                    unpacker.cancelExtraction();
                }
            }
        }
    }

    Connections {
        target: unpacker
        function onExtractionFinished(success, message) {
            msgDialog.text = message;
            msgDialog.open();
            resizeTimer.restart();
        }
    }

    Dialog {
        id: aboutDialog
        title: "About PS4 PKG Unpacker"
        modal: true
        anchors.centerIn: parent
        width: 450
        standardButtons: Dialog.Ok

        ColumnLayout {
            anchors.fill: parent
            spacing: 15

            Label {
                text: "PS4 PKG Unpacker"
                font.pixelSize: 16
                font.bold: true
                color: systemPalette.highlight
            }

            Label {
                text: "A modern tool for extracting PlayStation 4 package files"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }
}

import QtQuick
import "../../../core"
import "../../../widgets"

Item {
    id: root
    property var action
    property var selectionMode

    property string description: {
        const SnipAction = { Copy: 0, Edit: 1, Search: 2, CharRecognition: 3, Record: 4, RecordWithSound: 5 };
        switch (root.action) {
            case SnipAction.Copy:
            case SnipAction.Edit:
                return "Copy region (LMB) or annotate (RMB)";
            case SnipAction.Search:
                return "Search with Google Lens";
            case SnipAction.CharRecognition:
                return "Recognize text";
            case SnipAction.Record:
            case SnipAction.RecordWithSound:
                return "Record region";
            default:
                return "";
        }
    }
    
    property string materialSymbol: {
        const SnipAction = { Copy: 0, Edit: 1, Search: 2, CharRecognition: 3, Record: 4, RecordWithSound: 5 };
        switch (root.action) {
            case SnipAction.Copy:
            case SnipAction.Edit:
                return "content_cut";
            case SnipAction.Search:
                return "image_search";
            case SnipAction.CharRecognition:
                return "document_scanner";
            case SnipAction.Record:
            case SnipAction.RecordWithSound:
                return "videocam";
            default:
                return "";
        }
    }

    property bool showDescription: true
    function hideDescription() {
        root.showDescription = false
    }
    Timer {
        id: descTimeout
        interval: 1000
        running: true
        onTriggered: {
            root.hideDescription()
        }
    }
    onActionChanged: {
        root.showDescription = true
        descTimeout.restart()
    }

    property int margins: 8
    implicitWidth: content.implicitWidth + margins * 2
    implicitHeight: content.implicitHeight + margins * 2

    Rectangle {
        id: content
        anchors.centerIn: parent

        property real padding: 8
        implicitHeight: 38
        implicitWidth: root.showDescription ? contentRow.implicitWidth + padding * 2 : implicitHeight
        clip: true

        radius: 19

        color: Appearance.colors.colPrimary

        Behavior on implicitWidth {
            NumberAnimation { duration: 200 }
        }

        Row {
            id: contentRow
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                leftMargin: content.padding
            }
            spacing: 12

            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                iconSize: 22
                color: Appearance.colors.colOnPrimary
                text: root.materialSymbol
            }

            FadeLoader {
                id: descriptionLoader
                anchors.verticalCenter: parent.verticalCenter
                shown: root.showDescription
                sourceComponent: StyledText {
                    color: Appearance.colors.colOnPrimary
                    text: root.description
                }
            }
        }
    }
}

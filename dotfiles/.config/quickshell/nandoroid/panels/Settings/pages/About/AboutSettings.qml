import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import "."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Io

Flickable {
    id: root
    width: parent ? parent.width : 0
    height: parent ? parent.height : 0
    contentHeight: mainCol.implicitHeight + 48
    clip: true

    ScrollBar.vertical: StyledScrollBar {}

    SequentialAnimation {
        id: highlightAnim
        property var target: null
        NumberAnimation { target: highlightAnim.target; property: "opacity"; from: 1; to: 0.3; duration: 200 }
        NumberAnimation { target: highlightAnim.target; property: "opacity"; from: 0.3; to: 1; duration: 400 }
    }

    property string currentView: "main" // "main", "update", "dependency", or "credits"

    onCurrentViewChanged: {
        root.contentY = 0
    }

    onVisibleChanged: {
        if (!visible) root.currentView = "main"
        if (visible && root.currentView === "main" && !dependencyPage.isScanning) {
             dependencyPage.scanDependencies();
        }
    }

    Component.onCompleted: {
        dependencyPage.scanDependencies();
    }

    FileView {
        id: versionView
        path: Directories.home.replace("file://", "") + "/.config/quickshell/nandoroid/version.json"
        watchChanges: true
        JsonAdapter {
            id: versionData
            property string version: "1.2"
        }
    }

    ColumnLayout {
        id: mainCol
        width: parent.width
        spacing: 32

        // ── Header ──
        ColumnLayout {
            spacing: 4
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Back Button (only in sub-pages)
                RippleButton {
                    visible: root.currentView !== "main"
                    implicitWidth: 40
                    implicitHeight: 40
                    buttonRadius: 20
                    colBackground: Appearance.colors.colLayer1
                    onClicked: root.currentView = "main"
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "arrow_back"
                        iconSize: 24
                        color: Appearance.colors.colOnLayer1
                    }
                }

                StyledText {
                    text: {
                        if (root.currentView === "main") return "About"
                        if (root.currentView === "update") return "Shell Update"
                        if (root.currentView === "dependency") return "Dependency Check"
                        if (root.currentView === "credits") return "Special Thanks"
                        return "About"
                    }
                    font.pixelSize: Appearance.font.pixelSize.huge
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }
            }

            StyledText {
                text: {
                    if (root.currentView === "main") return "System information and shell details."
                    if (root.currentView === "update") return "Manage shell update channels and fetch new versions."
                    if (root.currentView === "dependency") return "Check and install missing system dependencies."
                    if (root.currentView === "credits") return "Contributors and projects that made Nandoroid possible."
                    return ""
                }
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
            }
        }

        // ── Main View ──
        AboutMainView {
            visible: root.currentView === "main"
            Layout.fillWidth: true
            version: versionData.version
            onPushView: (view) => root.currentView = view
        }

        // ── Update Sub-page ──
        AboutUpdate {
            visible: root.currentView === "update"
            Layout.fillWidth: true
        }

        // ── Dependency Sub-page ──
        AboutDependency {
            id: dependencyPage
            visible: root.currentView === "dependency"
            Layout.fillWidth: true
        }

        // ── Credits Sub-page ──
        AboutCredits {
            visible: root.currentView === "credits"
            Layout.fillWidth: true
        }

        Item { Layout.fillHeight: true }
    }
}

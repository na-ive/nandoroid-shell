import "../../../../core"
import "../../../../services"
import "../../../../widgets"
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

    property string currentView: "main" // "main", "update", "dependency", or "credits"


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
            property string version: "0.95-alpha"
        }
    }

    ColumnLayout {
        id: mainCol
        width: parent.width
        spacing: 32

        // ── Header ──
        ColumnLayout {
            spacing: 4
            Layout.fillWidth: true
            
            RowLayout {
                spacing: 12
                Layout.fillWidth: true

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
                        if (root.currentView === "update") return "Shell Update"
                        if (root.currentView === "dependency") return "Dependency Check"
                        if (root.currentView === "credits") return "Special Thanks"
                        return "About"
                    }
                    font.pixelSize: Appearance.font.pixelSize.huge
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer1
                }
            }

            StyledText {
                visible: root.currentView === "main"
                text: "System information and project branding."
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
            }
        }

        // ── Main View ──
        ColumnLayout {
        AboutMainView {
            visible: root.currentView === "main"
            Layout.fillWidth: true
            version: versionData.version
            onPushView: (viewName) => { root.currentView = viewName }
        }
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

    // ── Internal Components ──

}

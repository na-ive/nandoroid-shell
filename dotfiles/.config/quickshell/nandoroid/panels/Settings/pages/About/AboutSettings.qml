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
            property string version: "1.0"
        }
    }

    ColumnLayout {
        id: mainCol
        width: parent.width
        spacing: 32

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

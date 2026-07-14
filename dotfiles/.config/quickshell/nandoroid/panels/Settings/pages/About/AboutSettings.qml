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
    contentHeight: mainCol.implicitHeight + (48 * Appearance.effectiveScale)
    clip: true

    ScrollBar.vertical: StyledScrollBar {}

    SequentialAnimation {
        id: highlightAnim
        property var target: null
        NumberAnimation { target: highlightAnim.target; property: "opacity"; from: 1; to: 0.3; duration: 200 }
        NumberAnimation { target: highlightAnim.target; property: "opacity"; from: 0.3; to: 1; duration: 400 }
    }

    readonly property string currentView: GlobalStates.settingsAboutView

    onCurrentViewChanged: {
        root.contentY = 0
    }

    onVisibleChanged: {
        if (!visible) GlobalStates.settingsAboutView = "main"
        if (visible && GlobalStates.settingsAboutView === "main" && !dependencyPage.isScanning) {
             dependencyPage.scanDependencies();
        }
    }

    Component.onCompleted: {
        dependencyPage.scanDependencies();
    }

    FileView {
        id: versionView
        path: Directories.home.replace("file://", "") + "/.config/nandoroid/version.json"
        watchChanges: true
        JsonAdapter {
            id: versionData
            property string version: "1.4.0"
        }
    }

    ColumnLayout {
        id: mainCol
        width: parent.width - (24 * Appearance.effectiveScale)
        spacing: 32 * Appearance.effectiveScale

        // ── Header ──
        ColumnLayout {
            spacing: 4 * Appearance.effectiveScale
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 12 * Appearance.effectiveScale

                // Back Button (only in sub-pages)
                RippleButton {
                    visible: root.currentView !== "main"
                    implicitWidth: 40 * Appearance.effectiveScale
                    implicitHeight: 40 * Appearance.effectiveScale
                    buttonRadius: 20 * Appearance.effectiveScale
                    colBackground: Appearance.colors.colLayer1
                    onClicked: GlobalStates.settingsAboutView = "main"
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "arrow_back"
                        iconSize: 24 * Appearance.effectiveScale
                        color: Appearance.colors.colOnLayer1
                    }
                }

                StyledText {
                    text: {
                        if (GlobalStates.settingsAboutView === "main") return "About"
                        if (GlobalStates.settingsAboutView === "update") return "Shell Update"
                        if (GlobalStates.settingsAboutView === "dependency") return "Dependency Check"
                        if (GlobalStates.settingsAboutView === "credits") return "Special Thanks"
                        return "About"
                    }
                    font.pixelSize: Math.round(24 * Appearance.effectiveScale)
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }
            }

            StyledText {
                text: {
                    if (GlobalStates.settingsAboutView === "main") return "System information and shell details."
                    if (GlobalStates.settingsAboutView === "update") return "Manage shell update channels and fetch new versions."
                    if (GlobalStates.settingsAboutView === "dependency") return "Check and install missing system dependencies."
                    if (GlobalStates.settingsAboutView === "credits") return "Contributors and projects that made Nandoroid possible."
                    return ""
                }
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
            }
        }

        // ── Main View ──
        AboutMainView {
            visible: GlobalStates.settingsAboutView === "main"
            Layout.fillWidth: true
            version: versionData.version
            onPushView: (view) => GlobalStates.settingsAboutView = view
        }

        // ── Update Sub-page ──
        AboutUpdate {
            visible: GlobalStates.settingsAboutView === "update"
            Layout.fillWidth: true
        }

        // ── Dependency Sub-page ──
        AboutDependency {
            id: dependencyPage
            visible: GlobalStates.settingsAboutView === "dependency"
            Layout.fillWidth: true
        }

        // ── Credits Sub-page ──
        AboutCredits {
            visible: GlobalStates.settingsAboutView === "credits"
            Layout.fillWidth: true
        }

        Item { Layout.fillHeight: true }
    }
}

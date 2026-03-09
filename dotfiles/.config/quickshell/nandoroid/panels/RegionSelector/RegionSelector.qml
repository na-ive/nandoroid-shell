pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../core"
import "../../core/functions" as Functions
import "utils"

Scope {
    id: root

    function dismiss() {
        GlobalStates.regionSelectorOpen = false
    }    readonly property int actionCopy: 0
    readonly property int actionEdit: 1
    readonly property int actionSearch: 2
    readonly property int actionOCR: 3
    readonly property int actionRecord: 4
    readonly property int actionRecordWithSound: 5
    readonly property int actionRecordFullscreenWithSound: 6
    
    readonly property int modeRect: 0
    readonly property int modeCircle: 1

    property int action: actionCopy
    property int selectionMode: modeRect

    Component.onCompleted: {
    }

    
    Connections {
        target: GlobalStates
        function onRegionSelectorOpenChanged() {
        }
    }

    Variants {
        model: Quickshell.screens
        
        delegate: Loader {
            id: regionSelectorLoader
            required property var modelData

            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(regionSelectorLoader.modelData)
            property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor?.id)

            active: GlobalStates.regionSelectorOpen && (Config.ready && Config.options.regionSelector && (!Config.options.regionSelector.showOnlyOnFocusedMonitor || monitorIsFocused))
            
            onStatusChanged: {
                if (status === Loader.Error) {
                    console.error(`[RegionSelector] Error loading RegionSelection: ${regionSelectorLoader.sourceComponent ? regionSelectorLoader.sourceComponent.errorString() : "unknown error"}`)
                }
            }
            
            source: "RegionSelection.qml"

            onLoaded: {
                item.screen = regionSelectorLoader.modelData
                item.action = root.action
                item.selectionMode = root.selectionMode
                item.dismiss.connect(root.dismiss)
            }
        }
    }

    function screenshot() {
        root.action = actionCopy
        root.selectionMode = modeRect
        GlobalStates.regionSelectorOpen = true
    }

    function search() {
        root.action = actionSearch
        root.selectionMode = modeRect
        GlobalStates.regionSelectorOpen = true
    }

    function ocr() {
        root.action = actionOCR
        root.selectionMode = modeRect
        GlobalStates.regionSelectorOpen = true
    }

    function record() {
        root.action = actionRecord
        root.selectionMode = modeRect
        GlobalStates.regionSelectorOpen = true
    }

    function recordWithSound() {
        root.action = actionRecordWithSound
        root.selectionMode = modeRect
        GlobalStates.regionSelectorOpen = true
    }

    function recordFullscreenWithSound() {
        root.action = actionRecordFullscreenWithSound
        root.selectionMode = modeRect
        // Fullscreen doesn't strictly need a selection UI but we use it to handle state and script call
        // Actually, if it's fullscreen, maybe it should just START?
        // But record.sh handles it.
        // Actually, RegionSelection.qml has logic for preparation.
        GlobalStates.regionSelectorOpen = true
    }

    IpcHandler {
        target: "region"

        function screenshot() { root.screenshot() }
        function search() { root.search() }
        function ocr() { root.ocr() }
        function record() { root.record() }
        function recordWithSound() { root.recordWithSound() }
        function recordFullscreenWithSound() { root.recordFullscreenWithSound() }
    }

}

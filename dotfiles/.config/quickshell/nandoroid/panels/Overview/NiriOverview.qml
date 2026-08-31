pragma ComponentBehavior: Bound

import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland

FocusScope {
    id: root
    required property var screen
    property var panelWindow

    property var monitorData: HyprlandData.monitors.find(m => m.name === Hyprland.focusedMonitor?.name)

    property int activeWorkspaceId: {
        var id = Hyprland.focusedWorkspace?.id ?? monitorData?.activeWorkspace?.id ?? 1
        return Math.max(1, Math.min(100, id))
    }

    readonly property int maxWorkspaces: 20 // Fixed to avoid blinking when switching workspaces
    readonly property real wsHeight: (screen?.height ?? 1080) * (Config.options.overview.niriScale ?? Config.options.overview.scale ?? 0.5)
    readonly property real wsPadding: 28
    readonly property real scale: Config.options.overview.niriScale ?? Config.options.overview.scale ?? 0.5

    readonly property real monitorW: screen?.width ?? 1920
    readonly property real monitorH: screen?.height ?? 1080
    readonly property real screenCenterX: monitorW / 2

    property var windows: HyprlandData.windowList

    property int dragFromWs: -1
    property int dragFromPos: -1
    property int dragToWs: -1
    property bool isDragging: false
    property real ghostX: 0
    property real ghostY: 0
    property string dragWinIndex: ""
    property string localFocusedAddr: "" // for left/right nav: immediate center without waiting for HyprlandData
    property bool firstOpen: true

    implicitWidth: monitorW
    implicitHeight: monitorH

    // Expose for OverviewView
    property bool isManualScrolling: false

    Timer {
        id: niriFocusTimer
        interval: 100
        repeat: false
        onTriggered: {
            root.forceActiveFocus()
        }
    }

    // Keyboard: Up/Down = workspace, Left/Right = window in active workspace
    focus: true
    activeFocusOnTab: true
    Keys.onPressed: event => {
        
        if (event.key === Qt.Key_Escape) {
            GlobalStates.overviewOpen = false
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            Hyprland.dispatch(HyprlandCompat.dspWorkspace("r-1"))
            HyprlandData.updateAll()
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            Hyprland.dispatch(HyprlandCompat.dspWorkspace("r+1"))
            HyprlandData.updateAll()
            event.accepted = true
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
            const wins = getWindowsSortedByX(root.activeWorkspaceId)
            if (wins.length === 0) { event.accepted = true; return }
            const focusedAddrRaw = root.localFocusedAddr !== "" ? root.localFocusedAddr : (HyprlandData.activeWindow?.address ?? "")
            const focusedAddr = focusedAddrRaw ? focusedAddrRaw.toLowerCase() : ""
            let idx = wins.findIndex(w => (w.address || "").toLowerCase() === focusedAddr)
            if (idx === -1) {
                let minId = Infinity, minIdx = 0
                for (let i=0;i<wins.length;i++) if (wins[i].focusHistoryID < minId) { minId=wins[i].focusHistoryID; minIdx=i }
                idx = minIdx
            }
            const dir = (event.key === Qt.Key_Right) ? 1 : -1
            const nextIdx = (idx + dir + wins.length) % wins.length
            const nextAddr = wins[nextIdx]?.address
            if (nextAddr) {
                root.localFocusedAddr = nextAddr
                // Lightweight: preview only
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            // Select window in the currently centered workspace (activeWs), not Hyprland's old activeWindow
            const wins = getWindowsSortedByX(root.activeWorkspaceId)
            let targetAddr = root.localFocusedAddr
            if (!targetAddr) {
                if (wins.length > 0) {
                    let minId = Infinity, minAddr = wins[0].address
                    for (let w of wins) if (w.focusHistoryID < minId) { minId = w.focusHistoryID; minAddr = w.address }
                    targetAddr = minAddr
                } else {
                    targetAddr = ""
                }
            }
            if (targetAddr) {
                const targetWin = HyprlandData.windowList.find(w => (w.address||"").toLowerCase() === targetAddr.toLowerCase())
                const targetWs = targetWin?.workspace?.id ?? root.activeWorkspaceId
                GlobalStates.overviewOpen = false
                Qt.callLater(() => {
                    const wsCmd = HyprlandCompat.dspWorkspace(String(targetWs))
                    const winCmd = HyprlandCompat.dspFocusWindow(`address:${targetAddr}`)
                    Hyprland.dispatch(wsCmd)
                    Hyprland.dispatch(winCmd)
                    Quickshell.execDetached(["hyprctl", "dispatch", "workspace", String(targetWs)])
                    Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", `address:${targetAddr}`])
                })
            } else {
                // Empty workspace — just switch to it
                const targetWs = root.activeWorkspaceId
                GlobalStates.overviewOpen = false
                Qt.callLater(() => {
                    const wsCmd = HyprlandCompat.dspWorkspace(String(targetWs))
                    Hyprland.dispatch(wsCmd)
                    Quickshell.execDetached(["hyprctl", "dispatch", "workspace", String(targetWs)])
                })
            }
            event.accepted = true
        }
    }
    Connections {
        target: GlobalStates
        function onOverviewOpenChanged() {
            if (GlobalStates.overviewOpen) {
                root.firstOpen = true
                niriFocusTimer.restart()
                firstOpenTimer.restart()
                scrollTimer.restart()
            } else {
                root.firstOpen = true
            }
        }
    }
    onVisibleChanged: if (visible && GlobalStates.overviewOpen) { root.firstOpen = true; niriFocusTimer.restart(); firstOpenTimer.restart() }
    Component.onCompleted: if (GlobalStates.overviewOpen) { root.firstOpen = true; niriFocusTimer.restart(); firstOpenTimer.restart() }

    onActiveWorkspaceIdChanged: { root.localFocusedAddr = ""; scrollTimer.restart() }

    Timer {
        id: scrollTimer
        interval: 50
        repeat: false
        onTriggered: {
            // Center active workspace
            var targetY = (root.activeWorkspaceId - 1) * (root.wsHeight + root.wsPadding)
            var finalY = Math.min(targetY, Math.max(0, flickableItem.contentHeight - flickableItem.height))
            if (root.firstOpen) {
                flickableItem.contentY = finalY
            } else {
                scrollAnim.to = finalY
                scrollAnim.restart()
            }
        }
    }
    Timer {
        id: firstOpenTimer
        interval: 300
        repeat: false
        onTriggered: root.firstOpen = false
    }

    Timer {
        id: autoScrollTimer
        interval: 16
        repeat: true
        running: root.isDragging
        onTriggered: {
            const edge = root.height * 0.2
            const speed = 18
            if (root.ghostY < edge) {
                const stepUp = speed * (1 - root.ghostY / edge)
                flickableItem.contentY = Math.max(0, flickableItem.contentY - stepUp)
            } else if (root.ghostY > root.height - edge) {
                const stepDown = speed * ((root.ghostY - (root.height - edge)) / edge)
                flickableItem.contentY = Math.min(
                    flickableItem.contentHeight - flickableItem.height,
                    flickableItem.contentY + stepDown
                )
            }
        }
    }


    function getWindowsSortedByX(wsId) {
        if (!windows) return []
        var wins = windows.filter(w => w.workspace?.id === wsId)
        wins.sort((a, b) => a.at[0] - b.at[0])
        return wins
    }

    function getMonitorDataForWindow(win) {
        if (!win) return null
        return HyprlandData.monitors.find(m => m.id === win.monitor) ?? null
    }

    function getToplevelForWindow(win) {
        if (!win) return null
        return ToplevelManager.toplevels.values.find(
            t => `0x${t.HyprlandToplevel?.address}` === win.address
        ) ?? null
    }

    function getWindowsBBox(wins) {
        if (!wins || wins.length === 0)
            return { x: 0, y: 0, w: root.monitorW, h: root.monitorH }

        var refMon = HyprlandData.monitors.find(m => m.id === wins[0].monitor)
        var refW = refMon ? refMon.width / (refMon.scale ?? 1.0) : root.monitorW
        var refH = refMon ? refMon.height / (refMon.scale ?? 1.0) : root.monitorH

        var minX = Infinity, minY = Infinity
        var maxX = -Infinity, maxY = -Infinity

        for (var i = 0; i < wins.length; i++) {
            var w = wins[i]
            var mon = HyprlandData.monitors.find(m => m.id === w.monitor)
            var monD = getMonitorDataForWindow(w)
            var wx = w.at[0] - (mon?.x ?? 0) - (monD?.reserved[2] ?? 0)
            var wy = w.at[1] - (mon?.y ?? 0) - (monD?.reserved[0] ?? 0)
            minX = Math.min(minX, wx)
            minY = Math.min(minY, wy)
            maxX = Math.max(maxX, wx + w.size[0])
            maxY = Math.max(maxY, wy + w.size[1])
        }

        return {
            x: Math.min(minX, 0),
            y: Math.min(minY, 0),
            w: Math.max(maxX, refW),
            h: Math.max(maxY, refH)
        }
    }

    function getFitScale(wins) {
        if (!wins || wins.length === 0) return 1.0
        var bbox = getWindowsBBox(wins)
        var availW = bbox.w * root.scale * 0.90
        var availH = root.wsHeight * 0.88
        var contentW = bbox.w * root.scale
        var contentH = bbox.h * root.scale
        return Math.min(availW / contentW, availH / contentH, 1.0)
    }

    function getWinXInRow(win, monData, fitScale, bbox) {
        if (!win || !monData) return 0
        var mon = HyprlandData.monitors.find(m => m.id === win.monitor)
        var rawX = win.at[0] - (mon?.x ?? 0) - (monData.reserved[2] ?? 0)
        var relX = (rawX - bbox.x) * root.scale * fitScale
        var totalW = bbox.w * root.scale * fitScale
        var centerX = root.implicitWidth / 2
        return centerX - totalW / 2 + relX
    }

    function getWinYInRow(win, monData, fitScale, bbox) {
        if (!win || !monData) return 0
        var mon = HyprlandData.monitors.find(m => m.id === win.monitor)
        var rawY = win.at[1] - (mon?.y ?? 0) - (monData.reserved[0] ?? 0)
        var relY = (rawY - bbox.y) * root.scale * fitScale
        var totalH = bbox.h * root.scale * fitScale
        return (root.wsHeight - totalH) / 2 + relY
    }

    function getWinW(win, fitScale) {
        if (!win) return 80 * root.scale * fitScale
        return win.size[0] * root.scale * fitScale
    }

    function getWinH(win, fitScale) {
        if (!win) return 60 * root.scale * fitScale
        return win.size[1] * root.scale * fitScale
    }

    function findTargetPos(ghostLocalX, ghostLocalY, items, fitScale, bbox) {
        var minDist = Infinity
        var bestPos = items.length
        for (var i = 0; i < items.length; i++) {
            var monD = getMonitorDataForWindow(items[i])
            var cx = getWinXInRow(items[i], monD, fitScale, bbox) + getWinW(items[i], fitScale) / 2
            var cy = getWinYInRow(items[i], monD, fitScale, bbox) + getWinH(items[i], fitScale) / 2
            var dx = ghostLocalX - cx
            var dy = ghostLocalY - cy
            var dist = Math.sqrt(dx*dx + dy*dy)
            if (dist < minDist) {
                minDist = dist
                bestPos = i
            }
        }
        return bestPos
    }

    function focusWindowByAddr(addr) {
        if (!addr) return
        const cmd = HyprlandCompat.dspFocusWindow(`address:${addr}`)
        Hyprland.dispatch(cmd)
        Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", `address:${addr}`])
        Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", addr.replace("0x","")])
        HyprlandData.updateActiveWindow()
    }

    function doMove(fromWs, fromPos, toWs, toPos, fromWsWindows, toWsWindows) {
        if (fromWs === -1 || fromPos === -1 || dragWinIndex === "") return
        var addr = dragWinIndex
        if (fromWs === toWs) {
            if (toPos !== fromPos && toPos < toWsWindows.length) {
                var targetAddr = toWsWindows[toPos].address
                Hyprland.dispatch(`hl.dsp.focus({ window = "address:${targetAddr}" })`)
                Hyprland.dispatch(`hl.dsp.window.swap({ window = "address:${addr}" })`)
            }
        } else {
            Hyprland.dispatch(`hl.dsp.window.move({ workspace = ${toWs}, follow = false, window = "address:${addr}" })`)
        }
    }

    NumberAnimation {
        id: scrollAnim
        target: flickableItem
        property: "contentY"
        duration: Appearance.animation.elementMoveExit.duration
        easing.type: Appearance.animation.elementMove.type
    }

    Item {
        id: dragGhost
        parent: root
        visible: root.isDragging
        width: 160
        height: 100
        x: root.ghostX - width / 2
        y: root.ghostY - height / 2
        z: 9999

        Drag.active: root.isDragging
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2
        Drag.keys: ["winDrag"]

        Rectangle {
            anchors.fill: parent
            color: Functions.ColorUtils.transparentize(Appearance.colors.colSecondary, 0.5)
            radius: Appearance.rounding.normal
            border.width: 2
            border.color: Appearance.colors.colSecondary
        }
    }

    // Solid background + blurred wallpaper backdrop
    Rectangle {
        anchors.fill: parent
        color: Appearance.m3colors.m3surface
        z: -3
    }
    Item {
        anchors.fill: parent
        z: -2
        Image {
            id: niriBackdropImage
            anchors.fill: parent
            source: Config.options.appearance.background.wallpaperPath ?? ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            visible: false
        }
        GaussianBlur {
            anchors.fill: niriBackdropImage
            source: niriBackdropImage
            radius: 64 * Appearance.effectiveScale
            samples: 32
            cached: true
        }
        Rectangle {
            anchors.fill: parent
            color: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3scrim, 0.15)
        }
    }

    Flickable {
        id: flickableItem
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        flickableDirection: Flickable.VerticalFlick
        interactive: !root.isDragging
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

        // Backdrop: close on empty area
        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: GlobalStates.closeAllPanels()
        }

        Column {
            id: column
            width: parent.width
            spacing: root.wsPadding
            // Allow workspace 1 and 20 to center
            topPadding: Math.max(root.wsPadding, flickableItem.height/2 - root.wsHeight/2)
            bottomPadding: Math.max(root.wsPadding, flickableItem.height/2 - root.wsHeight/2)

            Repeater {
                model: root.maxWorkspaces
                delegate: Item {
                    id: rowItem
                    required property int index
                    property int wsId: index + 1
                    property bool isActiveWs: wsId === root.activeWorkspaceId
                    property bool isDragTarget: wsId === root.dragToWs
                    property var wsWindows: root.getWindowsSortedByX(wsId)
                    property var wsBBox: root.getWindowsBBox(wsWindows)
                    property real wsFitScale: root.getFitScale(wsWindows)

                    property int activeWinIdx: {
                        if (wsWindows.length === 0) return 0
                        var minId = Infinity, minIdx = 0
                        for (var i = 0; i < wsWindows.length; i++) {
                            if (wsWindows[i].focusHistoryID < minId) {
                                minId = wsWindows[i].focusHistoryID
                                minIdx = i
                            }
                        }
                        return minIdx
                    }
                    // Live preview: use localFocusedAddr for immediate centering
                    property var activeWin: {
                        if (wsWindows.length === 0) return null
                        if (isActiveWs) {
                            const addr = root.localFocusedAddr !== "" ? root.localFocusedAddr : HyprlandData.activeWindow?.address
                            if (addr) {
                                const found = wsWindows.find(w => w.address === addr)
                                if (found) return found
                            }
                        }
                        return wsWindows[activeWinIdx]
                    }
                    property var activeMonData: root.getMonitorDataForWindow(activeWin)
                    // Center active window (for scrolling layout)
                    readonly property real activeCenterShift: {
                        if (!activeWin || wsWindows.length === 0) return 0
                        // For dwindle/master, don't center active window
                        if (GlobalStates.hyprlandLayout !== "scrolling") return 0
                        var monAx = HyprlandData.monitors.find(m => m.id === activeWin.monitor)?.x ?? 0
                        var monDataA = getMonitorDataForWindow(activeWin)
                        var rawAx = activeWin.at[0] - monAx - (monDataA?.reserved[2] ?? 0)
                        var relAx = (rawAx - wsBBox.x) * root.scale * wsFitScale
                        var totalW = wsBBox.w * root.scale * wsFitScale
                        var activeW = getWinW(activeWin, wsFitScale)
                        return totalW/2 - relAx - activeW/2
                    }

                    width: parent.width
                    height: root.wsHeight

                    DropArea {
                        anchors.fill: parent
                        keys: ["winDrag"]
                        onEntered: drag => { root.dragToWs = rowItem.wsId }
                        onExited: {
                            if (root.dragToWs === rowItem.wsId)
                                root.dragToWs = -1
                        }
                        onDropped: drop => {
                            var fromWs = root.dragFromWs
                            var fromPos = root.dragFromPos
                            var toWs = rowItem.wsId
                            var ghostLocal = mapFromItem(root, root.ghostX, root.ghostY)
                            var toPos = root.findTargetPos(
                                ghostLocal.x, ghostLocal.y,
                                rowItem.wsWindows,
                                rowItem.wsFitScale,
                                rowItem.wsBBox
                            )
                            root.doMove(fromWs, fromPos, toWs, toPos,
                                        root.getWindowsSortedByX(fromWs),
                                        rowItem.wsWindows)
                            root.dragFromWs = -1
                            root.dragFromPos = -1
                            root.dragToWs = -1
                            root.dragWinIndex = ""
                        }
                    }

                    // Wallpaper
                    Rectangle {
                        id: wsCard
                        anchors.centerIn: parent
                        width: parent.width * (Config.options.overview.niriScale ?? Config.options.overview.scale ?? 0.5)
                        height: parent.height
                        radius: Appearance.rounding.large
                        color: "red"

                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on border.color { ColorAnimation { duration: 200 } }

                        Image {
                            id: ovBgSource
                            anchors.fill: parent
                            source: (Config.options.appearance && Config.options.appearance.background ? Config.options.appearance.background.wallpaperPath : Config.options.background.wallpaperPath) ?? ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                        }

                        StyledText {
                            visible: rowItem.wsWindows.length === 0
                            anchors.centerIn: parent
                            text: rowItem.wsId
                            font {
                                pixelSize: root.wsHeight * 0.38
                                weight: Font.DemiBold
                                family: Appearance.font.family.expressive
                            }
                            color: Functions.ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.4)
                            z: 2
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !root.isDragging && rowItem.wsWindows.length === 0
                            onClicked: {
                                GlobalStates.overviewOpen = false
                                Hyprland.dispatch(`hl.dsp.focus({ workspace = ${rowItem.wsId} })`)
                            }
                        }
                    }

                    // Clip container: clip for dwindle/master, allow overflow for scrolling (not clipped)
                    Item {
                        id: windowClip
                        anchors.centerIn: parent
                        width: wsCard.width
                        height: wsCard.height
                        clip: GlobalStates.hyprlandLayout !== "scrolling"
                        z: 1

                        // Active window border inside clip
                        Rectangle {
                            visible: rowItem.isActiveWs && rowItem.activeWin !== null
                            x: root.getWinXInRow(rowItem.activeWin, rowItem.activeMonData, rowItem.wsFitScale, rowItem.wsBBox) + rowItem.activeCenterShift - (rowItem.width/2 - wsCard.width/2)
                            y: root.getWinYInRow(rowItem.activeWin, rowItem.activeMonData, rowItem.wsFitScale, rowItem.wsBBox)
                            width: root.getWinW(rowItem.activeWin, rowItem.wsFitScale)
                            height: root.getWinH(rowItem.activeWin, rowItem.wsFitScale)
                            radius: Appearance.rounding.normal
                            color: "transparent"
                            border.width: 2
                            border.color: Functions.ColorUtils.transparentize(Appearance.colors.colPrimary, 0.5) 
                            z: 10
                            Behavior on x { enabled: !root.firstOpen; NumberAnimation { duration: Appearance.animation.elementMoveFast.duration } }
                            Behavior on y { enabled: !root.firstOpen; NumberAnimation { duration: Appearance.animation.elementMoveFast.duration } }
                            Behavior on width { enabled: !root.firstOpen; NumberAnimation { duration: Appearance.animation.elementMoveFast.duration } }
                            Behavior on height { enabled: !root.firstOpen; NumberAnimation { duration: Appearance.animation.elementMoveFast.duration } }
                        }

                        Repeater {
                        model: rowItem.wsWindows.length
                        delegate: Item {
                            id: winContainer
                            required property int index

                            property var win: rowItem.wsWindows[index]
                            property var winMonData: root.getMonitorDataForWindow(win)
                            property bool isActiveWin: index === rowItem.activeWinIdx && rowItem.isActiveWs
                            property bool isBeingDragged: root.isDragging &&
                                                            root.dragFromWs === rowItem.wsId &&
                                                            root.dragFromPos === index

                            x: root.getWinXInRow(win, winMonData, rowItem.wsFitScale, rowItem.wsBBox) + rowItem.activeCenterShift - (rowItem.width/2 - wsCard.width/2)
                            y: root.getWinYInRow(win, winMonData, rowItem.wsFitScale, rowItem.wsBBox)
                            width: root.getWinW(win, rowItem.wsFitScale)
                            height: root.getWinH(win, rowItem.wsFitScale)
                            z: 1

                            opacity: isBeingDragged ? 0.15 : 1.0
                            Behavior on opacity { enabled: isBeingDragged; NumberAnimation { duration: 150 } }
                            Behavior on x {
                                enabled: !isBeingDragged && !root.firstOpen
                                NumberAnimation { duration: Appearance.animation.elementMoveFast.duration }
                            }
                            Behavior on y {
                                enabled: !isBeingDragged && !root.firstOpen
                                NumberAnimation { duration: Appearance.animation.elementMoveFast.duration }
                            }
                            Behavior on width {
                                enabled: !isBeingDragged && !root.firstOpen
                                NumberAnimation { duration: Appearance.animation.elementMoveFast.duration }
                            }
                            Behavior on height {
                                enabled: !isBeingDragged && !root.firstOpen
                                NumberAnimation { duration: Appearance.animation.elementMoveFast.duration }
                            }

                            NiriOverviewWindow {
                                id: ovWin
                                anchors.fill: parent

                                toplevel: root.getToplevelForWindow(winContainer.win)
                                windowData: winContainer.win
                                monitorData: winContainer.winMonData
                                widgetMonitor: winContainer.winMonData
                                scale: root.scale * rowItem.wsFitScale
                                xOffset: 0
                                yOffset: 0
                                // Apps
                                opacity: winContainer.isActiveWin ? 1.0 : 0.80

                                topLeftRadius: Appearance.rounding.normal
                                topRightRadius: Appearance.rounding.normal
                                bottomLeftRadius: Appearance.rounding.normal
                                bottomRightRadius: Appearance.rounding.normal
                            }

                            MouseArea {
                                anchors.fill: parent
                                z: 10
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                                property real pressX: 0
                                property real pressY: 0
                                property bool dragStarted: false
                                property real dragStartTime: 0

                                onEntered: ovWin.hovered = true
                                onExited: { if (!dragStarted) ovWin.hovered = false }

                                onPressed: mouse => {
                                    pressX = mouse.x
                                    pressY = mouse.y
                                    dragStarted = false
                                    dragStartTime = Date.now()
                                    ovWin.pressed = true

                                    root.dragFromWs = rowItem.wsId
                                    root.dragFromPos = winContainer.index
                                    root.dragWinIndex = winContainer.win?.address ?? ""

                                    var gp = mapToItem(root, mouse.x, mouse.y)
                                    root.ghostX = gp.x
                                    root.ghostY = gp.y
                                }

                                onPositionChanged: mouse => {
                                    if (!pressed) return
                                    var gp = mapToItem(root, mouse.x, mouse.y)
                                    root.ghostX = gp.x
                                    root.ghostY = gp.y

                                    var dx = Math.abs(mouse.x - pressX)
                                    var dy = Math.abs(mouse.y - pressY)
                                    var elapsed = Date.now() - dragStartTime

                                    if (!dragStarted && (dx > 12 || dy > 12 ||
                                                        (elapsed > 200 && (dx > 6 || dy > 6)))) {
                                        dragStarted = true
                                        root.isDragging = true
                                    }
                                }

                                onReleased: mouse => {
                                    ovWin.pressed = false
                                    ovWin.hovered = containsMouse

                                    if (root.isDragging) {
                                        dragGhost.Drag.drop()
                                    }

                                    root.isDragging = false
                                    dragStarted = false
                                    root.dragFromWs = -1
                                    root.dragFromPos = -1
                                    root.dragToWs = -1
                                    root.dragWinIndex = ""
                                }

                                onClicked: event => {
                                    if (dragStarted) return
                                    if (!winContainer.win) return
                                    if (event.button === Qt.LeftButton) {
                                        GlobalStates.overviewOpen = false
                                        Hyprland.dispatch(`hl.dsp.focus({ window = "address:${winContainer.win.address}" })`)
                                        event.accepted = true
                                    } else if (event.button === Qt.MiddleButton) {
                                        Hyprland.dispatch(`hl.dsp.window.close({ window = "address:${winContainer.win.address}" })`)
                                        event.accepted = true
                                    }
                                }

                                StyledToolTip {
                                    extraVisibleCondition: false
                                    alternativeVisibleCondition: parent.containsMouse && !root.isDragging
                                    text: `${winContainer.win?.title ?? ""}\n[${winContainer.win?.class ?? ""}]`
                                }
                            }
                        }
                    }
                    }
                }
            }
        }
    }

    // Expose for OverviewView
    property alias flickable: flickableItem
    readonly property bool needsScrollbar: flickableItem.contentHeight > flickableItem.height
}
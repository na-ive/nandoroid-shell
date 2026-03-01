pragma Singleton
pragma ComponentBehavior: Bound
import "../../core"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

/**
 * Shared lock context — auth state synced across all monitor surfaces.
 * Ported from the ii example's common/panels/lock/LockContext.qml.
 */
Scope {
    id: root

    enum ActionEnum { Unlock, Poweroff, Reboot, Suspend }

    signal shouldReFocus()
    signal unlocked(var targetAction)
    signal failed()

    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false
    property bool fingerprintsConfigured: false
    property var targetAction: LockContext.ActionEnum.Unlock
    property bool alsoInhibitIdle: false

    function resetTargetAction() {
        root.targetAction = LockContext.ActionEnum.Unlock
    }

    function clearText() {
        root.currentText = ""
    }

    function resetClearTimer() {
        passwordClearTimer.restart()
    }

    function reset() {
        root.resetTargetAction()
        root.clearText()
        root.unlockInProgress = false
        stopFingerPam()
    }

    // Clear password after 10s of inactivity
    Timer {
        id: passwordClearTimer
        interval: 10000
        onTriggered: root.reset()
    }

    onCurrentTextChanged: {
        if (currentText.length > 0) {
            showFailure = false
            GlobalStates.screenUnlockFailed = false
        }
        GlobalStates.screenLockContainsCharacters = currentText.length > 0
        passwordClearTimer.restart()
    }

    function tryUnlock(alsoInhibitIdle = false) {
        root.alsoInhibitIdle = alsoInhibitIdle
        root.unlockInProgress = true
        pam.start()
    }

    function tryFingerUnlock() {
        if (root.fingerprintsConfigured) {
            fingerPam.start()
        }
    }

    function stopFingerPam() {
        if (fingerPam.active) {
            fingerPam.abort()
        }
    }

    // Check if fingerprints are enrolled
    Process {
        id: fingerprintCheckProc
        running: true
        command: ["bash", "-c", "fprintd-list $(whoami) 2>/dev/null"]
        stdout: StdioCollector {
            id: fingerprintOutput
            onStreamFinished: {
                root.fingerprintsConfigured = fingerprintOutput.text.includes("Fingerprints for user")
            }
        }
        onExited: (code, status) => {
            if (code !== 0) root.fingerprintsConfigured = false
        }
    }

    // Password PAM auth
    PamContext {
        id: pam
        onPamMessage: {
            if (this.responseRequired) this.respond(root.currentText)
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                root.unlocked(root.targetAction)
                stopFingerPam()
            } else {
                root.clearText()
                root.unlockInProgress = false
                GlobalStates.screenUnlockFailed = true
                root.showFailure = true
            }
        }
    }

    // Fingerprint PAM auth
    PamContext {
        id: fingerPam
        configDirectory: "pam"
        config: "fprintd.conf"
        onCompleted: result => {
            if (result === PamResult.Success) {
                root.unlocked(root.targetAction)
                stopFingerPam()
            } else if (result === PamResult.Error) {
                tryFingerUnlock()  // retry on timeout/error
            }
        }
    }
}

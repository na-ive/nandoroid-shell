pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Polkit
import "../core"

Singleton {
    id: root
    property alias agent: polkitAgent
    property alias active: polkitAgent.isActive
    property alias flow: polkitAgent.flow
    property bool interactionAvailable: false
    property bool failed: false

    readonly property string cleanMessage: {
        if (!root.flow) return "";
        let msg = root.flow.message;
        return msg.endsWith(".") ? msg.slice(0, -1) : msg;
    }

    readonly property string cleanPrompt: {
        if (!root.flow) return qsTr("Password");
        let prompt = root.flow.inputPrompt.trim();
        if (prompt.endsWith(":")) prompt = prompt.slice(0, -1);
        
        const usePasswordChars = !root.flow.responseVisible;
        return prompt || (usePasswordChars ? qsTr("Password") : qsTr("Input"));
    }

    function cancel() {
        if (root.flow) {
            root.flow.cancelAuthenticationRequest();
        }
    }

    function submit(response) {
        if (root.flow) {
            root.flow.submit(response);
            root.interactionAvailable = false;
        }
    }

    Connections {
        target: root.flow
        function onAuthenticationFailed() {
            root.interactionAvailable = true;
            root.failed = true;
        }
    }

    PolkitAgent {
        id: polkitAgent
        onAuthenticationRequestStarted: {
            root.interactionAvailable = true;
            root.failed = false;
        }
    }
}

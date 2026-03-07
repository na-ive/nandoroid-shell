pragma Singleton

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property string microphoneApp: {
        if (!Pipewire.ready || !Pipewire.nodes?.values) return "";

        for (let i = 0; i < Pipewire.nodes.values.length; i++) {
            const node = Pipewire.nodes.values[i];
            if (!node || !node.ready) continue;

            if ((node.type & PwNodeType.AudioInStream) === PwNodeType.AudioInStream) {
                if (!looksLikeSystemVirtualMic(node)) {
                    if (node.audio && node.audio.muted) continue;
                    return node.properties["application.name"] || node.name || "Unknown App";
                }
            }
        }
        return "";
    }

    readonly property string screensharingApp: {
        if (!Pipewire.ready) return "";

        // Look for active screen share links
        const activeLink = Pipewire.linkGroups.values.find(group => {
            const src = group.source;
            if (!src) return false;
            return (src.type & PwNodeType.VideoSource) === PwNodeType.VideoSource && looksLikeScreencast(src);
        });

        if (activeLink && activeLink.target && activeLink.target.properties) {
            return activeLink.target.properties["application.name"] || activeLink.target.name || "Unknown App";
        }
        return "";
    }

    readonly property bool microphoneActive: microphoneApp !== ""
    readonly property bool cameraActive: false
    readonly property bool screensharingActive: screensharingApp !== ""

    readonly property bool anyActive: microphoneActive || cameraActive || screensharingActive

    // Track objects to keep them reactive
    PwObjectTracker {
        id: nodeTracker
        objects: Pipewire.nodes ? Pipewire.nodes.values : []
    }

    PwObjectTracker {
        id: linkTracker
        objects: Pipewire.linkGroups ? Pipewire.linkGroups.values : []
    }

    function looksLikeSystemVirtualMic(node) {
        if (!node) return false;
        const name = (node.name || "").toLowerCase();
        const mediaName = (node.properties && node.properties["media.name"] || "").toLowerCase();
        const appName = (node.properties && node.properties["application.name"] || "").toLowerCase();
        const combined = name + " " + mediaName + " " + appName;
        // Basic system filter
        return /cava|monitor|system/.test(combined);
    }

    function looksLikeScreencast(node) {
        if (!node) return false;
        const appName = (node.properties && node.properties["application.name"] || "").toLowerCase();
        const nodeName = (node.name || "").toLowerCase();
        const mediaName = (node.properties && node.properties["media.name"] || "").toLowerCase();
        const combined = appName + " " + nodeName + " " + mediaName;
        return /portal|xdpw|screencast|screen|sharing|display|obs/.test(combined);
    }
}

import QtQuick
import ".."

QtObject {
    required property var lastIpcObject
    readonly property string ssid: lastIpcObject.ssid
    readonly property string bssid: lastIpcObject.bssid
    readonly property int strength: lastIpcObject.strength
    readonly property int frequency: lastIpcObject.frequency
    readonly property bool active: lastIpcObject.active
    readonly property string security: lastIpcObject.security
    readonly property bool isSecure: security.length > 0

    property bool askingPassword: false

    readonly property bool isSaved: Network.savedConnections.includes(ssid)
    readonly property int priority: Network.savedPriorities[ssid] || 0
}

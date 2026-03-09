import QtQuick
import "../services"

/**
 * Lightweight search handler for deep-linking.
 * Supports aliases for better search coverage.
 */
Item {
    id: root
    
    // The canonical string this handler responds to
    property string searchString: ""
    
    // Additional keywords that should trigger this handler
    property var aliases: []
    
    // The Flickable that should be scrolled (optional, finds parent by default)
    property var flickable: null
    
    // The item to highlight (defaults to parent)
    property var targetItem: parent

    function findFlickable(item) {
        if (!item) return null;
        if (item.hasOwnProperty("contentY") && item.hasOwnProperty("contentHeight")) return item;
        return findFlickable(item.parent);
    }

    Connections {
        target: SearchRegistry
        function onCurrentSearchChanged() {
            const query = SearchRegistry.currentSearch;
            if (query === "" || root.searchString === "") return;
            
            // Match canonical name OR any alias
            const isCanonicalMatch = (query.toLowerCase() === root.searchString.toLowerCase());
            let isAliasMatch = false;
            if (root.aliases) {
                for (let i = 0; i < root.aliases.length; i++) {
                    if (query.toLowerCase() === root.aliases[i].toLowerCase()) {
                        isAliasMatch = true;
                        break;
                    }
                }
            }

            if (isCanonicalMatch || isAliasMatch) {
                // console.log("[SearchHandler] Triggered for:", root.searchString);
                
                Qt.callLater(() => {
                    const targetFlick = root.flickable || findFlickable(root.parent);
                    if (!targetFlick) return;

                    const pos = root.targetItem.mapToItem(targetFlick.contentItem, 0, 0);
                    const targetY = Math.max(0, Math.min(pos.y - 40, targetFlick.contentHeight - targetFlick.height));
                    targetFlick.contentY = targetY;
                    
                    highlightAnim.restart();
                });
            }
        }
    }

    SequentialAnimation {
        id: highlightAnim
        NumberAnimation { target: root.targetItem; property: "opacity"; from: 1; to: 0.3; duration: 200 }
        NumberAnimation { target: root.targetItem; property: "opacity"; from: 0.3; to: 1; duration: 400 }
    }
}

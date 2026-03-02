import ".."
import "../../../services"

OsdToggleIndicator {
    id: osdValues

    property string layout: HyprlandData.activeWorkspace?.tiledLayout || "dwindle"

    name: "Window Layout"
    statusText: {
        if (layout === "dwindle") return "Dwindle";
        if (layout === "master") return "Master";
        if (layout === "scrolling") return "Scrolling";
        return layout.charAt(0).toUpperCase() + layout.slice(1);
    }
    icon: {
        if (layout === "dwindle") return "grid_view";
        if (layout === "master") return "view_quilt";
        if (layout === "scrolling") return "view_carousel";
        return "view_compact";
    }
}

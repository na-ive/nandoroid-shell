import QtQuick
import "../../core"
import "../../services"
import "../../core"
import "../../widgets"
import "../../core"

ToggleButton {
    buttonIcon: "grid_view"
    tooltipText: "Open Window Overview"

    onToggle: function () {
        if (GlobalStates.overviewOpen) {
            GlobalStates.closeAllPanels();
        } else {
            Visibilities.setActiveModule("overview");
        }
    }
}

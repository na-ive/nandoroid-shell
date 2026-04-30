import "../core"
import QtQuick
import Quickshell.Services.Notifications

RippleButton {
    id: button
    property string buttonText
    property string urgency
    property color colText: (urgency == NotificationUrgency.Critical) ? Appearance.m3colors.m3onSurfaceVariant : Appearance.m3colors.m3onSurface

    implicitHeight: 34 * Appearance.effectiveScale
    leftPadding: 15 * Appearance.effectiveScale
    rightPadding: 15 * Appearance.effectiveScale
    buttonRadius: Appearance.rounding.small
    colBackground: (urgency == NotificationUrgency.Critical) ? Appearance.m3colors.m3secondaryContainer : Appearance.m3colors.m3surfaceContainerHighest
    colBackgroundHover: (urgency == NotificationUrgency.Critical) ? Appearance.m3colors.m3secondaryFixedDim : Appearance.m3colors.m3surfaceBright
    colRipple: (urgency == NotificationUrgency.Critical) ? Appearance.m3colors.m3onSecondaryContainer : Appearance.m3colors.m3onSurface // Adapted

    contentItem: StyledText {
        horizontalAlignment: Text.AlignHCenter
        text: buttonText
        color: button.colText
    }
}

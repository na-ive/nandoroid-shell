import "../core"
import QtQuick
import Quickshell.Services.Notifications

RippleButton {
    id: button
    property string buttonText
    property string urgency

    implicitHeight: 34
    leftPadding: 15
    rightPadding: 15
    buttonRadius: Appearance.rounding.small
    colBackground: (urgency == NotificationUrgency.Critical) ? Appearance.m3colors.m3secondaryContainer : Appearance.m3colors.m3surfaceContainerHighest
    colBackgroundHover: (urgency == NotificationUrgency.Critical) ? Appearance.m3colors.m3secondaryFixedDim : Appearance.m3colors.m3surfaceBright
    colRipple: (urgency == NotificationUrgency.Critical) ? Appearance.m3colors.m3onSecondaryContainer : Appearance.m3colors.m3onSurface // Adapted

    contentItem: StyledText {
        horizontalAlignment: Text.AlignHCenter
        text: buttonText
        color: (urgency == NotificationUrgency.Critical) ? Appearance.m3colors.m3onSurfaceVariant : Appearance.m3colors.m3onSurface
    }
}

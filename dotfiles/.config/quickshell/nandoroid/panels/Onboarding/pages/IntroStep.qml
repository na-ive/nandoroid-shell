import "../../../core"
import "../../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 32 * Appearance.effectiveScale

        Image {
            Layout.alignment: Qt.AlignHCenter
            source: "../../../assets/icons/NAnDoroid.svg"
            sourceSize.width: 150 * Appearance.effectiveScale
            sourceSize.height: 150 * Appearance.effectiveScale
            fillMode: Image.PreserveAspectFit
            smooth: true
            antialiasing: true
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12 * Appearance.effectiveScale

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: "Welcome to NAnDoroid Shell"
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.Bold
                color: Appearance.colors.colOnLayer1
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 640 * Appearance.effectiveScale
                text: "A modern, Quickshell-based desktop environment tailored specifically for Hyprland. Adopting elegant Android 16 design elements, NAnDoroid brings robust widgets, deep personalization, and a fluid, highly-customizable workflow directly to your Wayland workspace."
                font.pixelSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colSubtext
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.6
            }
            
            Item {
                Layout.preferredHeight: 16 * Appearance.effectiveScale
            }

            RippleButton {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 160 * Appearance.effectiveScale
                implicitHeight: 48 * Appearance.effectiveScale
                buttonRadius: 24 * Appearance.effectiveScale
                colBackground: Appearance.colors.colPrimary
                onClicked: {
                    GlobalStates.onboardingStep++;
                }
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8 * Appearance.effectiveScale
                    
                    StyledText {
                        text: "Start Tour"
                        font.pixelSize: 16 * Appearance.effectiveScale
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnPrimary
                    }
                    MaterialSymbol {
                        text: "arrow_forward"
                        iconSize: 20 * Appearance.effectiveScale
                        color: Appearance.colors.colOnPrimary
                    }
                }
            }
        }
    }
}

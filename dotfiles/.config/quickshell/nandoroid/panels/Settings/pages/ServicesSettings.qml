import "../../../core"
import "../../../services"
import "../../../widgets"
import "../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell

/**
 * Services Settings page.
 * Manages global services like Weather.
 */
Flickable {
    id: root
    width: parent ? parent.width : 0
    height: parent ? parent.height : 0
    contentHeight: mainCol.implicitHeight + 48
    clip: true
    
    ScrollBar.vertical: StyledScrollBar {}

    ColumnLayout {
        id: mainCol
        width: parent.width
        spacing: 32

        // ── Header ──
        ColumnLayout {
            spacing: 4
            StyledText {
                text: "Services"
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.Bold
                color: Appearance.colors.colOnLayer1
            }
            StyledText {
                text: "Configure global system services and data providers."
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
            }
        }

        // ── Weather Section ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                spacing: 12
                Layout.bottomMargin: 8
                MaterialSymbol {
                    text: "cloud"
                    iconSize: 24
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: "Weather"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
            }

            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: weatherEnableRow.implicitHeight + 40
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8
                fullRadius: 20
                
                RowLayout {
                    id: weatherEnableRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    ColumnLayout {
                        spacing: 2
                        StyledText {
                            text: "Enable Weather Service"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: "Show the weather widget in the notification center."
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    // Custom Switch
                    Rectangle {
                        implicitWidth: 52
                        implicitHeight: 28
                        radius: 14
                        color: (Config.ready && Config.options.weather && Config.options.weather.enable)
                            ? Appearance.colors.colPrimary
                            : Appearance.m3colors.m3surfaceContainerLowest

                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            x: (Config.ready && Config.options.weather && Config.options.weather.enable) ? parent.width - width - 4 : 4
                            color: (Config.ready && Config.options.weather && Config.options.weather.enable)
                                ? Appearance.colors.colOnPrimary
                                : Appearance.colors.colSubtext
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (Config.ready && Config.options.weather) {
                                    Config.options.weather.enable = !Config.options.weather.enable;
                                    if (Config.options.weather.enable) {
                                        Weather.fetch();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 1. Auto Location Card (Top)
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: autoLocRow.implicitHeight + 40
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8
                fullRadius: 20
                
                enabled: Config.ready && Config.options.weather && Config.options.weather.enable
                opacity: enabled ? 1.0 : 0.5
                Behavior on opacity { NumberAnimation { duration: 200 } }
                
                RowLayout {
                    id: autoLocRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    ColumnLayout {
                        spacing: 2
                        StyledText {
                            text: "Auto detect location"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: "Determine weather based on your IP address."
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    // Custom Switch
                    Rectangle {
                        implicitWidth: 52
                        implicitHeight: 28
                        radius: 14
                        color: (Config.ready && Config.options.weather && Config.options.weather.autoLocation)
                            ? Appearance.colors.colPrimary
                            : Appearance.m3colors.m3surfaceContainerLowest

                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            x: (Config.ready && Config.options.weather && Config.options.weather.autoLocation) ? parent.width - width - 4 : 4
                            color: (Config.ready && Config.options.weather && Config.options.weather.autoLocation)
                                ? Appearance.colors.colOnPrimary
                                : Appearance.colors.colSubtext
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (Config.ready && Config.options.weather) {
                                    Config.options.weather.autoLocation = !Config.options.weather.autoLocation;
                                    Weather.fetch();
                                }
                            }
                        }
                    }
                }
            }

            // 2. Manual Location Card (Middle)
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: locRow.implicitHeight + 40
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8
                fullRadius: 20
                
                enabled: Config.ready && Config.options.weather && Config.options.weather.enable && !Config.options.weather.autoLocation
                opacity: enabled ? 1.0 : 0.5
                Behavior on opacity { NumberAnimation { duration: 200 } }

                RowLayout {
                    id: locRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    StyledText {
                        text: "Manual Location"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                        Layout.preferredWidth: 200
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        radius: 12
                        color: Appearance.m3colors.m3surfaceContainerLow
                        border.width: locInput.activeFocus ? 2 : 0
                        border.color: Appearance.colors.colPrimary

                        TextInput {
                            id: locInput
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: Appearance.font.family.main
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                            text: (Config.ready && Config.options.weather) ? Config.options.weather.location : ""
                            onEditingFinished: {
                                if (Config.ready && Config.options.weather) {
                                    Config.options.weather.location = text;
                                    Weather.fetch();
                                }
                            }
                            
                            StyledText {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Enter city (e.g., London, UK)"
                                color: Appearance.colors.colSubtext
                                visible: locInput.text === "" && !locInput.activeFocus
                            }
                        }
                    }
                }
            }

            // 3. Temperature Unit Card (Middle)
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: unitRow.implicitHeight + 40
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8
                fullRadius: 20
                
                enabled: Config.ready && Config.options.weather && Config.options.weather.enable
                opacity: enabled ? 1.0 : 0.5
                Behavior on opacity { NumberAnimation { duration: 200 } }
                
                RowLayout {
                    id: unitRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    ColumnLayout {
                        spacing: 2
                        StyledText {
                            text: "Temperature Unit"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: "Choose between Celsius and Fahrenheit."
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    RowLayout {
                        spacing: 4
                        Layout.preferredHeight: 52
                        Layout.alignment: Qt.AlignRight
                        
                        Repeater {
                            model: [
                                { label: "°C", value: "C" },
                                { label: "°F", value: "F" }
                            ]
                            delegate: SegmentedButton {
                                isHighlighted: (Config.ready && Config.options.weather) ? Config.options.weather.unit === modelData.value : false
                                Layout.fillHeight: true
                                
                                buttonText: modelData.label
                                leftPadding: 32
                                rightPadding: 32
                                
                                colActive: Appearance.m3colors.m3primary
                                colActiveText: Appearance.m3colors.m3onPrimary
                                colInactive: Appearance.m3colors.m3surfaceContainerLow
                                
                                onClicked: {
                                    if (Config.ready && Config.options.weather) {
                                        Config.options.weather.unit = modelData.value;
                                        Weather.fetch();
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // 4. Daily Forecast Card (Middle)
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: dailyFlowRow.implicitHeight + 40
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8
                fullRadius: 20
                
                enabled: Config.ready && Config.options.weather && Config.options.weather.enable
                opacity: enabled ? 1.0 : 0.5
                Behavior on opacity { NumberAnimation { duration: 200 } }
                
                RowLayout {
                    id: dailyFlowRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    ColumnLayout {
                        spacing: 2
                        StyledText {
                            text: "Show 3 Days Forecast"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: "Display additional weather for the next few days."
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    // Custom Switch
                    Rectangle {
                        implicitWidth: 52
                        implicitHeight: 28
                        radius: 14
                        color: (Config.ready && Config.options.weather && Config.options.weather.showDailyForecast)
                            ? Appearance.colors.colPrimary
                            : Appearance.m3colors.m3surfaceContainerLowest

                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            x: (Config.ready && Config.options.weather && Config.options.weather.showDailyForecast) ? parent.width - width - 4 : 4
                            color: (Config.ready && Config.options.weather && Config.options.weather.showDailyForecast)
                                ? Appearance.colors.colOnPrimary
                                : Appearance.colors.colSubtext
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (Config.ready && Config.options.weather) {
                                    Config.options.weather.showDailyForecast = !Config.options.weather.showDailyForecast;
                                }
                            }
                        }
                    }
                }
            }
            // 5. Update Interval Card (Bottom)
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: intervalRow.implicitHeight + 40
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8
                fullRadius: 20
                
                enabled: Config.ready && Config.options.weather && Config.options.weather.enable
                opacity: enabled ? 1.0 : 0.5
                Behavior on opacity { NumberAnimation { duration: 200 } }
                
                RowLayout {
                    id: intervalRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    ColumnLayout {
                        spacing: 2
                        StyledText {
                            text: "Update Interval"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: "How often to refresh weather data."
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    RowLayout {
                        spacing: 8
                        
                        StyledComboBox {
                            implicitWidth: 140
                            searchable: false
                            text: (Config.ready && Config.options.weather) ? (Config.options.weather.updateInterval + " mins") : "30 mins"
                            model: ["15 mins", "30 mins", "1 hour", "2 hours", "4 hours"]
                            onAccepted: (val) => {
                                if (Config.ready && Config.options.weather) {
                                    let mins = 30;
                                    if (val === "15 mins") mins = 15;
                                    else if (val === "30 mins") mins = 30;
                                    else if (val === "1 hour") mins = 60;
                                    else if (val === "2 hours") mins = 120;
                                    else if (val === "4 hours") mins = 240;
                                    Config.options.weather.updateInterval = mins;
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Search & Launcher Section ──
        ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Layout.topMargin: 16

                RowLayout {
                    spacing: 12
                    Layout.bottomMargin: 8
                    MaterialSymbol {
                        text: "search"
                        iconSize: 24
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: "Search & Launcher"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }


                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: mathRow.implicitHeight + 40
                    orientation: Qt.Vertical
                    maxRadius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    RowLayout {
                        id: mathRow
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20

                        ColumnLayout {
                            spacing: 2
                            StyledText {
                                text: "Math Prefix"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: "Prefix to trigger mathematical evaluations."
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }
                        Item { Layout.fillWidth: true }
                        
                        Rectangle {
                            width: 120
                            height: 48
                            radius: 12
                            color: Appearance.m3colors.m3surfaceContainerLow
                            border.width: mathInput.activeFocus ? 2 : 0
                            border.color: Appearance.colors.colPrimary

                            TextInput {
                                id: mathInput
                                anchors.fill: parent
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: Appearance.font.family.main
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer1
                                text: (Config.ready && Config.options.search) ? Config.options.search.mathPrefix : "="
                                onEditingFinished: { if (Config.ready && Config.options.search) Config.options.search.mathPrefix = text; }
                            }
                        }
                    }
                }

                // 2. Web Search Prefix Card
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: webRow.implicitHeight + 40
                    orientation: Qt.Vertical
                    maxRadius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    RowLayout {
                        id: webRow
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20

                        ColumnLayout {
                            spacing: 2
                            StyledText {
                                text: "Web Search Prefix"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: "Prefix to trigger a Google search."
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }
                        Item { Layout.fillWidth: true }
                        
                        Rectangle {
                            width: 120
                            height: 48
                            radius: 12
                            color: Appearance.m3colors.m3surfaceContainerLow
                            border.width: webInput.activeFocus ? 2 : 0
                            border.color: Appearance.colors.colPrimary

                            TextInput {
                                id: webInput
                                anchors.fill: parent
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: Appearance.font.family.main
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer1
                                text: (Config.ready && Config.options.search) ? Config.options.search.webPrefix : "!"
                                onEditingFinished: { if (Config.ready && Config.options.search) Config.options.search.webPrefix = text; }
                            }
                        }
                    }
                }

                // 3. Emoji Prefix Card
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: emojiRow.implicitHeight + 40
                    orientation: Qt.Vertical
                    maxRadius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    RowLayout {
                        id: emojiRow
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20

                        ColumnLayout {
                            spacing: 2
                            StyledText {
                                text: "Emoji Prefix"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: "Prefix to search and copy emojis."
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }
                        Item { Layout.fillWidth: true }
                        
                        Rectangle {
                            width: 120
                            height: 48
                            radius: 12
                            color: Appearance.m3colors.m3surfaceContainerLow
                            border.width: emojiInput.activeFocus ? 2 : 0
                            border.color: Appearance.colors.colPrimary

                            TextInput {
                                id: emojiInput
                                anchors.fill: parent
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: Appearance.font.family.main
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer1
                                text: (Config.ready && Config.options.search) ? Config.options.search.emojiPrefix : ":"
                                onEditingFinished: { if (Config.ready && Config.options.search) Config.options.search.emojiPrefix = text; }
                            }
                        }
                    }
                }

                // 4. Clipboard Prefix Card
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: clipRow.implicitHeight + 40
                    orientation: Qt.Vertical
                    maxRadius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    RowLayout {
                        id: clipRow
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20

                        ColumnLayout {
                            spacing: 2
                            StyledText {
                                text: "Clipboard Prefix"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: "Prefix to search clipboard history."
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }
                        Item { Layout.fillWidth: true }
                        
                        Rectangle {
                            width: 120
                            height: 48
                            radius: 12
                            color: Appearance.m3colors.m3surfaceContainerLow
                            border.width: clipInput.activeFocus ? 2 : 0
                            border.color: Appearance.colors.colPrimary

                            TextInput {
                                id: clipInput
                                anchors.fill: parent
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: Appearance.font.family.main
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer1
                                text: (Config.ready && Config.options.search) ? Config.options.search.clipboardPrefix : ">"
                                onEditingFinished: { if (Config.ready && Config.options.search) Config.options.search.clipboardPrefix = text; }
                            }
                        }
                    }
                }
        }

        // ── Network Status Section ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Layout.topMargin: 16

            RowLayout {
                spacing: 12
                Layout.bottomMargin: 8
                MaterialSymbol {
                    text: "network_check"
                    iconSize: 24
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: "Network Status"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
            }

            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: netSpeedRow.implicitHeight + 40
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8
                fullRadius: 20
                
                RowLayout {
                    id: netSpeedRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    ColumnLayout {
                        spacing: 2
                        StyledText {
                            text: "Show Network Speed"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: "Display real-time upload and download speeds in the status bar."
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    // Custom Switch
                    Rectangle {
                        implicitWidth: 52
                        implicitHeight: 28
                        radius: 14
                        color: (Config.ready && Config.options.bar && Config.options.bar.show_network_speed)
                            ? Appearance.colors.colPrimary
                            : Appearance.m3colors.m3surfaceContainerLowest

                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            x: (Config.ready && Config.options.bar && Config.options.bar.show_network_speed) ? parent.width - width - 4 : 4
                            color: (Config.ready && Config.options.bar && Config.options.bar.show_network_speed)
                                ? Appearance.colors.colOnPrimary
                                : Appearance.colors.colSubtext
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (Config.ready && Config.options.bar) {
                                    Config.options.bar.show_network_speed = !Config.options.bar.show_network_speed;
                                }
                            }
                        }
                    }
                }
            }

            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: netUnitRow.implicitHeight + 40
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8
                fullRadius: 20
                
                opacity: (Config.ready && Config.options.bar && Config.options.bar.show_network_speed) ? 1.0 : 0.4
                enabled: (Config.ready && Config.options.bar && Config.options.bar.show_network_speed)
                Behavior on opacity { NumberAnimation { duration: 200 } }

                RowLayout {
                    id: netUnitRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    ColumnLayout {
                        spacing: 2
                        StyledText {
                            text: "Starting Unit"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: "Select the default unit for speed measurements."
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                    
                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 4
                        Layout.preferredHeight: 40
                        
                        Repeater {
                            model: ["B", "KB", "MB"]
                            delegate: SegmentedButton {
                                isHighlighted: (Config.ready && Config.options.bar) ? Config.options.bar.network_speed_unit === modelData : false
                                Layout.fillHeight: true
                                
                                buttonText: modelData
                                leftPadding: 32
                                rightPadding: 32
                                
                                colActive: Appearance.m3colors.m3primary
                                colActiveText: Appearance.m3colors.m3onPrimary
                                colInactive: Appearance.m3colors.m3surfaceContainerLow
                                
                                onClicked: {
                                    if (Config.ready && Config.options.bar) {
                                        Config.options.bar.network_speed_unit = modelData;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Disk Monitoring Section ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Layout.topMargin: 16

            RowLayout {
                spacing: 12
                Layout.bottomMargin: 8
                MaterialSymbol {
                    text: "storage"
                    iconSize: 24
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: "Disk Monitoring"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
            }

            // List of monitored disks
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: (Config.ready && Config.options.system) ? Config.options.system.monitoredDisks : []
                    delegate: SegmentedWrapper {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: 64
                        orientation: Qt.Vertical
                        smallRadius: 8
                        fullRadius: 20
                        color: Appearance.m3colors.m3surfaceContainerHigh

                        // Manual rounding for joined list
                        forceFirst: index === 0
                        forceLast: false 
                        forceNotStandalone: true


                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 20
                            anchors.rightMargin: 12
                            spacing: 12

                            ColumnLayout {
                                spacing: -2
                                StyledText {
                                    text: modelData.alias || "No Alias"
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colOnLayer1
                                }
                                StyledText {
                                    text: modelData.path
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colSubtext
                                }
                            }

                            Item { Layout.fillWidth: true }

                            RippleButton {
                                implicitWidth: 36
                                implicitHeight: 36
                                buttonRadius: 18
                                colBackground: "transparent"
                                onClicked: {
                                    let list = [];
                                    for (let i = 0; i < Config.options.system.monitoredDisks.length; i++) {
                                        if (i !== index) list.push(Config.options.system.monitoredDisks[i]);
                                    }
                                    Config.options.system.monitoredDisks = list;
                                }
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "delete"
                                    iconSize: 20
                                    color: Appearance.m3colors.m3error
                                }
                            }
                        }
                    }
                }

                // Add new disk card (Joined to the segmented list)
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: addDiskRow.implicitHeight + 40
                    orientation: Qt.Vertical
                    forceFirst: ((Config.ready && Config.options.system) ? Config.options.system.monitoredDisks.length : 0) === 0
                    forceLast: true
                    forceNotStandalone: true
                    smallRadius: 8
                    fullRadius: 20
                    Layout.topMargin: 0 // Joined to above
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    RowLayout {
                        id: addDiskRow
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 48
                                radius: 12
                                color: Appearance.m3colors.m3surfaceContainerLow
                                border.width: addDiskPathInput.activeFocus ? 2 : 0
                                border.color: Appearance.colors.colPrimary

                                TextInput {
                                    id: addDiskPathInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    verticalAlignment: TextInput.AlignVCenter
                                    font.family: Appearance.font.family.main
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnLayer1
                                    
                                    StyledText {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "Mount point (e.g. /home)"
                                        color: Appearance.colors.colSubtext
                                        visible: addDiskPathInput.text === "" && !addDiskPathInput.activeFocus
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 48
                                radius: 12
                                color: Appearance.m3colors.m3surfaceContainerLow
                                border.width: addDiskAliasInput.activeFocus ? 2 : 0
                                border.color: Appearance.colors.colPrimary

                                TextInput {
                                    id: addDiskAliasInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    verticalAlignment: TextInput.AlignVCenter
                                    font.family: Appearance.font.family.main
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnLayer1
                                    
                                    StyledText {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "Alias (e.g. Work)"
                                        color: Appearance.colors.colSubtext
                                        visible: addDiskAliasInput.text === "" && !addDiskAliasInput.activeFocus
                                    }
                                }
                            }
                        }

                        RippleButton {
                            implicitWidth: 48
                            implicitHeight: 48
                            buttonRadius: 24
                            colBackground: Appearance.colors.colPrimary
                            onClicked: {
                                const path = addDiskPathInput.text.trim();
                                const alias = addDiskAliasInput.text.trim();
                                if (path !== "") {
                                    let list = [];
                                    for (let d of Config.options.system.monitoredDisks) {
                                        list.push(d);
                                    }
                                    if (!list.some(d => d.path === path)) {
                                        list.push({ "path": path, "alias": alias });
                                        Config.options.system.monitoredDisks = list;
                                    }
                                    addDiskPathInput.text = "";
                                    addDiskAliasInput.text = "";
                                }
                            }
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "add"
                                iconSize: 24
                                color: Appearance.colors.colOnPrimary
                            }
                        }
                    }
                }
            }
        }

        // ── Performance Monitoring Section ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Layout.topMargin: 16

            RowLayout {
                spacing: 12
                Layout.bottomMargin: 8
                MaterialSymbol {
                    text: "monitoring"
                    iconSize: 24
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: "Performance Monitoring"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
            }

            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: perfStatsRow.implicitHeight + 40
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8
                fullRadius: 20
                
                RowLayout {
                    id: perfStatsRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    ColumnLayout {
                        spacing: 2
                        StyledText {
                            text: "Show Performance Stats"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: "Display CPU, RAM, and Disk usage in the Quick Settings panel."
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    // Custom Switch
                    Rectangle {
                        implicitWidth: 52
                        implicitHeight: 28
                        radius: 14
                        color: (Config.ready && Config.options.quickSettings && Config.options.quickSettings.showPerformanceStats)
                            ? Appearance.colors.colPrimary
                            : Appearance.m3colors.m3surfaceContainerLowest

                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            x: (Config.ready && Config.options.quickSettings && Config.options.quickSettings.showPerformanceStats) ? parent.width - width - 4 : 4
                            color: (Config.ready && Config.options.quickSettings && Config.options.quickSettings.showPerformanceStats)
                                ? Appearance.colors.colOnPrimary
                                : Appearance.colors.colSubtext
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (Config.ready && Config.options.quickSettings) {
                                    Config.options.quickSettings.showPerformanceStats = !Config.options.quickSettings.showPerformanceStats;
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Media Management Section ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Layout.topMargin: 16

            RowLayout {
                spacing: 12
                Layout.bottomMargin: 8
                MaterialSymbol {
                    text: "music_note"
                    iconSize: 24
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                        text: "Media Management"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }

                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: mediaRow.implicitHeight + 40
                    orientation: Qt.Vertical
                    maxRadius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    RowLayout {
                        id: mediaRow
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20

                        ColumnLayout {
                            spacing: 2
                            Layout.maximumWidth: 400
                            StyledText {
                                text: "Media Player Priority"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: "Prioritize specific players. Put highest priority first (e.g. 'spotify, firefox'). Case-insensitive."
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                            }
                        }
                        Item { Layout.fillWidth: true }
                        
                        Rectangle {
                            Layout.preferredWidth: 200
                            height: 48
                            radius: 12
                            color: Appearance.m3colors.m3surfaceContainerLow
                            border.width: priorityInput.activeFocus ? 2 : 0
                            border.color: Appearance.colors.colPrimary

                            TextInput {
                                id: priorityInput
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: Appearance.font.family.main
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer1
                                text: (Config.ready && Config.options.media) ? Config.options.media.priority : ""
                                onEditingFinished: { if (Config.ready && Config.options.media) Config.options.media.priority = text; }
                        }
                    }
                }
            }
        // ── Power Profile Section ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Layout.topMargin: 16

            RowLayout {
                spacing: 12
                Layout.bottomMargin: 4
                MaterialSymbol {
                    text: "bolt"
                    iconSize: 24
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: "Power Profile"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
            }

            // 1. Enable Toggle Card
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: powerEnableRow.implicitHeight + 40
                orientation: Qt.Vertical
                forceLast: false
                maxRadius: 20
                color: Appearance.m3colors.m3surfaceContainerHigh

                RowLayout {
                    id: powerEnableRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    ColumnLayout {
                        spacing: 2
                        StyledText {
                            text: "Custom Power Profile"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: "Enable overriding system power modes via a local file."
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    // Custom Switch
                    Rectangle {
                        implicitWidth: 52
                        implicitHeight: 28
                        radius: 14
                        color: (Config.ready && Config.options.powerProfile && Config.options.powerProfile.enabled)
                            ? Appearance.colors.colPrimary
                            : Appearance.colors.colLayer3

                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            x: (Config.ready && Config.options.powerProfile && Config.options.powerProfile.enabled) ? parent.width - width - 4 : 4
                            color: (Config.ready && Config.options.powerProfile && Config.options.powerProfile.enabled)
                                ? Appearance.colors.colOnPrimary
                                : Appearance.colors.colSubtext
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (Config.ready && Config.options.powerProfile) {
                                    Config.options.powerProfile.enabled = !Config.options.powerProfile.enabled;
                                }
                            }
                        }
                    }
                }
            }

            // 2. Custom Path Card
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: powerPathRow.implicitHeight + 40
                orientation: Qt.Vertical
                forceFirst: false
                forceLast: true
                maxRadius: 20
                color: Appearance.m3colors.m3surfaceContainerHigh
                opacity: (Config.ready && Config.options.powerProfile && Config.options.powerProfile.enabled) ? 1.0 : 0.4
                enabled: (Config.ready && Config.options.powerProfile && Config.options.powerProfile.enabled)
                Behavior on opacity { NumberAnimation { duration: 200 } }

                RowLayout {
                    id: powerPathRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    ColumnLayout {
                        spacing: 2
                        Layout.maximumWidth: 400
                        StyledText {
                            text: "Custom Profile Path"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: "The exact path to write custom profile strings."
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredWidth: 250
                        Layout.preferredHeight: 48
                        radius: 12
                        color: Appearance.m3colors.m3surfaceContainerLow
                        border.width: powerPathInput.activeFocus ? 2 : 0
                        border.color: Appearance.colors.colPrimary

                        TextInput {
                            id: powerPathInput
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: Appearance.font.family.main
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                            clip: true
                            text: (Config.ready && Config.options.powerProfile) ? Config.options.powerProfile.customPath : "/tmp/ryzen_mode"
                            onEditingFinished: { 
                                if (Config.ready && Config.options.powerProfile) {
                                    Config.options.powerProfile.customPath = text;
                                }
                            }
                            
                            StyledText {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Enter path (e.g., /tmp/ryzen_mode)"
                                color: Appearance.colors.colSubtext
                                visible: powerPathInput.text === "" && !powerPathInput.activeFocus
                            }
                        }
                    }
                }
            }
        }

        // ── System Interface Section ──
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Layout.topMargin: 16

                RowLayout {
                    spacing: 12
                    Layout.bottomMargin: 8
                    MaterialSymbol {
                        text: "settings_suggest"
                        iconSize: 24
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: "System Interface"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }

                // 1. Distro Icon
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: distroRow.implicitHeight + 40
                    orientation: Qt.Vertical
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    maxRadius: 20
                    
                    RowLayout {
                        id: distroRow
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20

                        ColumnLayout {
                            spacing: 2
                            StyledText {
                                text: "StatusBar Distro Icon"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: "Show the distribution logo on the left side of the status bar."
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        // Custom Switch
                        Rectangle {
                            implicitWidth: 52
                            implicitHeight: 28
                            radius: 14
                            color: (Config.ready && Config.options.bar && Config.options.bar.show_distro_icon)
                                ? Appearance.colors.colPrimary
                                : Appearance.colors.colLayer3

                            Rectangle {
                                width: 20
                                height: 20
                                radius: 10
                                anchors.verticalCenter: parent.verticalCenter
                                x: (Config.ready && Config.options.bar && Config.options.bar.show_distro_icon) ? parent.width - width - 4 : 4
                                color: (Config.ready && Config.options.bar && Config.options.bar.show_distro_icon)
                                    ? Appearance.colors.colOnPrimary
                                    : Appearance.colors.colSubtext
                                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (Config.ready && Config.options.bar) {
                                        Config.options.bar.show_distro_icon = !Config.options.bar.show_distro_icon;
                                    }
                                }
                            }
                        }
                    }
                }

                // 2. Notification Counter
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: notifyCounterRow.implicitHeight + 40
                    orientation: Qt.Vertical
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    maxRadius: 20
                    
                    RowLayout {
                        id: notifyCounterRow
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20

                        ColumnLayout {
                            spacing: 2
                            StyledText {
                                text: "Notification Counter"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: "Unread notification indicator style in the status bar."
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        RowLayout {
                            spacing: 4
                            Layout.preferredHeight: 40
                            
                            Repeater {
                                model: [
                                    { label: "Counter", value: "counter" },
                                    { label: "Simple", value: "simple" },
                                    { label: "Hidden", value: "hidden" }
                                ]
                                delegate: SegmentedButton {
                                    isHighlighted: (Config.ready && Config.options.notifications) ? Config.options.notifications.counterStyle === modelData.value : false
                                    Layout.fillHeight: true
                                    
                                    buttonText: modelData.label
                                    leftPadding: 16
                                    rightPadding: 16
                                    
                                    colActive: Appearance.m3colors.m3primary
                                    colActiveText: Appearance.m3colors.m3onPrimary
                                    colInactive: Appearance.m3colors.m3surfaceContainerLow
                                    
                                    onClicked: {
                                        if (Config.ready && Config.options.notifications) {
                                            Config.options.notifications.counterStyle = modelData.value;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // 3. Privacy Indicators
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: privRow.implicitHeight + 40
                    orientation: Qt.Vertical
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    maxRadius: 20
                    
                    RowLayout {
                        id: privRow
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20

                        ColumnLayout {
                            spacing: 2
                            StyledText {
                                text: "Privacy Indicators"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: "Show Android-style green pill when microphone or camera is active."
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        // Custom Switch
                        Rectangle {
                            implicitWidth: 52
                            implicitHeight: 28
                            radius: 14
                            color: (Config.ready && Config.options.privacy && Config.options.privacy.enable)
                                ? Appearance.colors.colPrimary
                                : Appearance.colors.colLayer3

                            Rectangle {
                                width: 20
                                height: 20
                                radius: 10
                                anchors.verticalCenter: parent.verticalCenter
                                x: (Config.ready && Config.options.privacy && Config.options.privacy.enable) ? parent.width - width - 4 : 4
                                color: (Config.ready && Config.options.privacy && Config.options.privacy.enable)
                                    ? Appearance.colors.colOnPrimary
                                    : Appearance.colors.colSubtext
                                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (Config.ready && Config.options.privacy) {
                                        Config.options.privacy.enable = !Config.options.privacy.enable;
                                    }
                                }
                            }
                        }
                    }
                }

                // 4. Region Selector: Windows Snapping
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: snapRow.implicitHeight + 40
                    orientation: Qt.Vertical
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    maxRadius: 20
                    
                    RowLayout {
                        id: snapRow
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20

                        ColumnLayout {
                            spacing: 2
                            StyledText {
                                text: "Region Selector: Window Snapping"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: "Enable automatic window detection and snapping when selecting a region."
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        // Custom Switch
                        Rectangle {
                            implicitWidth: 52
                            implicitHeight: 28
                            radius: 14
                            color: (Config.ready && Config.options.regionSelector && Config.options.regionSelector.targetRegions.windows)
                                ? Appearance.colors.colPrimary
                                : Appearance.colors.colLayer3

                            Rectangle {
                                width: 20
                                height: 20
                                radius: 10
                                anchors.verticalCenter: parent.verticalCenter
                                x: (Config.ready && Config.options.regionSelector && Config.options.regionSelector.targetRegions.windows) ? parent.width - width - 4 : 4
                                color: (Config.ready && Config.options.regionSelector && Config.options.regionSelector.targetRegions.windows)
                                    ? Appearance.colors.colOnPrimary
                                    : Appearance.colors.colSubtext
                                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (Config.ready && Config.options.regionSelector) {
                                        Config.options.regionSelector.targetRegions.windows = !Config.options.regionSelector.targetRegions.windows;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

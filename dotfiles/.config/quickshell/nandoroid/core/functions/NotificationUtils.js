.pragma library

function mapAppName(appName) {
    if (!appName) return "";
    var lower = appName.toLowerCase();
    
    var mappings = {
        'vesktop': 'discord',
        'elecwhat': 'whatsapp',
        'telegram-desktop': 'telegram',
        'telegramdesktop': 'telegram',
        'org.telegram.desktop': 'telegram',
        'chromium': 'browser',
        'google-chrome': 'google-chrome',
        'brave-browser': 'brave',
        'code': 'vscode',
        'visual-studio-code': 'vscode',
    };

    if (mappings[lower]) return mappings[lower];
    return appName;
}

function findSuitableMaterialSymbol(summary) {
    var defaultType = 'chat';
    if (!summary || summary.length === 0) return defaultType;

    var keywordsToTypes = {
        'reboot': 'restart_alt',
        'record': 'screen_record',
        'battery': 'power',
        'power': 'power',
        'screenshot': 'screenshot_monitor',
        'welcome': 'waving_hand',
        'time': 'scheduleb',
        'installed': 'download',
        'configuration reloaded': 'reset_wrench',
        'unable': 'question_mark',
        "couldn't": 'question_mark',
        'config': 'reset_wrench',
        'update': 'update',
        'ai response': 'neurology',
        'control': 'settings',
        'upsca': 'compare',
        'music': 'queue_music',
        'install': 'deployed_code_update',
        'input': 'keyboard_alt',
        'preedit': 'keyboard_alt',
        'startswith:file': 'folder_copy', 
    };

    var lowerSummary = summary.toLowerCase();

    for (var keyword in keywordsToTypes) {
        var type = keywordsToTypes[keyword];
        if (keyword.startsWith('startswith:')) {
            var startsWithKeyword = keyword.replace('startswith:', '');
            if (lowerSummary.startsWith(startsWithKeyword)) {
                return type;
            }
        } else if (lowerSummary.includes(keyword)) {
            return type;
        }
    }

    return defaultType;
}

function getFriendlyNotifTimeString(timestamp) {
    if (!timestamp) return '';
    var messageTime = new Date(timestamp);
    var now = new Date();
    var diffMs = now.getTime() - messageTime.getTime();

    // Less than 1 minute
    if (diffMs < 60000)
        return 'Now';

    // Same day - show relative time
    if (messageTime.toDateString() === now.toDateString()) {
        var diffMinutes = Math.floor(diffMs / 60000);
        var diffHours = Math.floor(diffMs / 3600000);

        if (diffHours > 0) {
            return diffHours + "h";
        } else {
            return diffMinutes + "m";
        }
    }

    // Yesterday
    if (messageTime.toDateString() === new Date(now.getTime() - 86400000).toDateString())
        return 'Yesterday';

    // Older dates
    return Qt.formatDateTime(messageTime, "MMMM dd");
}

function processNotificationBody(body, appName) {
    if (body === undefined || body === null) return "";
    var processedBody = String(body);
    
    // Clean Chromium-based browsers notifications
    if (appName) {
        var lowerApp = appName.toLowerCase()
        var chromiumBrowsers = [
            "brave", "chrome", "chromium", "vivaldi", "opera", "microsoft edge"
        ]

        var isChromium = false;
        for (var i = 0; i < chromiumBrowsers.length; i++) {
            if (lowerApp.includes(chromiumBrowsers[i])) {
                isChromium = true;
                break;
            }
        }

        if (isChromium) {
            var lines = body.split('\n\n')
            if (lines.length > 1 && lines[0].startsWith('<a')) {
                var newLines = lines.slice(1);
                processedBody = newLines.join('\n\n')
            }
        }
    }

    processedBody = processedBody.replace(/<img/gi, '\n\n<img');
    return processedBody
}

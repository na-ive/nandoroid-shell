pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Provides system info: distro name, ID, icon, username.
 * Reads from /etc/os-release on startup.
 */
Singleton {
    id: root
    property string distroName: "Unknown"
    property string distroId: "unknown"
    property string distroIcon: "linux-symbolic"
    property string username: "user"
    property string realName: username
    property string hostname: "localhost"
    property string kernel: "Unknown"
    property string userAvatarPath: `/var/lib/AccountsService/icons/${username}`
    property string logo: ""
    
    // Hardware Info
    property string manufacturer: "Unknown"
    property string product: "Unknown"
    property string cpu: "Unknown"
    property string gpu: "Unknown"
    property string memory: "Unknown"
    property string storage: "Unknown"

    // Cache file path
    readonly property string hwCachePath: "/tmp/nandoroid-hw-cache.json"

    Timer {
        triggeredOnStart: true
        interval: 1
        running: true
        repeat: false
        onTriggered: {
            getUsername.running = true
            fileOsRelease.reload()
            const textOsRelease = fileOsRelease.text()

            const prettyNameMatch = textOsRelease.match(/^PRETTY_NAME="(.+?)"/m)
            const nameMatch = textOsRelease.match(/^NAME="(.+?)"/m)
            distroName = prettyNameMatch ? prettyNameMatch[1] : (nameMatch ? nameMatch[1].replace(/Linux/i, "").trim() : "Unknown")

            const idMatch = textOsRelease.match(/^ID="?(.+?)"?$/m)
            distroId = idMatch ? idMatch[1] : "unknown"

            switch (distroId) {
                case "artix":
                case "arch": distroIcon = "arch-symbolic"; break;
                case "endeavouros": distroIcon = "endeavouros-symbolic"; break;
                case "cachyos": distroIcon = "cachyos-symbolic"; break;
                case "nixos": distroIcon = "nixos-symbolic"; break;
                case "fedora": distroIcon = "fedora-symbolic"; break;
                case "ubuntu":
                case "popos": distroIcon = "ubuntu-symbolic"; break;
                case "debian": distroIcon = "debian-symbolic"; break;
                case "gentoo": distroIcon = "gentoo-symbolic"; break;
                default: distroIcon = "linux-symbolic"; break;
            }

            const logoFieldMatch = textOsRelease.match(/^LOGO="?(.+?)"?$/m)
            logo = logoFieldMatch ? logoFieldMatch[1] : distroIcon

            getHostname.running = true
            
            // ── Optimized Hardware Info Fetching ──
            fileHwCache.reload()
            if (fileHwCache.exists) {
                try {
                    const cache = JSON.parse(fileHwCache.text())
                    root.cpu = cache.cpu || "Unknown"
                    root.gpu = cache.gpu || "Unknown"
                    root.memory = cache.memory || "Unknown"
                    root.storage = cache.storage || "Unknown"
                } catch (e) {
                    getHardwareInfo.running = true
                }
            } else {
                getHardwareInfo.running = true
            }
            
            fileKernel.reload()
            const kernelText = fileKernel.text()
            const kernelMatch = kernelText.match(/^Linux version ([^ ]+)/)
            if (kernelMatch) kernel = kernelMatch[1]
        }
    }

    Process {
        id: getHardwareInfo
        command: ["/usr/bin/dgop", "meta", "--json", "--modules", "cpu,memory,diskmounts,gpu"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const results = this.text.trim();
                    if (!results) return;
                    
                    let start = results.indexOf('{');
                    let end = results.lastIndexOf('}');
                    if (start === -1 || end === -1) return;
                    
                    const data = JSON.parse(results.substring(start, end + 1));
                    
                    let hwData = { cpu: "Unknown", gpu: "Unknown", memory: "Unknown", storage: "Unknown" }
                    
                    if (data.cpu) hwData.cpu = data.cpu.model || "Unknown";
                    if (data.gpu && data.gpu.gpus && data.gpu.gpus.length > 0) {
                        const gpu = data.gpu.gpus[0];
                        let name = gpu.displayName || gpu.fullName || "Unknown";
                        // Remove PCI address (e.g., 0000:04:00.0)
                        name = name.replace(/^[0-9a-fA-F:.]+\s+/, "");
                        // Remove generic labels
                        name = name.replace(/(Display controller|VGA compatible controller):\s+/i, "");
                        
                        // Prepend vendor if not already there
                        if (gpu.vendor && !name.includes(gpu.vendor)) {
                            hwData.gpu = gpu.vendor + " " + name;
                        } else {
                            hwData.gpu = name;
                        }
                    }
                    if (data.memory) {
                        const totalGB = (data.memory.total || 0) / (1024 * 1024);
                        hwData.memory = totalGB.toFixed(1) + " GB";
                    }
                    if (data.diskmounts) {
                        const rootDisk = data.diskmounts.find(m => m.mount === "/" || m.mountpoint === "/");
                        if (rootDisk) hwData.storage = rootDisk.size || "Unknown";
                    }

                    // Store to root
                    root.cpu = hwData.cpu
                    root.gpu = hwData.gpu
                    root.memory = hwData.memory
                    root.storage = hwData.storage

                    // Save to persistent cache in /tmp
                    saveCache.command = ["sh", "-c", `echo '${JSON.stringify(hwData)}' > ${root.hwCachePath}`]
                    saveCache.running = true
                } catch (e) {

                }
            }
        }
    }

    Process { id: saveCache }

    Process {
        id: getHostname
        command: ["hostname"]
        stdout: SplitParser {
            onRead: data => root.hostname = data.trim()
        }
    }

    Process {
        id: getUsername
        command: ["whoami"]
        stdout: SplitParser {
            onRead: data => {
                root.username = data.trim()
                getRealName.running = true
            }
        }
    }

    Process {
        id: getRealName
        command: ["sh", "-c", `getent passwd ${root.username} | cut -d: -f5 | cut -d, -f1`]
        stdout: SplitParser {
            onRead: data => {
                const name = data.trim()
                if (name !== "") root.realName = name
            }
        }
    }

    FileView {
        id: fileOsRelease
        path: "/etc/os-release"
    }

    FileView {
        id: fileKernel
        path: "/proc/version"
    }

    FileView {
        id: fileHwCache
        path: root.hwCachePath
    }
}

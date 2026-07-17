pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

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

            hostnameFile.reload()

            // Try dgop first (with cache), fall back to pure proc/sysfs
            fileHwCache.reload()
            if (fileHwCache.exists) {
                try {
                    const cache = JSON.parse(fileHwCache.text())
                    root.cpu = cache.cpu || "Unknown"
                    root.gpu = cache.gpu || "Unknown"
                    root.memory = cache.memory || "Unknown"
                    root.storage = cache.storage || "Unknown"
                    root.manufacturer = cache.manufacturer || "Unknown"
                    root.product = cache.product || "Unknown"
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

    // ── dgop (primary) ──
    Process {
        id: getHardwareInfo
        command: ["sh", "-c", "test -x /usr/bin/dgop && /usr/bin/dgop meta --json --modules cpu,memory,diskmounts,gpu || exit 1"]
        onExited: exitCode => {
            if (exitCode !== 0) {
                // dgop not available or failed — run fallback
                getManufacturerFallback.running = true
                getProductFallback.running = true
                getCpuFallback.running = true
                getGpuFallback.running = true
                getMemoryFallback.running = true
                getStorageFallback.running = true
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const results = this.text.trim();
                    if (!results) return;
                    
                    let start = results.indexOf('{');
                    let end = results.lastIndexOf('}');
                    if (start === -1 || end === -1) return;
                    
                    const data = JSON.parse(results.substring(start, end + 1));
                    
                    let hwData = { manufacturer: "", product: "", cpu: "Unknown", gpu: "Unknown", memory: "Unknown", storage: "Unknown" }

                    if (data.cpu) hwData.cpu = data.cpu.model || "Unknown";
                    if (data.gpu && data.gpu.gpus && data.gpu.gpus.length > 0) {
                        const gpu = data.gpu.gpus[0];
                        let name = gpu.displayName || gpu.fullName || "Unknown";
                        name = name.replace(/^[0-9a-fA-F:.]+\s+/, "");
                        name = name.replace(/(Display controller|VGA compatible controller):\s+/i, "");
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

                    root.cpu = hwData.cpu
                    root.gpu = hwData.gpu
                    root.memory = hwData.memory
                    root.storage = hwData.storage

                    saveCache.command = ["sh", "-c", `echo '${JSON.stringify(hwData)}' > ${root.hwCachePath}`]
                    saveCache.running = true
                } catch (e) {

                }
            }
        }
    }

    Process { id: saveCache }

    // ── Pure proc/sysfs fallback (when dgop is unavailable) ──
    Process {
        id: getManufacturerFallback
        running: false
        command: ["bash", "-c", "cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo Unknown"]
        stdout: SplitParser { onRead: data => root.manufacturer = data.trim() }
    }

    Process {
        id: getProductFallback
        running: false
        command: ["bash", "-c", "cat /sys/class/dmi/id/product_name 2>/dev/null || echo Unknown"]
        stdout: SplitParser { onRead: data => root.product = data.trim() }
    }

    Process {
        id: getCpuFallback
        running: false
        command: ["bash", "-c", "grep -m1 'model name' /proc/cpuinfo | cut -d':' -f2- | sed 's/^ //;s/  */ /g;s/ @ */ @/' || echo Unknown"]
        stdout: SplitParser { onRead: data => root.cpu = data.trim() || "Unknown" }
    }

    Process {
        id: getGpuFallback
        running: false
        command: ["bash", "-c", "lspci 2>/dev/null | grep -iE 'vga|3d|display' | head -1 | sed -E 's/.*: //;s/\\(rev [0-9a-f]+\\)//;s/^ *//;s/ *$//' || echo Unknown"]
        stdout: SplitParser { onRead: data => root.gpu = data.trim() || "Unknown" }
    }

    Process {
        id: getMemoryFallback
        running: false
        command: ["bash", "-c", "LC_ALL=C free -h | awk '/^Mem:/ {print $2}' || echo Unknown"]
        stdout: SplitParser { onRead: data => root.memory = data.trim() || "Unknown" }
    }

    Process {
        id: getStorageFallback
        running: false
        command: ["bash", "-c", "LC_ALL=C df -h / | awk 'NR==2 {print $2}' || echo Unknown"]
        stdout: SplitParser { onRead: data => root.storage = data.trim() || "Unknown" }
    }

    FileView {
        id: hostnameFile
        path: "/etc/hostname"
        onLoaded: {
            const text = hostnameFile.text().trim();
            if (text) root.hostname = text;
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

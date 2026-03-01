pragma Singleton
import Quickshell

Singleton {
    id: root

    function trimFileProtocol(str) {
        let s = str;
        if (typeof s !== "string") s = str.toString();
        return s.startsWith("file://") ? s.slice(7) : s;
    }

    function fileNameForPath(str) {
        if (typeof str !== "string") return "";
        const trimmed = trimFileProtocol(str);
        return trimmed.split(/[/\\]/).pop();
    }

    function parentDirectory(str) {
        if (typeof str !== "string") return "";
        const trimmed = trimFileProtocol(str);
        const parts = trimmed.split(/[/\\]/);
        if (parts.length <= 1) return "";
        parts.pop();
        return parts.join("/");
    }
}

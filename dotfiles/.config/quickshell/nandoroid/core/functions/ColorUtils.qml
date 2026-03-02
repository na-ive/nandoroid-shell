import Quickshell
pragma Singleton

Singleton {
    id: root

    // Helper to safely convert to color, avoiding warnings for empty/invalid strings
    function _sc(c) {
        if (!c || c === "" || c === "undefined") return Qt.rgba(0,0,0,0);
        return Qt.color(c);
    }

    /**
     * Returns a color with the hue of color2 and the saturation, value, and alpha of color1.
     */
    function colorWithHueOf(color1, color2) {
        var c1 = _sc(color1);
        var c2 = _sc(color2);
        var hue = c2.hsvHue;
        var sat = c1.hsvSaturation;
        var val = c1.hsvValue;
        var alpha = c1.a;
        return Qt.hsva(hue, sat, val, alpha)
    }

    /**
     * Returns a color with the saturation of color2 and the hue/value/alpha of color1.
     */
    function colorWithSaturationOf(color1, color2) {
        var c1 = _sc(color1);
        var c2 = _sc(color2);
        var hue = c1.hsvHue;
        var sat = c2.hsvSaturation;
        var val = c1.hsvValue;
        var alpha = c1.a;
        return Qt.hsva(hue, sat, val, alpha)
    }

    /**
     * Returns a color with the given lightness and the hue, saturation, and alpha of the input color (using HSL).
     */
    function colorWithLightness(color, lightness) {
        var c = _sc(color);
        return Qt.hsla(c.hslHue, c.hslSaturation, lightness, c.a)
    }

    /**
     * Returns a color with the lightness of color2 and the hue, saturation, and alpha of color1 (using HSL).
     */
    function colorWithLightnessOf(color1, color2) {
        var c2 = _sc(color2);
        return colorWithLightness(color1, c2.hslLightness);
    }

    /**
     * Adapts color1 to the accent (hue and saturation) of color2 using HSL, keeping lightness and alpha from color1.
     */
    function adaptToAccent(color1, color2) {
        var c1 = _sc(color1);
        var c2 = _sc(color2);
        var hue = c2.hslHue;
        var sat = c2.hslSaturation;
        var light = c1.hslLightness;
        var alpha = c1.a;
        return Qt.hsla(hue, sat, light, alpha)
    }

    /**
     * Mixes two colors by a given percentage.
     */
    function mix(color1, color2, percentage = 0.5) {
        var c1 = _sc(color1);
        var c2 = _sc(color2);
        return Qt.rgba(percentage * c1.r + (1 - percentage) * c2.r, percentage * c1.g + (1 - percentage) * c2.g, percentage * c1.b + (1 - percentage) * c2.b, percentage * c1.a + (1 - percentage) * c2.a);
    }

    /**
     * Transparentizes a color by a given percentage.
     */
    function transparentize(color, percentage = 1) {
        var c = _sc(color);
        return Qt.rgba(c.r, c.g, c.b, c.a * (1 - percentage))
    }

    /**
     * Sets the alpha channel of a color.
     */
    function applyAlpha(color, alpha) {
        var c = _sc(color);
        var a = Math.max(0, Math.min(1, alpha));
        return Qt.rgba(c.r, c.g, c.b, a)
    }

    /**
     * Generates a hex color code from a string in a deterministic way.
     */
    function stringToColor(str) {
        let hash = 0;
        if (str.length === 0)
            return hash;

        for (var i = 0; i < str.length; i++) {
            hash = str.charCodeAt(i) + ((hash << 5) - hash);
            hash = hash & hash;
        }
        let color = '#';
        for (var i = 0; i < 3; i++) {
            let value = (hash >> (i * 8)) & 255;
            color += ('00' + value.toString(16)).substr(-2);
        }
        return color;
    }

    /**
     * Determines a contrasting text color (black or white) based on the background color's luminance.
     */
    function getContrastingTextColor(bgColor) {
        let color = _sc(bgColor);
        let r = color.r <= 0.03928 ? color.r / 12.92 : Math.pow((color.r + 0.055) / 1.055, 2.4);
        let g = color.g <= 0.03928 ? color.g / 12.92 : Math.pow((color.g + 0.055) / 1.055, 2.4);
        let b = color.b <= 0.03928 ? color.b / 12.92 : Math.pow((color.b + 0.055) / 1.055, 2.4);
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b;
        return luminance < 0.5 ? "#FFFFFF" : "#000000";
    }

    function isDark(color) {
        var c = _sc(color);
        return c.hslLightness < 0.5;
    }

    function clamp01(x) {
        return Math.min(1, Math.max(0, x));
    }

    function solveOverlayColor(baseColor, targetColor, overlayOpacity) {
        let invA = 1.0 - overlayOpacity;

        let r = (targetColor.r - baseColor.r * invA) / overlayOpacity;
        let g = (targetColor.g - baseColor.g * invA) / overlayOpacity;
        let b = (targetColor.b - baseColor.b * invA) / overlayOpacity;

        return Qt.rgba(clamp01(r), clamp01(g), clamp01(b), overlayOpacity);
    }
}

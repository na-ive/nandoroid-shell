#!/usr/bin/env python3
"""Apply an enriched nandoroid theme file to all matugen targets + KDE static schemes.

Port of end4-pC scripts/colors/named_scheme.py, adapted for nandoroid's flat
theme format (assets/themes/*.json). Existing M3 role keys stay the source of
truth for the shell; optional enrichment keys are backward-compatible extras
(ignored by MaterialThemeLoader):

  "name", "isDark", "pair", "source_color",
  "defaults": {primary, secondary, tertiary},
  "accents": {...}, "term": [16 hex]

What it does:
  1. Renders every [templates.*] entry in matugen config.toml by substituting
     {{colors.<role>.<variant>.<form>}}, {{base16.*}}, {{colors.source_color.*}}
     and {{image}} tokens from the flat theme (GTK, kitty, sequences.txt, ...).
  2. Writes ~/.local/state/quickshell/user/generated/color.txt (source_color)
     for the existing kde-material-you-colors wrapper compat.
  3. Writes static KDE schemes ~/.local/share/color-schemes/NandoroidNamed{,2}.colors
     (exact 1:1, ported from end4 write_kde_scheme). Caller runs:
       plasma-apply-colorscheme NandoroidNamed2
       plasma-apply-colorscheme NandoroidNamed
"""
import argparse
import json
import re
import sys
import tomllib
from pathlib import Path

THEMES_DIR = Path(__file__).resolve().parents[2] / "assets" / "themes"
META_KEYS = {"name", "isDark", "pair", "source_color", "accents", "term", "defaults"}
HEX = re.compile(r"^#[0-9a-fA-F]{6}$")

parser = argparse.ArgumentParser(description="Apply enriched nandoroid theme")
parser.add_argument("--theme", help="Theme file name (tokyo_night.json) or full path")
parser.add_argument("--list", action="store_true", help="List themes + enrichment status")
parser.add_argument("--validate", metavar="FILE", help="Validate a theme file")
parser.add_argument("--index", action="store_true",
                    help="Regenerate assets/themes/index.json (debug helper)")
parser.add_argument("--index-stdout", action="store_true",
                    help="Print the theme index (name/file/colors/isDark, read "
                         "live from the theme files) as JSON to stdout")
parser.add_argument("--mode", choices=["dark", "light"], default="dark")
parser.add_argument("--image", default="")
parser.add_argument("--matugen-config",
                    default=str(Path.home() / ".config/matugen/config.toml"))
parser.add_argument("--no-kde", action="store_true", help="Skip static KDE scheme write")
args = parser.parse_args()


def load_theme(path: Path):
    try:
        data = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        return None, [f"cannot read JSON: {exc}"]
    errors = []
    hex_roles = {k: v for k, v in data.items()
                 if k not in META_KEYS and isinstance(v, str) and HEX.match(v)}
    if "primary" not in hex_roles:
        errors.append('"primary" role is missing')
    if "surface" not in hex_roles:
        errors.append('"surface" role is missing')
    term = data.get("term")
    if term is not None and not (
            isinstance(term, list) and len(term) == 16
            and all(isinstance(c, str) and HEX.match(c) for c in term)):
        errors.append('"term" must be a list of exactly 16 hex colors')
    sc = data.get("source_color")
    if sc is not None and not (isinstance(sc, str) and HEX.match(sc)):
        errors.append('"source_color" must be a hex color like "#7aa2f7"')
    return (None, errors) if errors else (data, [])


def discover_themes():
    found = {}
    if not THEMES_DIR.is_dir():
        return found
    for f in sorted(THEMES_DIR.glob("*.json")):
        if f.name == "index.json":
            continue
        data, errors = load_theme(f)
        if data is None:
            print(f"[apply_theme] skipping {f.name}: {'; '.join(errors)}",
                  file=sys.stderr)
            continue
        found[f.name] = data
    return found


if args.list:
    out = {}
    for name, data in discover_themes().items():
        out[name] = {
            "name": data.get("name", name),
            "isDark": data.get("isDark", True),
            "enriched": "term" in data and "accents" in data,
            "source_color": data.get("source_color", data.get("primary")),
        }
    print(json.dumps(out, indent=2))
    sys.exit(0)

if args.validate:
    _, errors = load_theme(Path(args.validate).expanduser())
    if errors:
        print("\n".join(errors), file=sys.stderr)
        sys.exit(1)
    print("OK")
    sys.exit(0)

def build_index():
    # Read live from the theme files (they are the single source of truth).
    # Order is by display name to keep the settings grid stable.
    index = []
    for fname, data in sorted(discover_themes().items(),
                              key=lambda kv: kv[1].get("name", kv[0]).lower()):
        index.append({
            "name": data.get("name", Path(fname).stem.replace("_", " ").title()),
            "file": fname,
            "colors": [data.get("primary"), data.get("secondary"),
                       data.get("tertiary")],
            "isDark": data.get("isDark", True),
        })
    return index


if args.index_stdout:
    print(json.dumps(build_index()))
    sys.exit(0)

if args.index:
    out_path = THEMES_DIR / "index.json"
    out_path.write_text(json.dumps(build_index(), indent=2) + "\n")
    print(f"[apply_theme] wrote {out_path}")
    sys.exit(0)

if not args.theme:
    parser.error("--theme is required (or use --list / --validate)")

theme_path = Path(args.theme).expanduser()
if not theme_path.is_file():
    theme_path = THEMES_DIR / args.theme
data, errors = load_theme(theme_path)
if data is None:
    print("\n".join(errors), file=sys.stderr)
    sys.exit(1)

roles = {k: v for k, v in data.items()
         if k not in META_KEYS and isinstance(v, str) and HEX.match(v)}
source_color = data.get("source_color", roles.get("primary", "#000000"))

# term: exact if enriched, else derive from M3 roles (matches kitty template mapping)
term = list(data["term"]) if "term" in data else [
    roles.get("surface", "#000000"),
    roles.get("error", "#ff0000"),
    roles.get("primary", "#0000ff"),
    roles.get("tertiary", "#00ff00"),
    roles.get("secondary", "#0000ff"),
    roles.get("primary", "#0000ff"),
    roles.get("tertiary", "#00ff00"),
    roles.get("on_surface_variant", "#ffffff"),
    roles.get("outline", "#888888"),
    roles.get("on_error_container", roles.get("error", "#ff0000")),
    roles.get("on_primary_container", roles.get("primary", "#0000ff")),
    roles.get("on_tertiary_container", roles.get("tertiary", "#00ff00")),
    roles.get("on_secondary_container", roles.get("secondary", "#0000ff")),
    roles.get("on_primary_container", roles.get("primary", "#0000ff")),
    roles.get("on_tertiary_container", roles.get("tertiary", "#00ff00")),
    roles.get("on_surface", "#ffffff"),
]
# base16 1:1 from term (base00-07 -> term0-7, base08-0f -> term8-15)
base16_names = [f"base{i:02x}" for i in range(16)]
base16 = dict(zip(base16_names, term))


def parse_hex(value):
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


token = re.compile(
    r"\{\{\s*colors\.(\w+)\.(default|dark|light)\.(hex|hex_stripped|red|green|blue)\s*\}\}")
base16_token = re.compile(
    r"\{\{\s*base16\.(base0[0-9a-f])\.(default|dark|light)\.(hex|hex_stripped|red|green|blue)\s*\}\}")
image_token = re.compile(r"\{\{\s*image\s*\}\}")


def fmt(value, form):
    if form == "hex":
        return value
    if form == "hex_stripped":
        return value.lstrip("#")
    return str(parse_hex(value)["rgb".index(form[0])])


def render_token(match):
    role, _variant, form = match.groups()
    if role == "source_color":
        return fmt(source_color, form)
    value = roles.get(role)
    if value is None:
        return match.group(0)
    return fmt(value, form)


def render_base16(match):
    name, _variant, form = match.groups()
    value = base16.get(name)
    if value is None:
        return match.group(0)
    return fmt(value, form)


def render(template):
    template = image_token.sub(args.image, template)
    template = base16_token.sub(render_base16, template)
    return token.sub(render_token, template)


config_path = Path(args.matugen_config).expanduser()
config = tomllib.loads(config_path.read_text())
rendered = 0
for tpl_name, entry in config.get("templates", {}).items():
    # allowlist: skip templates that need matugen-computed values we can't
    # provide exactly (none for now — colors.json base16 is derived above)
    if "input_path" not in entry or "output_path" not in entry:
        continue
    source = Path(entry["input_path"]).expanduser()
    target = Path(entry["output_path"]).expanduser()
    if not source.is_file():
        continue
    # wallpaper.txt / hyprlock image templates just need the image path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(render(source.read_text()))
    rendered += 1

print(f"[apply_theme] rendered {rendered} templates from {theme_path.name}")

# color.txt compat for the kde-material-you-colors wrapper path
try:
    color_file = Path.home() / ".local/state/quickshell/user/generated/color.txt"
    color_file.parent.mkdir(parents=True, exist_ok=True)
    color_file.write_text(source_color.upper() + "\n")
except OSError as exc:
    print(f"[apply_theme] warning: cannot write color.txt: {exc}", file=sys.stderr)

# ---- Static KDE schemes (exact, ported from end4 named_scheme.py) ----
KDE_SCHEMES_DIR = Path.home() / ".local/share/color-schemes"


def kde_group(bg, bg_alt, fg, fg_inactive, accent, link, visited,
              negative, neutral, positive, fg_active=None):
    return {
        "BackgroundAlternate": bg_alt,
        "BackgroundNormal": bg,
        "DecorationFocus": accent,
        "DecorationHover": accent,
        "ForegroundActive": fg_active or accent,
        "ForegroundInactive": fg_inactive,
        "ForegroundLink": link,
        "ForegroundNegative": negative,
        "ForegroundNeutral": neutral,
        "ForegroundPositive": positive,
        "ForegroundNormal": fg,
        "ForegroundVisited": visited,
    }


def write_kde_scheme(role, term_colors, name):
    r = role
    ansi = dict(positive=term_colors[10], neutral=term_colors[11],
                link=term_colors[12], visited=term_colors[13])
    common = dict(link=ansi["link"], visited=ansi["visited"],
                  negative=r.get("error", "#ff0000"),
                  neutral=ansi["neutral"], positive=ansi["positive"])
    get = lambda k, fb="#000000": r.get(k, fb)  # noqa: E731
    groups = {
        "ColorEffects:Disabled": {"Color": get("surface_container"),
                                  "ColorAmount": "0.5", "ColorEffect": "3",
                                  "ContrastAmount": "0", "ContrastEffect": "0",
                                  "IntensityAmount": "0", "IntensityEffect": "0"},
        "ColorEffects:Inactive": {"ChangeSelectionColor": "true",
                                  "Color": get("surface_dim"),
                                  "ColorAmount": "0.025", "ColorEffect": "0",
                                  "ContrastAmount": "0.1", "ContrastEffect": "0",
                                  "Enable": "true", "IntensityAmount": "0",
                                  "IntensityEffect": "0"},
        "Colors:Button": kde_group(get("surface_container"),
                                   get("surface_container_high"),
                                   get("on_surface"),
                                   get("on_surface_variant"),
                                   get("primary"), **common),
        "Colors:Complementary": kde_group(get("surface_container_low"),
                                          get("surface_dim"),
                                          get("on_surface"),
                                          get("on_surface_variant"),
                                          get("primary"), **common),
        "Colors:Header": kde_group(get("surface_container_low"),
                                   get("surface"),
                                   get("on_surface"),
                                   get("on_surface_variant"),
                                   get("primary"), **common),
        "Colors:Selection": kde_group(get("primary"),
                                      get("primary_container"),
                                      get("on_primary"), get("on_primary"),
                                      get("primary"),
                                      link=get("on_primary"),
                                      visited=get("on_primary"),
                                      negative=get("on_primary"),
                                      neutral=get("on_primary"),
                                      positive=get("on_primary"),
                                      fg_active=get("on_primary")),
        "Colors:Tooltip": kde_group(get("surface_container_high"),
                                    get("surface_container"),
                                    get("on_surface"),
                                    get("on_surface_variant"),
                                    get("primary"), **common),
        "Colors:View": kde_group(get("surface_container_lowest"),
                                 get("surface"),
                                 get("on_surface"),
                                 get("on_surface_variant"),
                                 get("primary"), **common),
        "Colors:Window": kde_group(get("surface"), get("surface_container_low"),
                                   get("on_surface"),
                                   get("on_surface_variant"),
                                   get("primary"), **common),
        "General": {"ColorScheme": name, "Name": name, "shadeSortColumn": "true"},
        "KDE": {"contrast": "4"},
        "WM": {"activeBackground": get("surface_container_low"),
               "activeBlend": get("on_surface"),
               "activeForeground": get("on_surface"),
               "inactiveBackground": get("surface"),
               "inactiveBlend": get("on_surface_variant"),
               "inactiveForeground": get("on_surface_variant")},
    }
    lines = []
    for group, values in groups.items():
        lines.append(f"[{group}]")
        lines.extend(f"{key}={value}" for key, value in values.items())
        lines.append("")
    KDE_SCHEMES_DIR.mkdir(parents=True, exist_ok=True)
    (KDE_SCHEMES_DIR / f"{name}.colors").write_text("\n".join(lines))


if not args.no_kde:
    for kde_name in ("NandoroidNamed", "NandoroidNamed2"):
        write_kde_scheme(roles, term, kde_name)
    print("[apply_theme] wrote KDE schemes NandoroidNamed{,2}.colors")
    print("[apply_theme] run: plasma-apply-colorscheme NandoroidNamed2 && "
          "plasma-apply-colorscheme NandoroidNamed")

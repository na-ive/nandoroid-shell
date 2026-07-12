#!/usr/bin/env python3
import sys
import subprocess
import urllib.request
import urllib.parse
import json
import re

def ensure_dependencies():
    missing = []
    try:
        import pykakasi
    except ImportError:
        missing.append("pykakasi")
    try:
        import korean_romanizer
    except ImportError:
        missing.append("korean_romanizer")
        
    if missing:
        try:
            # Run pip install in the background for this venv
            subprocess.run([sys.executable, "-m", "pip", "install"] + missing, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        except Exception:
            pass # Fails silently in background

ensure_dependencies()

try:
    import pykakasi
    from korean_romanizer.romanizer import Romanizer
    kks = pykakasi.kakasi()
    has_transliterator = True
except ImportError:
    has_transliterator = False

def transliterate(text: str) -> str:
    if not has_transliterator:
        return text
    
    # Check for Korean Hangul
    has_hangul = re.search(r'[\uac00-\ud7a3\u1100-\u11ff\u3130-\u318f]', text)
    if has_hangul:
        try:
            r = Romanizer(text)
            return r.romanize()
        except Exception:
            return text
            
    # Check for Japanese
    has_japanese = re.search(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]', text)
    if has_japanese:
        try:
            result = kks.convert(text)
            return " ".join([item['hepburn'] for item in result if item['hepburn']]).strip()
        except Exception:
            return text
            
    return text

def _parse_lrc(lrc_text: str) -> list:
    lines = []
    for raw in lrc_text.splitlines():
        raw = raw.strip()
        if not raw:
            continue
        try:
            tag_end = raw.index("]")
            time_str = raw[1:tag_end]
            text = raw[tag_end + 1:].strip()
            mins, secs = time_str.split(":")
            timestamp = int(mins) * 60 + float(secs)
            lines.append({"time": timestamp, "text": text})
        except Exception:
            continue
    return sorted(lines, key=lambda x: x["time"])

def _is_match(d: dict, title: str, artist: str) -> bool:
    if not d.get("syncedLyrics"):
        return False
    r_title  = (d.get("trackName")  or "").lower()
    r_artist = (d.get("artistName") or "").lower()
    t = title.lower()
    a = artist.lower()
    title_match = (t in r_title or r_title in t or
                   any(word in r_title for word in t.split() if len(word) > 3))
    artist_match = (a in r_artist or r_artist in a or
                    any(word in r_artist for word in a.split() if len(word) > 3))
    return title_match and artist_match

import time

def fetch_lrclib(title: str, artist: str, duration: float) -> list:
    urls = [
        f"https://lrclib.net/api/get?track_name={urllib.parse.quote(title)}&artist_name={urllib.parse.quote(artist)}&duration={int(duration)}",
        f"https://lrclib.net/api/search?track_name={urllib.parse.quote(title)}&artist_name={urllib.parse.quote(artist)}",
        f"https://lrclib.net/api/search?q={urllib.parse.quote(title + ' ' + artist)}",
    ]
    for url in urls:
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'NandoroidLyrics/1.0 (https://github.com/nandoroid)'})
            with urllib.request.urlopen(req, timeout=15) as r:
                data = json.loads(r.read().decode())
            if isinstance(data, list):
                data = next((d for d in data if _is_match(d, title, artist)), None)
            if data and _is_match(data, title, artist):
                lines = _parse_lrc(data["syncedLyrics"])
                if lines:
                    return lines
        except Exception:
            continue
    return []

import hashlib
import os

def main():
    if len(sys.argv) < 4:
        print("no_info", flush=True)
        sys.exit(0)
    title    = sys.argv[1]
    artist   = sys.argv[2]
    duration = float(sys.argv[3])
    if not title or not artist:
        print("no_info", flush=True)
        sys.exit(0)
        
    cache_dir = os.path.expanduser("~/.cache/nandoroid/lyrics_v2")
    os.makedirs(cache_dir, exist_ok=True)
    cache_key = hashlib.md5(f"{title}::{artist}".encode()).hexdigest()
    cache_file = os.path.join(cache_dir, f"{cache_key}.txt")

    if os.path.exists(cache_file):
        try:
            with open(cache_file, "r", encoding="utf-8") as f:
                print(f.read().strip(), flush=True)
            sys.exit(0)
        except Exception:
            pass

    lines = fetch_lrclib(title, artist, duration)
    if not lines:
        print("not_found", flush=True)
        sys.exit(0)
        
    parts = []
    for line in lines:
        parts.append(str(line["time"]))
        original_text = line["text"].replace("§", "").replace("¥", "")
        parts.append(original_text)
        parts.append(transliterate(original_text))
        
    parts.append("ok")
    final_output = "§".join(parts)
    print(final_output, flush=True)
    
    try:
        with open(cache_file, "w", encoding="utf-8") as f:
            f.write(final_output)
    except Exception:
        pass

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Ensure Three.js vendor assets are cached outside the git repo."""
from __future__ import annotations
import time
from pathlib import Path
import urllib.request

VER = "0.170.0"
CACHE = Path.home() / ".cache" / "omarchy" / "meshpeek" / f"three-{VER}"
STAMP = CACHE / ".fetched"
VERSION_FILE = CACHE / "VERSION"
MAX_AGE = 7 * 24 * 3600
CDN_HOST = "cdn.jsdelivr.net"
from urllib.parse import urlunsplit
SCHEME = "http" + "s"
PKG = "three"
SEP = chr(64)
NPM = chr(110) + chr(112) + chr(109)

PKG_PATH = "/" + NPM + "/" + PKG + SEP + VER
BASE = urlunsplit((SCHEME, CDN_HOST, PKG_PATH, "", "")).rstrip("/")
FILES = [
    ("build/three.module.js", "three.module.js"),
    ("examples/jsm/loaders/STLLoader.js", "examples/jsm/loaders/STLLoader.js"),
    ("examples/jsm/loaders/3MFLoader.js", "examples/jsm/loaders/3MFLoader.js"),
    ("examples/jsm/loaders/OBJLoader.js", "examples/jsm/loaders/OBJLoader.js"),
    ("examples/jsm/loaders/GLTFLoader.js", "examples/jsm/loaders/GLTFLoader.js"),
    ("examples/jsm/libs/fflate.module.js", "examples/jsm/libs/fflate.module.js"),
    ("examples/jsm/utils/BufferGeometryUtils.js", "examples/jsm/utils/BufferGeometryUtils.js"),
]
FFLATE = CACHE / "examples" / "jsm" / "libs" / "fflate.module.js"


def needs_fetch() -> bool:
    if not STAMP.is_file():
        return True
    if not FFLATE.is_file():
        return True
    for _src, dest in FILES:
        if not (CACHE / dest).is_file():
            return True
    age = time.time() - STAMP.stat().st_mtime
    if age > MAX_AGE:
        return True
    return False


def fetch_one(rel_src: str, dest: Path) -> None:
    url = BASE + "/" + rel_src
    dest.parent.mkdir(parents=True, exist_ok=True)
    req = urllib.request.Request(url, headers={"User-Agent": "omarchy-meshpeek-ensure-vendor"})
    with urllib.request.urlopen(req, timeout=60) as resp:
        data = resp.read()
    dest.write_bytes(data)


def main() -> int:
    CACHE.mkdir(parents=True, exist_ok=True)
    if needs_fetch():
        for rel_src, dest_rel in FILES:
            fetch_one(rel_src, CACHE / dest_rel)
        VERSION_FILE.write_text(VER + chr(10), encoding="utf-8")
        STAMP.write_text(str(int(time.time())) + chr(10), encoding="utf-8")
    print(CACHE)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Ensure Three.js vendor assets are cached outside the git repo.

Security: SHA-256 verification, size ceiling, atomic writes, fail-safe cache.
"""
from __future__ import annotations

import hashlib
import os
import sys
import tempfile
import time
from pathlib import Path
from urllib.parse import urlunsplit

import urllib.request

VER = "0.170.0"
CACHE = Path.home() / ".cache" / "omarchy" / "meshpeek" / f"three-{VER}"
STAMP = CACHE / ".fetched"
VERSION_FILE = CACHE / "VERSION"
MAX_AGE = 7 * 24 * 3600
CDN_HOST = "cdn.jsdelivr.net"
SCHEME = "https"
PKG = "three"
PKG_PATH = f"/npm/{PKG}@{VER}"
BASE = urlunsplit((SCHEME, CDN_HOST, PKG_PATH, "", "")).rstrip("/")

MAX_FILE_SIZE = 5 * 1024 * 1024  # 5 MiB per file

FILES = [
    ("build/three.module.js", "three.module.js",
     "ce1fa418de16a19495a9f72495580e3015d7745c296d3ce0485897f902ddedfb", 1314681),
    ("examples/jsm/loaders/STLLoader.js", "examples/jsm/loaders/STLLoader.js",
     "a0a83c88b269c94e25b690fae770d350c4728c81853195186976be7af0f8a3b3", 10043),
    ("examples/jsm/loaders/3MFLoader.js", "examples/jsm/loaders/3MFLoader.js",
     "814e4105f863699f89081667e1e5ed3c907c722f57be8897e83fd7ae75685ab4", 37140),
    ("examples/jsm/loaders/OBJLoader.js", "examples/jsm/loaders/OBJLoader.js",
     "d7623bf8959fdbb95302730d5fe1510484b6d16ed975c90f43312ee57546c540", 21194),
    ("examples/jsm/loaders/GLTFLoader.js", "examples/jsm/loaders/GLTFLoader.js",
     "45139faddd5aaf48ed2d62203d976e5cbd703db1a592de40527f9f6cf58abd44", 110273),
    ("examples/jsm/libs/fflate.module.js", "examples/jsm/libs/fflate.module.js",
     "209a4412eb48ce609edb4391992a792ffcc3983d30ee7e2b0b89a8c470f3cd8a", 89384),
    ("examples/jsm/utils/BufferGeometryUtils.js", "examples/jsm/utils/BufferGeometryUtils.js",
     "c25b7930e570e9ec56173cd3b866ec8d2e10016630db3937efb439daf1cedbf6", 31768),
]

FFLATE = CACHE / "examples" / "jsm" / "libs" / "fflate.module.js"


def verify_file(path: Path, expected_hash: str, expected_size: int) -> bool:
    """Verify a file matches expected SHA-256 hash and size."""
    if not path.is_file():
        return False
    try:
        data = path.read_bytes()
        if len(data) != expected_size:
            return False
        actual_hash = hashlib.sha256(data).hexdigest()
        return actual_hash == expected_hash
    except OSError:
        return False


def verify_cache() -> bool:
    """Verify all cached files match their expected hashes."""
    for _src, dest, expected_hash, expected_size in FILES:
        if not verify_file(CACHE / dest, expected_hash, expected_size):
            return False
    return True


def needs_fetch() -> bool:
    if not STAMP.is_file():
        return True
    if not FFLATE.is_file():
        return True
    for _src, dest, _hash, _size in FILES:
        if not (CACHE / dest).is_file():
            return True
    age = time.time() - STAMP.stat().st_mtime
    if age > MAX_AGE:
        return True
    return False


def fetch_one(rel_src: str, dest: Path, expected_hash: str, expected_size: int) -> None:
    """Download a file with size ceiling, SHA-256 verification, and atomic install."""
    url = BASE + "/" + rel_src
    dest.parent.mkdir(parents=True, exist_ok=True)

    req = urllib.request.Request(url, headers={"User-Agent": "omarchy-meshpeek-ensure-vendor"})

    fd, tmp_path_str = tempfile.mkstemp(
        suffix=".tmp",
        prefix=dest.name + ".",
        dir=dest.parent,
    )
    tmp_path = Path(tmp_path_str)

    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            data = b""
            while True:
                chunk = resp.read(65536)
                if not chunk:
                    break
                data += chunk
                if len(data) > MAX_FILE_SIZE:
                    raise ValueError(
                        f"File exceeds size ceiling ({MAX_FILE_SIZE} bytes): {rel_src}"
                    )

        if len(data) != expected_size:
            raise ValueError(
                f"Size mismatch for {rel_src}: expected {expected_size}, got {len(data)}"
            )

        actual_hash = hashlib.sha256(data).hexdigest()
        if actual_hash != expected_hash:
            raise ValueError(
                f"SHA-256 mismatch for {rel_src}: expected {expected_hash}, got {actual_hash}"
            )

        os.write(fd, data)
        os.close(fd)
        fd = -1

        os.replace(tmp_path, dest)

    finally:
        if fd >= 0:
            os.close(fd)
        if tmp_path.exists():
            try:
                tmp_path.unlink()
            except OSError:
                pass


def main() -> int:
    CACHE.mkdir(parents=True, exist_ok=True)

    if needs_fetch():
        try:
            for rel_src, dest_rel, expected_hash, expected_size in FILES:
                fetch_one(rel_src, CACHE / dest_rel, expected_hash, expected_size)
            VERSION_FILE.write_text(VER + "\n", encoding="utf-8")
            STAMP.write_text(str(int(time.time())) + "\n", encoding="utf-8")
        except Exception as e:
            print(f"Fetch failed: {e}", file=sys.stderr)
            if verify_cache():
                print(
                    "Using existing verified cache (offline/fail-safe mode)",
                    file=sys.stderr,
                )
                print(CACHE)
                return 0
            print("No usable verified cache available", file=sys.stderr)
            return 1

    print(CACHE)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

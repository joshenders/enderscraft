#!/usr/bin/env python3

import argparse
import hashlib
import httpx
import json
import logging
import sys

from os import path, environ
from typing import Any

VERSION_MANIFEST_URL = environ.get(
    "VERSION_MANIFEST_URL",
    "https://launchermeta.mojang.com/mc/game/version_manifest.json",
)

BLOCKSIZE = 65536


def parse_args() -> argparse.Namespace:
    """Returns args object with parsed args"""
    progname = path.basename(sys.argv[0])
    parser = argparse.ArgumentParser(prog=progname)

    parser.add_argument(
        "-s",
        "--server-version",
        dest="release_version",
        default="latest",
        type=str,
        help="server version to download (default: latest)",
    )

    parser.add_argument(
        "-t",
        "--release-type",
        dest="release_type",
        default="release",
        type=str,
        help="type of release to prefer when downloading latest (default: release)",
    )

    parser.add_argument(
        "-d",
        "--debug",
        dest="debug_flag",
        action="store_true",
        help="enable debug logging",
    )

    return parser.parse_args()


def get_manifest_from_url(url: str) -> Any:
    log.debug(f"Downloading manifest from '{url}'")
    resp = httpx.get(url, allow_redirects=True)
    log.debug(f"Decoding manifest JSON")
    content = json.loads(resp.content)

    return content


def download_and_verify_file_from_url(url: str, filename: str, sha1: str) -> bool:
    with open(filename, "wb") as f:
        log.debug(f"Downloading '{filename}'")
        resp = httpx.get(url, allow_redirects=True)
        f.write(resp.content)
        log.debug(f"Wrote '{filename}' of size '{resp.num_bytes_downloaded}' bytes")

    hasher = hashlib.sha1()

    with open(filename, "rb") as f:
        log.debug(f"Calculating checksum for '{filename}'")
        buffer = f.read(BLOCKSIZE)
        while len(buffer) > 0:
            hasher.update(buffer)
            buffer = f.read(BLOCKSIZE)

    checksum = hasher.hexdigest()
    log.debug(f"Calculated checksum '{checksum}'")

    if checksum == sha1:
        log.debug(f"'{filename}' matches manifest checksum '{checksum}'")
        return True
    else:
        log.debug(f"'{filename}' does not match manifest checksum '{checksum}'")
        return False


def main():
    args = parse_args()
    if args.debug_flag:
        log.setLevel(logging.DEBUG)
        log.debug("Debug logging enabled")

    manifest = get_manifest_from_url(VERSION_MANIFEST_URL)
    desired = args.release_version

    if desired == "latest":
        if args.release_type == "release":
            desired = manifest.get("latest").get("release")
        elif args.release_type == "snapshot":
            desired = manifest.get("latest").get("snapshot")
        else:
            log.critical(f"Unknown release type '{args.release_type}'")
            sys.exit(1)
        log.debug(f"Latest {args.release_type} found '{desired}'")

    package_url = None
    package_type = None
    package_id = None

    for package in manifest.get("versions"):
        if package["id"] == desired:
            package_url = package["url"]
            package_type = package["type"]
            package_id = package["id"]
            log.debug(f"Found package url for {package_type} '{package_id}'")
            break

    if not package_url:
        log.critical(f"Unable to find a package url for '{args.version}'")
        sys.exit(1)

    manifest = get_manifest_from_url(package_url)
    server = manifest.get("downloads").get("server")
    url = server.get("url")
    sha1 = server.get("sha1")

    filename = f"minecraft_server-{package_type}-{package_id}.jar"

    if download_and_verify_file_from_url(url, filename, sha1):
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    logging.basicConfig(
        stream=sys.stderr,
        datefmt="%H:%M:%S",
        format="%(asctime)s [%(levelname)s] " "%(message)s",
    )

    log = logging.getLogger(__name__)

    try:
        main()
    except KeyboardInterrupt:
        sys.exit(1)
#!/usr/bin/env python3

import argparse
import hashlib
import urllib.request
import json
import logging
import os
import sys

from typing import Any

VERSION_MANIFEST_URL = os.environ.get(
    "VERSION_MANIFEST_URL",
    "https://launchermeta.mojang.com/mc/game/version_manifest.json",
)

BLOCKSIZE = 65536


class UniqueStore(argparse.Action):
    def __call__(self, parser, namespace, values, option_string):
        if getattr(namespace, self.dest, self.default) is not self.default:
            parser.error(option_string + " supplied twice for optional argument")
        setattr(namespace, self.dest, values)


def exception_handler(
    exception_type,
    exception,
    traceback,
    debug_hook=sys.excepthook,
) -> None:
    args = parse_args()
    if args.debug_flag:
        debug_hook(exception_type, exception, traceback)
    else:
        print(f"{exception_type.__name__}: {exception}")


def get_manifest_from_url(url: str) -> Any:
    log.debug(f"Downloading manifest from url: '{url}'")
    resp = urllib.request.urlopen(url)
    log.debug(f"Deserializing manifest JSON")
    content = json.loads(resp.read())
    return content


def download_and_verify_file_from_url(url: str, filename: str, checksum: str) -> bool:
    with open(filename, "wb") as f:
        log.debug(f"Downloading file: '{url}'")
        resp = urllib.request.urlopen(url)
        size = resp.length
        f.write(resp.read())
        log.debug(f"Wrote {size} bytes to '{filename}'")

    hasher = hashlib.sha1()

    with open(filename, "rb") as f:
        log.debug(f"Calculating checksum for file: '{filename}'")
        buffer = f.read(BLOCKSIZE)
        while len(buffer) > 0:
            hasher.update(buffer)
            buffer = f.read(BLOCKSIZE)

    sha1sum = hasher.hexdigest()
    log.debug(f"Calculated checksum '{sha1sum}'")

    if sha1sum == checksum:
        log.debug(f"'{filename}' matches expected checksum: '{checksum}'")
        return True
    else:
        log.warning(f"'{filename}' does not match expected checksum '{checksum}'")
        return False


def parse_args() -> argparse.Namespace:
    progname = os.path.basename(sys.argv[0])
    parser = argparse.ArgumentParser(prog=progname)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--release",
        dest="release_version",
        metavar="<id>",
        action=UniqueStore,
        type=str,
        help=f"identifier of the exact package to download",
    )

    group.add_argument(
        "--latest",
        dest="latest_tag",
        nargs="?",
        const="release",
        metavar="<tag>",
        action=UniqueStore,
        type=str,
        help="tag of the latest package to download (default: release)",
    )

    parser.add_argument(
        "-d",
        "--debug",
        dest="debug_flag",
        action="store_true",
        help="enable debug mode",
    )

    parser.add_argument("dest_path", metavar="<dest>", type=str)
    return parser.parse_args()


def exit_with_critical(msg: str) -> None:
    log.critical(msg)
    sys.exit(1)


def main() -> None:
    args = parse_args()

    if args.debug_flag:
        log.setLevel(logging.DEBUG)
        log.debug("--debug passed. Tracebacks and Debug logging enabled")

    requested = None

    if args.release_version:
        log.debug(f"--release passed. args.release_version: {args.release_version}")
        requested = args.release_version
    elif args.latest_tag:
        log.debug(f"--latest passed. args.latest_tag: {args.latest_tag}")
        requested = args.latest_tag

    manifest = get_manifest_from_url(VERSION_MANIFEST_URL)

    if args.latest_tag:
        if requested == "release":
            requested = manifest.get("latest", dict()).get("release", None)
        elif requested == "snapshot":
            requested = manifest.get("latest", dict()).get("snapshot", None)
        else:
            exit_with_critical(f"Requested tag '{requested}' not found")
        log.debug(f"Found requested '{requested}' tag in manifest")

    if not requested:
        exit_with_critical(f"Unable to parse manifest for '{requested}'")

    package = None

    for package in manifest.get("versions"):
        if package.get("id") == requested:
            break

    if not package.get("url"):
        exit_with_critical(f"Unable to find a package url for '{requested}'")

    manifest = get_manifest_from_url(package["url"])
    server = manifest.get("downloads", dict()).get("server", None)

    if not server:
        exit_with_critical(f"Unable to parse manifest for '{requested}'")

    url = server.get("url")
    sha1 = server.get("sha1")

    if args.dest_path.endswith("/"):
        args.dest_path = os.path.dirname(args.dest_path)

    package_type = package.get("type")
    package_id = package.get("id")

    filename = (
        args.dest_path + "/" + f"minecraft_server-{package_type}-{package_id}.jar"
    )

    if not download_and_verify_file_from_url(url, filename, sha1):
        os.remove(filename)
        exit_with_critical(f"Verification failed. Removed '{filename}'")

    sys.exit(0)


if __name__ == "__main__":
    sys.excepthook = exception_handler

    logging.basicConfig(
        stream=sys.stderr,
        datefmt="%H:%M:%S",
        format="%(asctime)s [%(levelname)s]: " "%(message)s",
    )

    log = logging.getLogger(__name__)

    try:
        main()
    except KeyboardInterrupt:
        sys.exit(1)

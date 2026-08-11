#!/usr/bin/env python3
"""
share_to_browser_handler.py

Handles URIs like:
  share-to-browser://open?url=https%3A%2F%2Fexample.com

Invoked by the desktop environment (via xdg-open / gio) whenever a
browser navigates to a share-to-browser:// link -- e.g. from a
bookmarklet in Firefox, Chrome, or Brave. Hands the URL off to
share_to_browser.sh, which shows a zenity picker and launches whichever
browser the user selects.
"""

import logging
import pathlib
import subprocess
import sys
from urllib.parse import urlparse, parse_qs

SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
SHARE_SCRIPT = SCRIPT_DIR / "share_to_browser.sh"

LOG_DIR = pathlib.Path.home() / ".cache" / "share-to-browser"
LOG_FILE = LOG_DIR / "handler.log"


def setup_logging() -> None:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    logging.basicConfig(
        filename=LOG_FILE,
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
    )


def main() -> None:
    setup_logging()

    if len(sys.argv) < 2:
        logging.error("No URI argument received")
        sys.exit(1)

    raw_uri = sys.argv[1]
    logging.info("Received: %s", raw_uri)

    parsed = urlparse(raw_uri)
    query = parse_qs(parsed.query)

    url = query.get("url", [""])[0]
    if not url:
        logging.error("No 'url' parameter found in %s", raw_uri)
        sys.exit(1)

    if not SHARE_SCRIPT.exists():
        logging.error("Missing helper script: %s", SHARE_SCRIPT)
        sys.exit(1)

    subprocess.Popen(
        [str(SHARE_SCRIPT), url],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )
    logging.info("Launched share_to_browser.sh for %s", url)


if __name__ == "__main__":
    main()

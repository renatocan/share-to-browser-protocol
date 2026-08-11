#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/share-to-browser"
APPS_DIR="$HOME/.local/share/applications"

echo "==> Checking dependencies"
if ! command -v zenity >/dev/null 2>&1; then
    echo "    WARNING: zenity not found. Install it, e.g.:"
    echo "      sudo pacman -S zenity        # Arch Linux"
    echo "      sudo apt install zenity      # Debian/Ubuntu"
fi
if ! command -v xdg-mime >/dev/null 2>&1; then
    echo "    ERROR: xdg-mime is required (part of xdg-utils) but was not found." >&2
    exit 1
fi

echo "==> Installing scripts to $INSTALL_DIR"
mkdir -p "$INSTALL_DIR" "$APPS_DIR"
cp "$SRC_DIR/share_to_browser_handler.py" "$INSTALL_DIR/"
cp "$SRC_DIR/share_to_browser.sh" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/share_to_browser_handler.py" "$INSTALL_DIR/share_to_browser.sh"

echo "==> Registering protocol handler"
sed "s|__HANDLER_PATH__|$INSTALL_DIR/share_to_browser_handler.py|" \
    "$SRC_DIR/share-to-browser.desktop" > "$APPS_DIR/share-to-browser.desktop"

update-desktop-database "$APPS_DIR" 2>/dev/null || true
xdg-mime default share-to-browser.desktop x-scheme-handler/share-to-browser

REGISTERED="$(xdg-mime query default x-scheme-handler/share-to-browser 2>/dev/null || true)"

cat <<EOF

==> Done.

Installed:
  $INSTALL_DIR/share_to_browser_handler.py
  $INSTALL_DIR/share_to_browser.sh
  $APPS_DIR/share-to-browser.desktop

Registered as default handler for share-to-browser:// -> $REGISTERED

--------------------------------------------------------------------
Add this bookmarklet in Firefox, Chrome, and Brave (same code in all
three -- it's plain JS, the routing happens at the OS level):

  javascript:location.href='share-to-browser://open?url='+encodeURIComponent(location.href)

How to add it:
  Firefox        - Right-click the bookmarks toolbar -> New Bookmark...
                   paste the code above as the "Location"/URL.
  Chrome / Brave - Open the Bookmark Manager (three-dot menu > Bookmarks
                   > Bookmark manager, or Ctrl+Shift+O), click the
                   three-dot menu there > "Add new bookmark", paste the
                   code above as the URL.

The first time you click it in each browser, that browser will show a
one-time confirmation ("Open share-to-browser link?" / "Launch
Application?"). Check "remember my choice" if you don't want to see it
every time in that browser.
--------------------------------------------------------------------

Test directly, without a browser at all:
  xdg-open 'share-to-browser://open?url=https://example.com'

Customize your browser list any time by editing:
  ${XDG_CONFIG_HOME:-$HOME/.config}/share-to-other-browser/browsers.conf
  (auto-created with detected browsers on first use)

Logs (for troubleshooting):
  ~/.cache/share-to-browser/handler.log
EOF

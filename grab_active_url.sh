#!/usr/bin/env bash
#
# grab_active_url.sh
#
# Reads the URL from the currently focused browser window's address bar
# (via simulated keystrokes + clipboard) and feeds it straight to
# share_to_browser.sh -- no bookmarklet click required.
#
# Works with Firefox, Brave, Chrome, and Chromium -- they all use Ctrl+L
# to focus the address bar, so the same keystroke sequence covers all
# four; only the window-class detection differs per browser.
#
# Meant to be bound to a keyboard shortcut, e.g. in XFCE:
#   Settings > Keyboard > Application Shortcuts > Add
#   Command: /path/to/grab_active_url.sh
#
# Requires: xdotool, xclip

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARE_SCRIPT="$SCRIPT_DIR/share_to_browser.sh"

for dep in xdotool xclip; do
    command -v "$dep" >/dev/null 2>&1 || {
        echo "Missing dependency: $dep" >&2
        zenity --error --text="Missing dependency: $dep" 2>/dev/null || true
        exit 1
    }
done

WIN_ID="$(xdotool getactivewindow)"
WIN_CLASS="$(xdotool getwindowclassname "$WIN_ID" 2>/dev/null || echo "")"

# Identify which supported browser (if any) the active window belongs to.
# xdotool getwindowclassname returns the WM_CLASS "class" component, which
# varies by browser and sometimes by distro packaging -- match broadly.
BROWSER_NAME=""
case "$WIN_CLASS" in
    *[Ff]irefox*|*[Nn]avigator*)        BROWSER_NAME="Firefox" ;;
    *[Bb]rave*)                         BROWSER_NAME="Brave" ;;
    *[Cc]hromium*)                      BROWSER_NAME="Chromium" ;;
    *[Gg]oogle-chrome*|*[Cc]hrome*)     BROWSER_NAME="Chrome" ;;
    *)
        zenity --error --text="Active window doesn't look like a supported browser (class: $WIN_CLASS)." 2>/dev/null || true
        exit 1
        ;;
esac

# Preserve whatever's currently on the clipboard so we can restore it.
OLD_CLIP="$(xclip -selection clipboard -o 2>/dev/null || true)"

# Focus the address bar, select all, copy -- then leave without navigating.
xdotool windowactivate --sync "$WIN_ID"
sleep 0.2

xdotool key ctrl+l
sleep 0.2
xdotool key ctrl+a
sleep 0.1
xdotool key ctrl+c
sleep 0.5
xdotool key Escape

URL="$(xclip -selection clipboard -o 2>/dev/null || true)"

# Restore the original clipboard contents.
printf '%s' "$OLD_CLIP" | xclip -selection clipboard

if [[ -z "$URL" || "$URL" != http* ]]; then
    zenity --error --text="Could not read a URL from the $BROWSER_NAME address bar." 2>/dev/null || true
    exit 1
fi

exec "$SHARE_SCRIPT" "$URL"

## Acknowledgements

This project was developed with the assistance of [Claude](https://claude.ai) by [Anthropic](https://www.anthropic.com).
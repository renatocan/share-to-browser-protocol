# Share to Browser (protocol handler, no extension)

Lets you pick a target browser (via a `zenity` list) for the current page
from Firefox, Chrome, or Brave -- with **no browser extension installed in
any of them**. It works by registering a custom URI scheme,
`share-to-browser://`, with the desktop environment (the same mechanism
tools like Emacs' `org-protocol://` use).

## How it fits together

```
Bookmarklet (any browser)
  --> location.href = 'share-to-browser://open?url=<encoded current URL>'
  --> OS looks up the registered handler for that scheme
  --> share_to_browser_handler.py  (parses the URI)
  --> share_to_browser.sh          (zenity picker)
  --> chosen browser launches with the URL
```

Because the handler is registered once at the OS/desktop level (via
`xdg-mime`), every browser that hands off unknown URI schemes to the
system (Firefox, Chrome, and Brave all do this on Linux) can trigger it
with the exact same bookmarklet.

## Requirements

- `zenity`
- `xdg-utils` (provides `xdg-mime`, `update-desktop-database` -- almost
  always already installed on a normal desktop Linux system)
- Python 3

On Arch Linux:

```sh
sudo pacman -S zenity xdg-utils
```

## Install

```sh
./install.sh
```

This copies `share_to_browser_handler.py` and `share_to_browser.sh` to
`~/.local/share/share-to-browser/`, registers a `.desktop` entry at
`~/.local/share/applications/share-to-browser.desktop`, and sets it as
the default handler for `x-scheme-handler/share-to-browser`.

## Add the bookmarklet

Same code works in all three browsers:

```
javascript:location.href='share-to-browser://open?url='+encodeURIComponent(location.href)
```

- **Firefox** -- right-click the bookmarks toolbar -> *New Bookmark...* ->
  paste as the Location/URL.
- **Chrome / Brave** -- open the Bookmark Manager (`Ctrl+Shift+O`), use its
  "Add new bookmark" option, paste as the URL.

Click it on any page, and you'll get a one-time per-browser confirmation
dialog ("Open share-to-browser link?" / "Launch Application?") before the
zenity list appears. You can tell the browser to remember your choice so
it stops asking.

## Configuring the browser list

Uses the same config file as the original native-messaging project, so if
you already set one up it's reused automatically:

```
${XDG_CONFIG_HOME:-$HOME/.config}/share-to-other-browser/browsers.conf
```

Format: `Display Name|command %u`, one per line. Auto-generated on first
use by probing `$PATH` for common browsers if the file doesn't exist yet.

## Testing without a browser

```sh
xdg-open 'share-to-browser://open?url=https://example.com'
```

Or skip the URI-scheme layer entirely and call the script directly:

```sh
~/.local/share/share-to-browser/share_to_browser.sh 'https://example.com'
```

## Triggering it from a keyboard shortcut instead of a bookmarklet

`grab_active_url.sh` reads the URL out of the currently focused
browser window's address bar (via simulated keystrokes + clipboard) and
feeds it straight to `share_to_browser.sh` -- no click on a bookmark
required. Works with Firefox, Brave, Chrome, and Chromium: all four use
Ctrl+L to focus the address bar, so the same keystroke sequence covers
every one of them -- only the window-class detection differs per
browser, and the script identifies whichever is active automatically.

Requires `xdotool` and `xclip`:

```sh
sudo pacman -S xdotool xclip
```

Bind it to a shortcut, e.g. in XFCE: *Settings > Keyboard > Application
Shortcuts > Add*, with the command set to:

```
~/.local/share/share-to-browser/grab_active_url.sh
```

(after running `install.sh`, which copies it alongside the other
scripts). Focus a Firefox window, hit the shortcut, and the zenity
picker appears with that tab's URL -- no bookmarklet, no browser
interaction beyond having the tab focused.

Note: this relies on X11 keystroke simulation (`xdotool`), so it won't
work under native Wayland without an XWayland-compatible substitute
(e.g. `wtype`/`ydotool`), and it temporarily overwrites and restores your
clipboard.

Check `xdg-mime query default x-scheme-handler/share-to-browser` if
nothing happens -- it should print `share-to-browser.desktop`.

## Troubleshooting

- **Nothing happens on click** -- check
  `~/.cache/share-to-browser/handler.log`. If it's empty, the scheme
  isn't reaching the handler at all; re-run
  `xdg-mime default share-to-browser.desktop x-scheme-handler/share-to-browser`
  and confirm with `xdg-mime query default x-scheme-handler/share-to-browser`.
- **Browser shows "no application found"** -- run
  `update-desktop-database ~/.local/share/applications` again, some
  desktop environments cache the mimeinfo database.
- **Works from Firefox but not Chrome/Brave** -- Chromium-based browsers
  sandbox external protocol launches slightly differently; make sure
  you're not running Brave as a Flatpak/Snap (sandboxed installs can't
  see `~/.local/share/applications` the same way -- check your Brave
  install type if this happens).

## A note on the security model

Any web page -- not just your bookmarklet -- can technically link to
`share-to-browser://...` and trigger this flow. This is the same
inherent tradeoff as `org-protocol://` or any other custom URI scheme.
Browsers mitigate this with the confirmation prompt shown the first time
(and on Chrome/Brave, per-origin permission after that); it's still worth
not blanket-approving "always allow" if you're not confident about a
site.

## File layout

```
share-to-browser-protocol/
├── install.sh
├── README.md
├── share-to-browser.desktop
├── share_to_browser_handler.py
└── share_to_browser.sh
```

## Acknowledgements

This project was developed with the assistance of [Claude](https://claude.ai) by [Anthropic](https://www.anthropic.com).
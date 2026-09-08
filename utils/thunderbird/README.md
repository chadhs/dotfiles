# Thunderbird

Solarized Light and Dark that follow system appearance, a three-pane reading
layout, and keyboard folder filing. The theme is a standard static theme with
both palettes in one manifest. A small UI-only CSS layer finishes the message
list, compact header, and remote-content notice. No background process is needed.

`deploy.sh` installs Thunderbird on Arch and deploys the Omarchy keybindings.
Account setup, theme installation, and extension configuration are explicit
one-time steps. Normal dotfiles deployment does not rewrite a mail profile.

## Install and connect

On an existing Omarchy install:

```sh
omarchy pkg add thunderbird
thunderbird
```

Add the mail account in Thunderbird. For iCloud, enter the Apple app-specific
password directly into the application. Keep credentials and account data out
of this repository.

Apple documents the [current IMAP and SMTP settings](https://support.apple.com/en-us/102525).
Incoming mail uses `imap.mail.me.com`, port 993, SSL/TLS. Outgoing mail uses
`smtp.mail.me.com`, port 587, STARTTLS and authentication. SMTP uses the full
iCloud login address. Configure aliases and custom-domain sender identities
separately from the login username when needed.

## Discover the correct folders first

Before configuring archive or sent-mail storage, confirm the folder list
against iCloud Mail on the web. In **Account Settings → Server Settings →
Advanced**, clear **Show only subscribed folders** if server folders are
missing, then restart Thunderbird to refresh discovery. This was necessary
to reveal iCloud's Archive and other special folders on the initial setup.
Waiting for message bodies to download does not fix that filter.

These were the server folder names on the verified setup:

| Purpose | IMAP folder |
| --- | --- |
| Archive | `Archive` |
| Sent | `Sent Messages` |
| Trash | `Deleted Messages` |
| Drafts | `Drafts` |

Confirm these for each account by comparing counts and recent messages with
webmail. A folder's label alone is not sufficient, particularly when old mail
clients have left similarly named folders. Thunderbird may display `Archive`
as **Archives**. Preserve unrelated custom folders such as a separate `Trash`.

In **Copies & Folders**, choose the existing server folders using **Other**
when needed. In **Archive options**, choose a single folder and turn off
preserving the original folder structure. In **Server Settings**, choose the
server's actual trash folder for deleted messages. Close Account Settings
after making changes so an old open editor cannot overwrite later changes.

## Install the adaptive theme

From the repository root:

```sh
python3 utils/thunderbird/build-theme.py
```

In Thunderbird, open **Add-ons and Themes → Tools for all add-ons → Install
Add-on From File**. Select `utils/thunderbird/build/solarized-omarchy.xpi` and
enable **Solarized for Omarchy**.

The package uses the tracked manifest as its only input, so building does not
depend on a particular machine's Omarchy theme directory. The light palette
uses `#fdf6e3` and `#657b83`; the dark palette uses `#002b36` and `#839496`.
Both use Solarized blue accents. Omarchy's scheduled or manual appearance
changes also change Thunderbird's palette.

### Install the UI refinements

Find the active **Profile Folder** under **Help → Troubleshooting Information**.
Close Thunderbird, then run the following with that profile's path:

```sh
python3 utils/thunderbird/install-style.py --profile "$HOME/.thunderbird/xxxxxxxx.default-release"
```

The installer checks that Thunderbird is closed and backs up the affected
files inside the profile's `solarized-style-backups` directory. It preserves
existing CSS and adds an import of `chrome/solarized-ui.css` to `userChrome.css`
and `userContent.css`. The stylesheet targets only Thunderbird's main window,
`about:3pane`, and `about:message`; sender message documents are excluded.

It also selects two-line cards, sets initial folder/reader pane widths to
230/540 pixels, and uses Thunderbird's built-in icon-only message-header
controls. Pane widths remain adjustable by dragging the splitters. The
Quick Move control remains with the icon-only message actions so its keyboard
picker has a visible anchor. The duplicate top-toolbar control is removed
through Thunderbird's native toolbar configuration. Keyboard shortcuts remain
available.

The remote-content notice uses muted amber while retaining its text,
Preferences menu, and close control. Other warnings and errors keep their
native severity colors. Sender HTML colors and remote-image blocking remain
unchanged.

Run the installer explicitly after changing the stylesheet; it copies the
new CSS and reapplies these layout defaults. Normal dotfiles deployment does
not modify the profile. CSS selectors may need attention after major
Thunderbird updates because [userChrome customizations are unsupported](https://support.mozilla.org/en-US/kb/userchromecss-js-usercontent-unsupported).

## Reading preferences

Use vertical layout, Cards View with two lines per card, default density,
and the reading pane. Hide the Today pane using its toggle.

[`preferences.json`](preferences.json) records the exact portable preferences
for this setup. Set them through Thunderbird's normal appearance settings or
**Settings → General → Config Editor**. They are a reference, not a profile
to symlink or a file that deployment applies automatically.

`mail.dark-reader.enabled = false` preserves the sender's HTML colors instead
of automatically converting message bodies to dark colors. Keep remote-image
blocking enabled. The default-client preference only suppresses the prompt;
it does not change the OS mail handler. Archive defaults do not replace
per-account folder verification.

## Keyboard setup

Install the official add-ons:

- [Quick Folder Move](https://addons.thunderbird.net/thunderbird/addon/quick-folder-move/), ID `quickmove@mozilla.kewis.ch`.
- [tbkeys-lite](https://addons.thunderbird.net/thunderbird/addon/tbkeys-lite/), ID `tbkeys-lite@addons.thunderbird.net`.

The initial setup used Quick Folder Move 3.3.0 and tbkeys-lite 2.4.4 with
Thunderbird 153.0.2. Check the published compatibility range when installing
on another version. Both add-ons use Thunderbird experiment APIs and request
full access to Thunderbird and the computer. Review that permission when
installing; let Thunderbird manage their updates.

In tbkeys-lite's preferences, replace **Main key bindings** with:

```json
{"ctrl+alt+shift+e":"cmd:cmd_archive","backspace":"cmd:cmd_delete"}
```

Set **Compose key bindings** to `{}` and save. Reopen the preferences to check
that the values persisted. This replaces tbkeys-lite's default Gmail-style
bindings while retaining Thunderbird's native keys. The exact two stored
values are also recorded in [`tbkeys-settings.json`](tbkeys-settings.json).

Backspace invokes Thunderbird's normal Delete command in the message list.
The add-on ignores unmodified Backspace in text-entry controls, and empty
compose bindings preserve normal editing in drafts.

Keep Quick Folder Move's move command on `Ctrl+Shift+N`. Its picker shows
recent folders initially; type to filter, press Enter to move, or Escape to
cancel.

The Thunderbird block in [`omarchy/hypr/bindings.lua`](../../omarchy/hypr/bindings.lua)
translates Super+E to the archive command chord and Ctrl+Super+M to the folder
picker chord. It runs only for the installed Thunderbird window class and
uses Omarchy's paired key-down/key-up method. After editing Hyprland bindings,
run `hyprctl reload` and `hyprctl configerrors`.

| Action | Shortcut |
| --- | --- |
| Archive selected messages | Super+E |
| Delete selected messages | Backspace |
| Open the folder picker | Ctrl+Super+M |
| Confirm / cancel folder choice | Enter / Escape |
| Star or unstar | s |
| Next / previous unread | n / p |
| Next / previous message in the list | Down / Up |

## Check after setup or upgrades

- Switch system appearance in both directions and restart Thunderbird to
  check the selected theme persists.
- Check a plain-text message, a formatted receipt, a newsletter, and an
  attachment.
- Test the two Super shortcuts with the physical keyboard, including
  multiple selection, cancelling the picker, and typing in a draft or search
  field. Other applications should be unaffected.
- Confirm archive, flags, moves, and sent copies agree with webmail. A
  self-addressed test message can verify sending without contacting anyone
  else; check that exactly one sent copy appears in the intended folder.

Local sample-message tests verified archive and folder movement during the
initial setup. Real-account sending and physical-keyboard acceptance are
separate user checks. Virtual-keyboard Super simulation did not reproduce the
physical keymap reliably, so use the actual keyboard for those checks.

## What stays local

Do not commit or symlink Thunderbird profiles, account IDs, folder URLs with
login addresses, `prefs.js`, `profiles.ini`, `logins.json`, `key4.db`, mail,
address books, calendars, caches, extension databases, backups, or screenshots.
Generated XPIs are ignored. Third-party add-on binaries remain managed by
Thunderbird.

## Undo

Remove only `@import url("solarized-ui.css");` from the profile's
`chrome/userChrome.css` and `chrome/userContent.css`, then restart Thunderbird
to remove the UI refinements. Keep any unrelated CSS. If no custom styles
remain, reset `toolkit.legacyUserProfileCustomizations.stylesheets` to false.

Enable **System theme — auto** in Add-ons and Themes to restore the default
color theme. Remove the Thunderbird shortcut block from Hyprland bindings to
remove the Super mappings, then reload and check for config errors. Restore
reading preferences through Thunderbird's settings. Avoid replacing a whole
older `prefs.js` after accounts or preferences have changed.

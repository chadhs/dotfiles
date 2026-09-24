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

It also selects three-line cards, enables dark message rendering and global
search/indexing, sets initial folder/reader pane widths to
230/540 pixels, and uses Thunderbird's built-in icon-only message-header
controls. Pane widths remain adjustable by dragging the splitters. The
Quick Move control remains with the icon-only message actions so its keyboard
picker has a visible anchor. The duplicate top-toolbar control is removed
through Thunderbird's native toolbar configuration. Keyboard shortcuts remain
available. Conversations replaces the native header, so Quick Folder Move
can open its picker in a separate window there.

The remote-content notice uses muted amber while retaining its text,
Preferences menu, and close control. Other warnings and errors keep their
native severity colors. Thunderbird handles sender HTML dark rendering;
the stylesheet does not modify message bodies. Remote-image blocking remains
unchanged.

Run the installer explicitly after changing the stylesheet; it copies the
new CSS and reapplies these layout defaults. Normal dotfiles deployment does
not modify the profile. CSS selectors may need attention after major
Thunderbird updates because [userChrome customizations are unsupported](https://support.mozilla.org/en-US/kb/userchromecss-js-usercontent-unsupported).

## Reading preferences

Use vertical layout, Cards View with three lines per card, default density,
and the reading pane. Hide the Today pane using its toggle.

[`preferences.json`](preferences.json) records the exact portable preferences
for this setup. Set them through Thunderbird's normal appearance settings or
**Settings → General → Config Editor**. They are a reference, not a profile
to symlink or a file that deployment applies automatically.

`mail.dark-reader.enabled = true` adapts message bodies when dark appearance
is active, including messages in Conversations. Keep
`mail.dark-reader.show-toggle = true` so the message-header toggle can restore
original colors when needed. Thunderbird's native toggle changes the shared
preference, so turn dark rendering back on afterward. Images and complex HTML
may still contain bright areas. Keep remote-image blocking enabled.
The default-client preference only suppresses the prompt;
it does not change the OS mail handler. Archive defaults do not replace
per-account folder verification.

### Message previews and conversations

These add-ons support Thunderbird 153 and were installed and checked on
Thunderbird 155.0. Both use experiment
APIs and request full access to Thunderbird and the computer. Keep downloaded
XPIs outside this repository.

1. Download `addon.xpi` from the published
   [Message Excerpts 0.1.4 release](https://github.com/michael-markl/message-excerpts-for-thunderbird/releases/tag/0.1.4).
   Install through **Add-ons and Themes → Tools for all add-ons → Install
   Add-on From File**. Its ID is
   `message-excerpts-for-thunderbird@michael-markl.de`. This add-on currently
   requires manual installation; check its releases for updates.
2. In Message Excerpts preferences, enable **If cards layout with three rows
   is active, place message excerpt in third row**, stored as
   `excerptInThirdRow = true`. Together with three-row Cards View this adds
   one truncated body-preview line below the subject. Three-row Cards View
   alone only rearranges metadata. Native row heights and default density
   keep scrolling aligned.
3. Install [Conversations for Thunderbird](https://addons.thunderbird.net/thunderbird/addon/gmail-conversation-view/),
   ID `gconversation@xulforum.org`. Version 4.3.12 supports Thunderbird 153.
   Set **By default, expand → All messages** (`expand_who = 3`), enable
   **Hide Quick Reply** (`hide_quick_reply = true`), and leave
   **Archive/delete behavior** unchecked (`operate_on_conversations = false`).
   Other options can retain their defaults. These settings belong to the
   extension, not Thunderbird's Config Editor. Change one option at a time,
   then reopen preferences to confirm the values persisted. In its setup
   assistant, enable indexing, the reading pane, and Inbox/Sent offline
   storage. Leave the Between column and applying a new sort order to all
   folders unchecked to retain the existing list layout.
4. In **Add-ons and Themes → Tools for all add-ons → Manage Extension
   Shortcuts**, clear Conversations' **Open the quick compose window**
   shortcut. Its default Ctrl+Shift+N conflicts with Quick Folder Move.
   Keep Quick Folder Move on Ctrl+Shift+N.
   Restart Thunderbird after installation and shortcut changes before testing
   the picker, then use Escape to cancel without moving a message.
5. Keep **Settings → General → Enable Global Search and Indexer** enabled.
   In the Inbox and actual Sent Messages folder's **Properties → General
   Information**, enable **Include messages in this folder in Global Search
   results**. Allow indexing to finish; check **Tools → Activity Manager**.
   Select an incoming message with a known sent reply and confirm both appear
   in the reading pane. Replies stay in Sent Messages; no copying into Inbox
   is necessary. Message headers and indexing determine conversation membership.

Conversations supplies its own reading-pane controls and layout. Its standard
message order is retained. The compact native header styling still applies
where Thunderbird uses its own reader.

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

Thunderbird is also tagged as a multi-tab application in
`omarchy/hypr/looknfeel.lua`. Super+W forwards Ctrl+W: an open message tab
closes while the main mail tab remains. When only the last tab is open,
Thunderbird's native behavior applies and may close the window.

After opening a folder without a selected message, press `f` to select the
first message or `n` for the first unread message, then use Up/Down. Thunderbird
153 has no preference to automatically select a message on folder entry; its
native folder-opening code scrolls without selecting.

In the native reader, `f` and `b` change messages without moving keyboard
focus out of the message body. From that pane, Shift+F6 returns to the message
list. F6 cycles forward through panes. Clicking or tabbing into the body can
move focus there. Conversations has its own controls, so check focus after
interacting with them. Keep native keys and tbkeys-lite; no script rebinding
or auto-selection add-on is needed.

| Action | Shortcut |
| --- | --- |
| Archive selected messages | Super+E |
| Delete selected messages | Backspace |
| Open the folder picker | Ctrl+Super+M |
| Confirm / cancel folder choice | Enter / Escape |
| Star or unstar | s |
| Next / previous message | f / b |
| Next / previous unread | n / p |
| Next / previous message in the list | Down / Up |
| First / last message with the list focused | Home / End |
| Scroll message; at the end, advance to next unread | Space |
| Previous / next pane; native reader back to list | Shift+F6 / F6 |
| Toggle read / unread | m |
| Toggle tags 1–5 / clear tags | 1–5 / 0 |
| Reply / reply all | Ctrl+R / Ctrl+Shift+R |
| Open selected message using Thunderbird's configured open behavior | Enter |
| Close current tab | Ctrl+W / Super+W |
| Toggle message pane | F8 |

Set **Settings → General → Reading & Display → Open messages in → A new
tab** if Enter should open a tab rather than a separate window.

Thunderbird tags and Mail.app's colored flags do not share a portable color
mapping. Thunderbird uses IMAP keywords for tags; the shared IMAP flag is
the star, `\Flagged`. Use stars for attention and IMAP folders for categories
that should agree in both clients. File messages with Quick Folder Move;
use Thunderbird tags only when cross-client color matching is unnecessary.

## Check after setup or upgrades

- Switch system appearance in both directions and restart Thunderbird to
  check the selected theme persists.
- Check a plain-text message, a formatted receipt, a newsletter, and an
  attachment. Check dark rendering and its toggle, keeping remote images blocked.
- Scroll the message list, switch folders, and resize its width. Confirm one
  preview line per card, readable selected/unread states, and no overlapping rows.
- Confirm an incoming message and its sent reply appear together after indexing.
- Test the two Super shortcuts with the physical keyboard, including
  multiple selection, cancelling the picker, and typing in a draft or search
  field. Check `f`, `n`, arrows, Shift+F6, and Super+W on a message tab.
  Other applications should be unaffected. Use local sample mail for destructive
  archive/delete checks.
- Confirm archive, flags, moves, and sent copies agree with webmail. A
  self-addressed test message can verify sending without contacting anyone
  else; check that exactly one sent copy appears in the intended folder.

Local sample-message tests verified archive and folder movement during the
initial setup. Real-account sending and physical-keyboard acceptance are
separate user checks. Virtual-keyboard Super simulation did not reproduce the
physical keymap reliably, so use the actual keyboard for those checks.

On Thunderbird 155.0, live checks verified preview truncation and row alignment
at multiple pane widths and scroll positions, light/dark switching, and an
incoming message with its sent reply expanded together. Settings survived a
restart. Injected native keys verified `f`/`b`, arrows, opening and closing a
message tab, and opening/cancelling Quick Folder Move. These do not replace
the physical Super-key checks above.

Repository checks:

```sh
python3 -B -m unittest discover -s utils/thunderbird -p 'test_*.py'
python3 -m json.tool utils/thunderbird/preferences.json >/dev/null
python3 -m json.tool utils/thunderbird/tbkeys-settings.json >/dev/null
git diff --check
hyprctl reload
hyprctl configerrors
```

## What stays local

Do not commit or symlink Thunderbird profiles, account IDs, folder URLs with
login addresses, `prefs.js`, `profiles.ini`, `logins.json`, `key4.db`, mail,
address books, calendars, caches, extension databases, backups, or screenshots.
Generated XPIs are ignored. Third-party add-on binaries remain managed by
Thunderbird.

## Undo

To undo previews and conversations, disable Message Excerpts and Conversations
in Add-ons and Themes. Restore `mail.threadpane.cardsview.rowcount = 2` and
`mail.dark-reader.enabled = false` through Config Editor. Restore the previous
dark-toggle and global-indexing settings from the installer backup if desired;
disabling Conversations does not require disabling indexing. The installer
reapplies the new reading defaults if run again.

Remove only Thunderbird's alternative from the `multi-tab` class rule in
`omarchy/hypr/looknfeel.lua` to restore its previous Super+W behavior. Reload
Hyprland and check for configuration errors.

Remove only `@import url("solarized-ui.css");` from the profile's
`chrome/userChrome.css` and `chrome/userContent.css`, then restart Thunderbird
to remove the UI refinements. Keep any unrelated CSS. If no custom styles
remain, reset `toolkit.legacyUserProfileCustomizations.stylesheets` to false.

Enable **System theme — auto** in Add-ons and Themes to restore the default
color theme. Remove the Thunderbird shortcut block from Hyprland bindings to
remove the Super mappings, then reload and check for config errors. Restore
reading preferences through Thunderbird's settings. Avoid replacing a whole
older `prefs.js` after accounts or preferences have changed.

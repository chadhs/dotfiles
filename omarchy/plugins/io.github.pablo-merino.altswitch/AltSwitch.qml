// Windows-style ALT+TAB window list.
//
// This is the display half only. All key handling and all state live in
// altswitch.lua next to this file, loaded from the Hyprland config. It owns the
// frozen window list and the cursor, and drives this panel over IPC:
//
//   omarchy-shell altswitch show '{"windows":[...],"index":1}'
//   omarchy-shell altswitch select 2
//   omarchy-shell altswitch hide
//
// The panel deliberately takes no keyboard focus: keys flow through the
// Hyprland binds in altswitch.lua, so there is exactly one place where a
// keypress can be interpreted.

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

Item {
  id: root

  property bool opened: false
  property var windows: []
  property int selectedIndex: 0

  function friendlyAppName(appClass) {
    const raw = String(appClass || "").trim()
    if (!raw) return "Unknown"

    // Window classes usually match a desktop-file id or StartupWMClass.
    // Let Quickshell resolve both before falling back to formatting the id.
    const entry = DesktopEntries.heuristicLookup(raw)
    if (entry && entry.name) return String(entry.name)

    let name = raw.replace(/^steam_app_/i, "")
    if (name.indexOf(".") !== -1) name = name.split(".").pop()
    name = name.replace(/[_-]+/g, " ").trim()
    return name.replace(/(^|\s)\S/g, function(letter) { return letter.toUpperCase() })
  }

  function show(payloadJson) {
    // Armed before anything that can throw, so a payload this panel cannot read
    // can never strand it on screen.
    watchdog.restart()

    let payload
    try {
      payload = JSON.parse(payloadJson)
    } catch (error) {
      console.warn("altswitch: unreadable payload:", error)
      root.hide()
      return
    }

    root.windows = payload.windows || []
    root.selectedIndex = payload.index || 0
    root.opened = root.windows.length > 0

    // Modifier sessions are short-lived (commit on release), so a brief
    // watchdog suffices. Sticky sessions — opened by the swipe-up gesture with
    // nothing held — sit around while the user picks, so they get longer.
    watchdog.interval = payload.sticky ? 30000 : 10000
  }

  function select(index) {
    root.selectedIndex = index
    watchdog.restart()
  }

  function hide() {
    watchdog.stop()
    root.opened = false
  }

  // A switch ends when ALT is released, which is a keybind in the Hyprland
  // config. If that release is ever missed the panel would sit on screen for
  // good, so it also gives up on its own and tells the config to reset.
  Timer {
    id: watchdog
    interval: 10000
    onTriggered: {
      root.hide()
      Quickshell.execDetached(["hyprctl", "eval", "__altswitch_cancel()"])
    }
  }

  IpcHandler {
    target: "altswitch"

    function show(payloadJson: string): string {
      root.show(payloadJson)
      return "ok"
    }

    function select(index: int): string {
      root.select(index)
      return "ok"
    }

    function hide(): string {
      root.hide()
      return "ok"
    }

    function state(): string {
      return root.opened ? "open" : "closed"
    }
  }

  // One PanelWindow per output (Variants on Quickshell.screens), matching
  // how omarchy spawns its notification popups. A single-output window is
  // dead wherever the pointer is not — on multi-monitor layouts (and worse,
  // overlapping ones) the picker would be visible on one screen while the
  // cursor's input routed elsewhere, so hover and click did nothing.
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: panel

      required property var modelData
      screen: modelData

      readonly property int rowHeight: Math.max(Style.space(34), Style.font.body + Style.spacing.controlPaddingY * 2)
      readonly property int cardWidth: Math.min(Style.space(560), panel.width - Style.gapsOut * 2)
      readonly property int maxCardHeight: panel.height - Style.gapsOut * 2

      visible: root.opened
      anchors { top: true; bottom: true; left: true; right: true }
      color: "transparent"
      WlrLayershell.namespace: "omarchy-altswitch"
      WlrLayershell.layer: WlrLayer.Overlay
      // Never grab the keyboard. A grab here can outlive the switch and leave
      // the desktop with no way to dismiss it; a purely visual surface cannot.
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore

      Rectangle {
        anchors.fill: parent
        color: Color.menu.scrim
      }

      BorderSurface {
        id: card

        width: panel.cardWidth
        // BorderSurface exposes its padding as numbers rather than insetting its
        // children, so the rows below carry the same insets by hand and the card
        // is measured to match. Filling it outright leaves dead space under the
        // last row.
        height: Math.min(
          panel.maxCardHeight,
          root.windows.length * panel.rowHeight + card.contentTopInset + card.contentBottomInset
        )
      anchors.centerIn: parent
      radius: Style.cornerRadius
      color: Color.menu.background
      borderSpec: Border.surfaceSpec("menu", "border", Color.menu.border, Math.max(1, Style.space(2)))
      padding: Style.spacing.panelPadding

      ListView {
        id: list

        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        anchors.rightMargin: card.contentRightInset
        clip: true
        interactive: false
        model: root.windows
        currentIndex: root.selectedIndex
        highlightMoveDuration: 0
        // Keep the cursor on screen when there are more windows than fit.
        preferredHighlightBegin: 0
        preferredHighlightEnd: height
        highlightRangeMode: ListView.ApplyRange

        delegate: Rectangle {
          id: row

          required property int index
          required property var modelData

          width: list.width
          height: panel.rowHeight
          radius: Style.cornerRadius
          color: index === root.selectedIndex ? Color.menu.selectedBackground : "transparent"

          // Mouse picking for sticky sessions: hover previews, click commits.
          // The click reaches the config side via `hyprctl eval`, the same
          // channel the watchdog uses for __altswitch_cancel(). Row indexes
          // here are 0-based; __altswitch_commit_at() is 1-based, hence the +1.
          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onContainsMouseChanged: if (containsMouse) root.select(row.index)
            onClicked: {
              root.select(row.index)
              Quickshell.execDetached(["hyprctl", "eval", "__altswitch_commit_at(" + (row.index + 1) + ")"])
            }
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Style.spacing.controlPaddingX
            anchors.rightMargin: Style.spacing.controlPaddingX
            spacing: Style.spacing.md

            // Workspace number, so a switch across workspaces is legible.
            Text {
              Layout.preferredWidth: Style.space(24)
              horizontalAlignment: Text.AlignRight
              text: modelData.workspace
              color: Color.menu.text
              opacity: 0.5
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.body
            }

            Text {
              Layout.preferredWidth: Style.space(88)
              Layout.maximumWidth: Style.space(88)
              elide: Text.ElideRight
              text: root.friendlyAppName(modelData.appClass)
              color: index === root.selectedIndex ? Color.menu.selectedText : Color.menu.text
              opacity: 0.7
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.body
            }

            Text {
              Layout.fillWidth: true
              elide: Text.ElideRight
              text: modelData.title
              color: index === root.selectedIndex ? Color.menu.selectedText : Color.menu.text
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.body
            }
          }
        }
      }
    }
    }
  }
}

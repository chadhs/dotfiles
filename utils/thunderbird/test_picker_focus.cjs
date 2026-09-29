const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const vm = require("node:vm");

function fixture() {
  const listeners = new Set();
  const frames = new Map();
  let frameId = 0;
  let focused = 0;
  const window = {
    closed: false,
    addEventListener: (_, listener) => listeners.add(listener),
    removeEventListener: (_, listener) => listeners.delete(listener),
    requestAnimationFrame: callback => {
      frames.set(++frameId, callback);
      return frameId;
    },
    cancelAnimationFrame: id => frames.delete(id),
  };
  const browser = {
    currentURI: { spec: "moz-extension://quickmove/popup/popup.html?action=move" },
    isConnected: true,
    focus: () => focused++,
  };
  const panel = { localName: "panel", state: "open", querySelector: () => browser };
  const sandbox = { ChromeUtils: { importESModule: () => ({
    ExtensionCommon: { ExtensionAPI: class {} },
    ExtensionParent: { GlobalManager: { getExtension: () => ({
      baseURI: { resolve: file => "moz-extension://quickmove/" + file },
    }) } },
    ExtensionSupport: {},
  }) } };
  vm.runInNewContext(fs.readFileSync(path.join(__dirname, "picker-focus/api.js"), "utf8"), sandbox);
  const api = new sandbox.folderPickerFocus();
  api.attach(window);
  return {
    api, window, browser, panel, listeners, frames,
    shown: () => { for (const listener of listeners) listener({ target: panel }); },
    flush: () => {
      const callbacks = [...frames.values()];
      frames.clear();
      for (const callback of callbacks) callback();
    },
    focused: () => focused,
  };
}

test("focuses the Quick Folder Move browser after the popup is shown", () => {
  const f = fixture();
  f.shown();
  assert.equal(f.focused(), 0);
  f.flush();
  assert.equal(f.focused(), 1);
  assert.equal(f.frames.size, 0);
});

test("does not take focus from another extension's popup", () => {
  const f = fixture();
  f.browser.currentURI.spec = "moz-extension://other/popup/popup.html?action=move";
  f.shown();
  f.flush();
  assert.equal(f.focused(), 0);
});

test("does not focus a popup closed before the next frame", () => {
  const f = fixture();
  f.shown();
  f.panel.state = "closed";
  f.flush();
  assert.equal(f.focused(), 0);
});

test("disabling removes listeners and cancels pending focus", () => {
  const f = fixture();
  f.api.attach(f.window);
  assert.equal(f.listeners.size, 1);
  f.shown();
  f.api.onShutdown();
  assert.equal(f.listeners.size, 0);
  assert.equal(f.frames.size, 0);
  f.flush();
  assert.equal(f.focused(), 0);
});

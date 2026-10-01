var { ExtensionCommon } = ChromeUtils.importESModule(
  "resource://gre/modules/ExtensionCommon.sys.mjs"
);
var { ExtensionParent } = ChromeUtils.importESModule(
  "resource://gre/modules/ExtensionParent.sys.mjs"
);
var { ExtensionSupport } = ChromeUtils.importESModule(
  "resource:///modules/ExtensionSupport.sys.mjs"
);

var folderPickerFocus = class extends ExtensionCommon.ExtensionAPI {
  windows = new Map();
  started = false;

  attach(window) {
    if (this.windows.has(window)) {
      return;
    }
    const pending = new Set();
    const onShown = event => {
      const panel = event.target;
      if (panel.localName !== "panel") {
        return;
      }
      const browser = panel.querySelector('browser[webextension-view-type="popup"]');
      const quickMove = ExtensionParent.GlobalManager.getExtension("quickmove@mozilla.kewis.ch");
      const popupURL = quickMove?.baseURI.resolve("popup/popup.html");
      if (!popupURL || browser?.currentURI?.spec.split("?")[0] !== popupURL) {
        return;
      }
      const request = window.requestAnimationFrame(() => {
        pending.delete(request);
        if (!window.closed && panel.state === "open" && browser.isConnected) {
          browser.focus();
        }
      });
      pending.add(request);
    };
    window.addEventListener("popupshown", onShown);
    this.windows.set(window, () => {
      window.removeEventListener("popupshown", onShown);
      for (const request of pending) {
        window.cancelAnimationFrame(request);
      }
    });
  }

  detach(window) {
    this.windows.get(window)?.();
    this.windows.delete(window);
  }

  onShutdown() {
    if (this.started) {
      ExtensionSupport.unregisterWindowListener(this.extension.id);
    }
    for (const window of this.windows.keys()) {
      this.detach(window);
    }
  }

  getAPI() {
    return {
      folderPickerFocus: {
        start: async () => {
          if (this.started) {
            return;
          }
          this.started = true;
          ExtensionSupport.registerWindowListener(this.extension.id, {
            chromeURLs: ["chrome://messenger/content/messenger.xhtml"],
            onLoadWindow: window => this.attach(window),
            onUnloadWindow: window => this.detach(window),
          });
        },
      },
    };
  }
};

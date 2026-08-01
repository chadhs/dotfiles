;;; early-init.el --- Early Emacs bootstrap -*- lexical-binding: t; -*-

;; Runs before package/UI init (Emacs 27+). Keep this file small and side-effect light.

;; Defer package.el until the literate config initializes it.
(setq package-enable-at-startup nil)

;; Raise GC threshold during startup; restored in emacs-config.org after load.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; Avoid expensive file-name-handler regex work while loading.
(defvar cs--file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)

;; Hide chrome before the first frame is drawn (GUI).
(setq frame-inhibit-implied-resize t)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

(provide 'early-init)
;;; early-init.el ends here

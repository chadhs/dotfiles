;;; emacs config bootstrap -*- lexical-binding: t -*-

;; Follow the existing Unix init symlink or the Windows redirector to the source.
(defvar cs/editor-directory
  (file-name-directory (file-truename (or load-file-name buffer-file-name))))
(add-to-list 'load-path (expand-file-name "emacs.d/lisp" cs/editor-directory))
(require 'cs-platform)
(setq package-enable-at-startup nil)

;; prevent emacs from saving customizations to this file
(setq custom-file (expand-file-name ".emacs-customize.el" user-emacs-directory))

;; always follow the emacs-config.org symlink without prompting
(setq vc-follow-symlinks t)

;; Tangle outside the checkout. Never remove another Emacs process's output.
(require 'org)
(require 'ob-tangle)
(defvar cs/tangled-config-file (cs/state-path "generated/emacs-config.el"))
(cs/state-directory "generated")
(when (or (not (file-exists-p cs/tangled-config-file))
          (file-newer-than-file-p cs/config-org-file cs/tangled-config-file))
  (org-babel-tangle-file cs/config-org-file cs/tangled-config-file "emacs-lisp\\|elisp"))
(load cs/tangled-config-file nil nil t)

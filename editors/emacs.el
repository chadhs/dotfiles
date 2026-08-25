;;; emacs config bootstrap -*- lexical-binding: t -*-

;; prevent emacs from automatically adding a package section to this file
;(package-initialize)

;; prevent emacs from saving customizations to this file
(setq custom-file (expand-file-name ".emacs-customize.el" user-emacs-directory))

;; always follow the emacs-config.org symlink without prompting
(setq vc-follow-symlinks t)

;; load the fully documented emacs-config.org configuration
(org-babel-load-file (expand-file-name "emacs-config.org" user-emacs-directory))

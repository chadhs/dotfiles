;;; emacs config bootstrap

;; prevent emacs from automatically adding a package section to this file
;(package-initialize)

;; prevent emacs from saving customizations to this file
(setq custom-file (concat user-emacs-directory ".emacs-customize.el"))

;; always follow the emacs-config.org symlink without prompting
(setq vc-follow-symlinks t)

;; load the fully documented emacs-config.org configuration
(org-babel-load-file "~/.emacs.d/emacs-config.org")
;(org-babel-load-file "~/.emacs.d/emacs-config-up.org")

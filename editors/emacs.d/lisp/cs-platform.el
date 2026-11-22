;;; cs-platform.el --- Paths and OS integration for the shared config -*- lexical-binding: t -*-

;;; Code:
(require 'cl-lib)
(require 'subr-x)

(defvar cs/editor-directory
  (file-name-as-directory
   (expand-file-name "../.." (file-name-directory (file-truename (or load-file-name buffer-file-name))))))
(defvar cs/dotfiles-root (file-name-directory (directory-file-name cs/editor-directory)))
(defvar cs/config-org-file (expand-file-name "emacs-config.org" cs/editor-directory))
(defvar cs/personal-home (expand-file-name "~"))
(defvar cs/source-directory nil)
(defvar cs/default-font (if (eq system-type 'darwin) "Menlo" "JetBrainsMono Nerd Font"))
(defvar cs/default-font-height (if (eq system-type 'darwin) 140 100))
(defvar cs/terminal-toggle-function #'cs/unix-terminal-toggle)
(defvar cs/terminal-new-function #'cs/unix-terminal-new)
(defvar cs/project-ruby-command
  (list (expand-file-name "utils/project-ruby-exec" cs/dotfiles-root)))
(defvar cs/auto-install-grammars t)
(defvar cs/node-executable-suffix "")

(defun cs/state-path (name)
  "Return a writable local state path for NAME."
  (expand-file-name name user-emacs-directory))

(defun cs/state-directory (name)
  "Create and return the local state directory NAME."
  (let ((directory (file-name-as-directory (cs/state-path name))))
    (make-directory directory t)
    directory))

(defun cs/personal-path (name)
  "Resolve NAME under the personal home, not Emacs's platform-specific home."
  (expand-file-name name cs/personal-home))

(defun cs/node-tool (name &optional start)
  "Find project-local NAME above START, then fall back to the editor PATH."
  (let* ((start (or start buffer-file-name default-directory))
         (relative (concat "node_modules/.bin/" name cs/node-executable-suffix))
         (root (locate-dominating-file start relative))
         (local (and root (expand-file-name relative root))))
    (or (and local (file-executable-p local) local)
        (executable-find (concat name cs/node-executable-suffix)))))

(defun cs/ruby-available-p ()
  "Return non-nil when the configured Ruby launcher and runtime are available."
  (executable-find (car cs/project-ruby-command)))

(defun cs/unix-terminal-toggle ()
  "Toggle the dedicated Unix terminal."
  (interactive)
  (multi-term-dedicated-toggle)
  (when (multi-term-dedicated-exist-p)
    (multi-term-dedicated-select)))

(defun cs/unix-terminal-new ()
  "Open a Unix terminal for the current perspective."
  (interactive)
  (setq-default multi-term-buffer-name (concat "term-" (persp-name (persp-curr))))
  (multi-term))

(defun cs/terminal-toggle ()
  "Toggle the platform's dedicated shell window."
  (interactive)
  (funcall cs/terminal-toggle-function))

(defun cs/terminal-new ()
  "Open a new platform shell."
  (interactive)
  (funcall cs/terminal-new-function))

(defun cs/ensure-grammars ()
  "Install configured grammars when a compiler is available."
  (interactive)
  (if (and (fboundp 'treesit-available-p) (treesit-available-p)
           (executable-find "git")
           (cl-some #'executable-find '("cc" "gcc" "c99")))
      (dolist (recipe treesit-language-source-alist)
        (unless (treesit-language-available-p (car recipe))
          (condition-case err
              (treesit-install-language-grammar (car recipe))
            (error (display-warning 'cs-platform (error-message-string err))))))
    (message "Grammar installation needs Tree-sitter support, Git, and a C compiler")))

(defun cs/javascript-mode ()
  "Use installed JavaScript grammars, otherwise keep plain JS editing."
  (interactive)
  (require 'js)
  ;; Emacs 31 compiles JSDoc queries even when that secondary grammar is absent.
  (if (and (fboundp 'treesit-ready-p)
           (treesit-ready-p (if (fboundp 'treesit-ensure-installed)
                                '(javascript jsdoc)
                              'javascript)
                            t))
      (js-ts-mode)
    (js-mode)))

(defun cs/typescript-mode ()
  "Use the TypeScript grammar when installed, otherwise use JS syntax."
  (interactive)
  (if (and (fboundp 'treesit-ready-p) (treesit-ready-p 'typescript t))
      (typescript-ts-mode)
    (js-mode)))

(defun cs/tsx-mode ()
  "Use the TSX grammar when installed, otherwise use web-mode."
  (interactive)
  (if (and (fboundp 'treesit-ready-p) (treesit-ready-p 'tsx t))
      (tsx-ts-mode)
    (web-mode)))

(when (eq system-type 'windows-nt)
  (load (expand-file-name "windows/emacs/platform.el" cs/dotfiles-root) nil nil t))

(setq cs/source-directory (or (getenv "DOTFILES_SRC") cs/source-directory (cs/personal-path "src")))
(defvar cs/notes-directory (or (getenv "DOTFILES_NOTES") (cs/personal-path "notes")))
(defvar cs/org-directory (or (getenv "DOTFILES_ORG") (cs/personal-path "org")))
(defvar cs/local-config-file (cs/state-path "local.el"))
(when (file-readable-p cs/local-config-file)
  (load cs/local-config-file nil nil t))

(provide 'cs-platform)
;;; cs-platform.el ends here

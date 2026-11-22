;;; platform.el --- Native Windows integration -*- lexical-binding: t -*-

;;; Code:
(setq cs/personal-home (or (getenv "USERPROFILE") cs/personal-home)
      cs/source-directory "C:/src"
      cs/default-font "Cascadia Mono"
      cs/default-font-height 120
      cs/node-executable-suffix ".cmd"
      cs/project-ruby-command '("ruby" "-S")
      ;; Build grammars explicitly with M-x cs/ensure-grammars after setup.
      cs/auto-install-grammars nil
      cs/terminal-toggle-function #'cs/windows-terminal-toggle
      cs/terminal-new-function #'cs/windows-terminal-new)

(defvar cs/tools-directory
  (or (getenv "DOTFILES_TOOLS") (expand-file-name "dotfiles/tools" (getenv "LOCALAPPDATA"))))

(let ((file (expand-file-name "paths.json" cs/tools-directory)))
  (when (file-readable-p file)
    (require 'json)
    (let* ((data (json-parse-string (with-temp-buffer (insert-file-contents file) (buffer-string))
                                    :object-type 'alist :array-type 'list))
           (paths (alist-get 'Paths data))
           (fallback (alist-get 'FallbackPaths data)))
      (unless (and (equal (alist-get 'ManagedBy data) "chadhs/dotfiles/windows")
                   (equal (alist-get 'Version data) 1))
        (error "Run windows/deploy.ps1 to refresh tool paths"))
      (setq exec-path (append paths exec-path fallback))
      (setenv "PATH" (mapconcat #'identity (append paths (list (getenv "PATH")) fallback) path-separator)))))

;; Node searches project-local modules before these editor-local fallbacks.
(let ((modules (expand-file-name "node/node_modules" cs/tools-directory)))
  (when (file-directory-p modules)
    (setenv "NODE_PATH" (mapconcat #'identity (delq nil (list (getenv "NODE_PATH") modules)) path-separator))))

;; Keep cmdproxy for batch-file tools. Only interactive shells use PowerShell.
(setq explicit-shell-file-name (or (executable-find "pwsh") (executable-find "powershell")))
(defvar explicit-pwsh.exe-args '("-NoLogo" "-NoProfile" "-NoExit" "-Command" "-"))
(defvar explicit-powershell.exe-args '("-NoLogo" "-NoProfile" "-NoExit" "-Command" "-"))
(setq shell-file-name (expand-file-name "cmdproxy.exe" exec-directory)
      shell-command-switch "/c")
(require 'ls-lisp)
(setq ls-lisp-use-insert-directory-program nil)

(defun cs/windows-terminal-toggle ()
  "Toggle the dedicated native PowerShell buffer."
  (interactive)
  (if-let* ((window (get-buffer-window "*dotfiles-shell*")))
      (if (one-window-p) (switch-to-prev-buffer) (delete-window window))
    (require 'shell)
    (let ((display-buffer-alist
           '(("\\*dotfiles-shell\\*" (display-buffer-in-side-window)
              (side . bottom) (window-height . 0.3)))))
      (shell "*dotfiles-shell*")
      (when-let* ((window (get-buffer-window (current-buffer))))
        (select-window window)))))

(defun cs/windows-terminal-new ()
  "Open another native PowerShell buffer."
  (interactive)
  (require 'shell)
  (shell (generate-new-buffer-name "*dotfiles-shell*")))

;;; platform.el ends here

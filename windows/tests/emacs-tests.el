;;; emacs-tests.el --- Shared editor regression tests -*- lexical-binding: t -*-
(require 'ert)
(require 'cl-lib)
(defvar cs/test-root
  (expand-file-name "../.." (file-name-directory (or load-file-name buffer-file-name))))
(add-to-list 'load-path (expand-file-name "editors/emacs.d/lisp" cs/test-root))
(require 'cs-platform)

(ert-deftest cs/platform-discovers-checkout ()
  (should (file-equal-p cs/dotfiles-root cs/test-root))
  (should (file-readable-p cs/config-org-file))
  (should (file-directory-p (expand-file-name "emacs.d/snippets" cs/editor-directory))))

(ert-deftest cs/platform-state-is-local ()
  (let ((user-emacs-directory (make-temp-file "emacs state " t)))
    (unwind-protect
        (let ((state (cs/state-directory "generated")))
          (should (file-directory-p state))
          (should (file-in-directory-p state user-emacs-directory))
          (should-not (file-in-directory-p state cs/dotfiles-root)))
      (delete-directory user-emacs-directory t))))

(ert-deftest cs/platform-finds-native-node-shims ()
  (let* ((project (make-temp-file "node project " t))
         (nested (expand-file-name "src/nested" project))
         (bin (expand-file-name "node_modules/.bin" project))
         (cs/node-executable-suffix (if (eq system-type 'windows-nt) ".cmd" ""))
         (tool (expand-file-name (concat "prettier" cs/node-executable-suffix) bin)))
    (unwind-protect
        (progn
          (make-directory nested t)
          (make-directory bin t)
          (with-temp-file tool (insert "echo test\n"))
          (set-file-modes tool #o755)
          (should (equal (cs/node-tool "prettier" nested) tool)))
      (delete-directory project t))))

(ert-deftest cs/platform-missing-ruby-is-harmless ()
  (cl-letf (((symbol-function 'executable-find) (lambda (&rest _) nil)))
    (should-not (cs/ruby-available-p))))

(ert-deftest cs/platform-js-falls-back-without-grammar ()
  (require 'js)
  (cl-letf (((symbol-function 'treesit-ready-p) (lambda (&rest _) nil))
            ((symbol-function 'js-mode) (lambda () 'fallback)))
    (should (eq (cs/javascript-mode) 'fallback))
    (should (eq (cs/typescript-mode) 'fallback))))

(ert-deftest cs/platform-js-falls-back-without-secondary-grammar ()
  (skip-unless (fboundp 'treesit-ensure-installed))
  (require 'js)
  (cl-letf (((symbol-function 'treesit-ready-p)
             (lambda (languages &rest _) (not (memq 'jsdoc languages))))
            ((symbol-function 'js-mode) (lambda () 'fallback)))
    (should (eq (cs/javascript-mode) 'fallback))))

(ert-deftest cs/shared-config-tangles-outside-checkout ()
  (require 'org)
  (require 'ob-tangle)
  (let* ((state (make-temp-file "emacs tangle " t))
         (output (expand-file-name "generated.el" state)))
    (unwind-protect
        (progn
          (org-babel-tangle-file cs/config-org-file output "emacs-lisp\\|elisp")
          (should (file-exists-p output))
          (with-temp-buffer
            (insert-file-contents output)
            (emacs-lisp-mode)
            (check-parens)
            (goto-char (point-min))
            (while (< (point) (point-max))
              (forward-comment (point-max))
              (unless (eobp) (read (current-buffer))))))
      (delete-directory state t))))

(ert-deftest cs/windows-has-native-backends ()
  (skip-unless (eq system-type 'windows-nt))
  (should (equal cs/personal-home (getenv "USERPROFILE")))
  (should (equal cs/project-ruby-command '("ruby" "-S")))
  (should (equal cs/terminal-toggle-function #'cs/windows-terminal-toggle))
  (should-not cs/auto-install-grammars)
  (should (string-match-p "cmdproxy\\.exe$" shell-file-name)))

;;; emacs-tests.el ends here

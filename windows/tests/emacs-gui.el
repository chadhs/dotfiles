;;; emacs-gui.el --- Check a normal isolated GUI launch -*- lexical-binding: t -*-
;; Run after normal initialization with --init-directory pointing at test state.
(require 'cl-lib)
(require 'subr-x)

(defun cs/gui-acceptance-check ()
  "Check normal startup after Windows processes pending frame changes."
  (let* ((root (file-name-as-directory
                (or (getenv "DOTFILES_TEST_ROOT")
                    (error "Set DOTFILES_TEST_ROOT to an isolated test directory"))))
         (result (expand-file-name "emacs-gui-result.txt" root))
         checks finished clipboard-active saved-clipboard timeout)
    (cl-labels
        ((check (condition description)
           (unless condition (error "%s" description))
           (push (concat "PASS " description) checks))
         (finish (status &optional failure)
           (unless finished
             (setq finished t)
             (when timeout (cancel-timer timeout))
             (when failure (push (concat "FAIL " failure) checks))
             (when clipboard-active
               (gui-set-selection 'CLIPBOARD (or saved-clipboard "")))
             (with-temp-file result
               (insert (string-join (nreverse checks) "\n") "\n\n")
               (insert-buffer-substring "*Messages*"))
             (let ((kill-emacs-query-functions nil))
               (kill-emacs status))))
         (clipboard-command (shell command callback)
           (let ((buffer (generate-new-buffer " *dotfiles-clipboard*")))
             (make-process
              :name "dotfiles-clipboard-check"
              :buffer buffer
              :command (list shell "-NoLogo" "-NoProfile" "-NonInteractive" "-Command" command)
              :connection-type 'pipe
              :coding 'utf-8-unix
              :noquery t
              :sentinel
              (lambda (process _event)
                (when (memq (process-status process) '(exit signal))
                  (unwind-protect
                      (condition-case err
                          (with-current-buffer buffer
                            (unless (eq (process-exit-status process) 0)
                              (error "Clipboard command failed: %s" (buffer-string)))
                            (funcall callback (buffer-string)))
                        (error (finish 1 (error-message-string err))))
                    (when (buffer-live-p buffer) (kill-buffer buffer)))))))))
      (condition-case err
          (progn
            (check (display-graphic-p) "native graphical frame opens")
            (check (not init-file-had-error) "normal init completes without an error")
            (check (featurep 'cs-platform) "deployed redirector loads the shared configuration")
            (check (file-equal-p user-init-file (expand-file-name "emacs/init.el" root))
                   "startup uses the isolated deployed init")
            (check (file-in-directory-p package-user-dir (expand-file-name "emacs/" root))
                   "packages remain in isolated test state")
            (check (file-in-directory-p cs/tangled-config-file (expand-file-name "emacs/" root))
                   "generated Lisp remains in isolated test state")
            (check (bound-and-true-p global-flycheck-mode) "normal startup activates Flycheck")
            (check (cl-intersection custom-enabled-themes '(solarized-dark solarized-light))
                   "a shared Solarized theme is active")
            (check (eq auto-dark-detection-method 'winreg) "appearance detection uses the Windows registry")
            (find-file (expand-file-name "emacs project/example.ts" root))
            (check (eq major-mode 'typescript-ts-mode) "TypeScript opens in the native GUI")
            (check (bound-and-true-p highlight-indent-guides-mode) "graphical indentation guides enable")
            ;; Native Emacs returns nil for clipboard text it owns. Use another
            ;; process to read copied text and replace it before testing paste.
            ;; Return to the event loop for frame updates and delayed clipboard data.
            (setq saved-clipboard (gui-get-selection 'CLIPBOARD 'STRING)
                  clipboard-active t
                  timeout (run-at-time 20 nil (lambda () (finish 1 "Clipboard check timed out"))))
            (let ((shell (or (executable-find "pwsh")
                             (error "PowerShell 7 is required for the clipboard check"))))
              (run-with-idle-timer
               0.5 nil
               (lambda ()
                 (condition-case err
                     (progn
                       (check (gui-set-selection 'CLIPBOARD "dotfiles Windows clipboard check")
                              "native clipboard copy succeeds")
                       (clipboard-command
                        shell "[Console]::Write((Get-Clipboard -Raw))"
                        (lambda (copied)
                          (unless (equal copied "dotfiles Windows clipboard check")
                            (error "Clipboard copy mismatch: %S" copied))
                          (check t "Emacs copies text to the system clipboard")
                          (clipboard-command
                           shell "Set-Clipboard -Value 'dotfiles Windows clipboard paste check'"
                           (lambda (_output)
                             (check (equal (gui-get-selection 'CLIPBOARD 'STRING)
                                           "dotfiles Windows clipboard paste check")
                                    "Emacs pastes text from the system clipboard")
                             (finish 0))))))
                   (error (finish 1 (error-message-string err))))))))
        (error (finish 1 (error-message-string err)))))))

;; Hiding the native menu queues a frame update that must finish before copy.
(run-with-idle-timer 0.1 nil #'cs/gui-acceptance-check)

;;; emacs-gui.el ends here

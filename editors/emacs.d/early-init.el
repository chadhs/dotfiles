;;; early-init.el --- Early Emacs settings -*- lexical-binding: t; -*-

;; Bundled libgccjit 14.3 maps macOS 27 to a deployment target Clang rejects.
;; Set the native compiler's target before Emacs activates packages.
;; https://github.com/jimeh/emacs-builds/issues/71
(when (and (eq system-type 'darwin)
           (fboundp 'native-comp-available-p)
           (native-comp-available-p)
           (member (getenv "MACOSX_DEPLOYMENT_TARGET") '(nil ""))
           (with-temp-buffer
             (and (eq 0 (call-process "/usr/bin/sw_vers" nil t nil "-productVersion"))
                  (string-prefix-p "27." (buffer-string)))))
  (require 'comp)
  (when (and (fboundp 'comp-libgccjit-version)
             (equal (comp-libgccjit-version) '(14 3 0))
             (not (seq-some (lambda (option)
                             (string-prefix-p "-mmacosx-version-min=" option))
                           native-comp-driver-options)))
    (add-to-list 'native-comp-driver-options "-mmacosx-version-min=27.0")))

;;; early-init.el ends here

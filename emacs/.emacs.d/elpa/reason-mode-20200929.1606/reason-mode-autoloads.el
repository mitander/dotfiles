;;; reason-mode-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "reason-indent" "reason-indent.el" (0 0 0 0))
;;; Generated autoloads from reason-indent.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "reason-indent" '("reason-")))

;;;***

;;;### (autoloads nil "reason-interaction" "reason-interaction.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from reason-interaction.el

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "reason-interaction" '("reason-")))

;;;***

;;;### (autoloads nil "reason-mode" "reason-mode.el" (0 0 0 0))
;;; Generated autoloads from reason-mode.el

(autoload 'reason-mode "reason-mode" "\
Major mode for Reason code.

\\{reason-mode-map}

\(fn)" t nil)

(add-to-list 'auto-mode-alist '("\\.\\(resi?\\|rei?\\)$" . reason-mode))

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "reason-mode" '("reason-")))

;;;***

;;;### (autoloads nil "refmt" "refmt.el" (0 0 0 0))
;;; Generated autoloads from refmt.el

(autoload 'refmt-before-save "refmt" "\
Add this to .emacs to run refmt on the current buffer when saving:
 (add-hook 'before-save-hook 'refmt-before-save)." t nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "refmt" '("apply-refmt" "reason--" "refmt")))

;;;***

;;;### (autoloads nil nil ("reason-mode-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; reason-mode-autoloads.el ends here

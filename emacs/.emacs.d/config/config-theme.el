;; Disable bars
(when (functionp 'menu-bar-mode)
  (menu-bar-mode -1))
(when (functionp 'set-scroll-bar-mode)
  (set-scroll-bar-mode 'nil))
(when (functionp 'mouse-wheel-mode)
  (mouse-wheel-mode -1))
(when (functionp 'tooltip-mode)
  (tooltip-mode -1))
(when (functionp 'tool-bar-mode)
  (tool-bar-mode -1))
(when (functionp 'blink-cursor-mode)
  (blink-cursor-mode -1))

;; Theme
(use-package solarized-theme :config (load-theme 'solarized-gruvbox-dark t))

;; Fancy mode line
(use-package smart-mode-line
  :demand t
  :config
  (progn
    (setq sml/no-confirm-load-theme t)
    (setq sml/theme 'dark)
    (sml/setup)
    (set-face-attribute 'mode-line nil
                        :underline nil)
    (set-face-attribute 'mode-line-inactive nil
                        :underline nil
                        :overline nil)
    (set-face-attribute 'header-line nil
                        :box nil
                        :underline nil)))

(if (window-system)
    (progn
      (add-hook 'prog-mode-hook 'linum-mode)   ;; Show line numbers
      (sml/apply-theme 'automatic)             ;; Change status bar theme
      (setq confirm-kill-emacs 'yes-or-no-p)   ;; Confirm before exiting
      (setq ns-use-native-fullscreen nil)      ;; Use "windowed" fullscreen instead of normal fullscreen
      (toggle-frame-maximized)
    )
)

;; Eshell command prompt customizations
(custom-set-faces
 '(epe-dir-face ((t (:inherit eshell-prompt))))
 '(epe-symbol-face ((t (:inherit eshell-ls-symlink)))))

(provide 'config-theme)

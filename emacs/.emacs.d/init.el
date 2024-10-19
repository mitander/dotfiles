;; optimize startup
(setq package-enable-at-startup nil
      package--init-file-ensured t)
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6
      file-name-handler-alist-original file-name-handler-alist
      file-name-handler-alist nil
      frame-inhibit-implied-resize t)
(add-hook 'after-init-hook (lambda ()
    (setq file-name-handler-alist file-name-handler-alist-original)
    (makunbound 'file-name-handler-alist-original)))
(add-hook 'focus-out-hook (lambda ()
  (setq gc-cons-threshold (* 1024 1024 16) ; 16mb
        gc-cons-percentage 0.1)
  (garbage-collect)))
(run-with-idle-timer 5 nil
  (lambda ()
    (setq gc-cons-threshold (* 1024 1024 16) ; 16mb
          gc-cons-percentage 0.1)))

;; disable startup warnings and message buffer
(setq warning-minimum-level :emergency)
(setq-default message-log-max nil)
(add-hook 'emacs-startup-hook (lambda ()
  (kill-buffer (get-buffer "*Messages*"))))

;; kill help buffer after :q
(advice-add #'evil-quit :after (lambda (&rest r)
  (let ((buf (get-buffer "*Help*")))
    (if (eq buf nil) nil
      (kill-buffer buf)))))

;; hide bars
(tool-bar-mode 0)
(menu-bar-mode 0)
(scroll-bar-mode 0)

;; prevent file litter
(setq make-backup-files nil
      auto-save-default nil
      create-lockfiles nil
      custom-file (concat user-emacs-directory "trash.el"))

;; better scrolling
(setq-default pixel-scroll-precision-mode t
              fast-but-imprecise-scrolling t
              mouse-wheel-scroll-amount '(1 ((shift) . 1))
              mouse-wheel-progressive-speed nil
              mouse-wheel-follow-mouse t
              mouse-wheel-tilt-scroll t
              scroll-margin 7
              scroll-preserve-screen-position t
              scroll-conservatively 10)

;; font
(set-frame-font "JetBrains Mono 18" nil t);
(setq-default line-spacing 0.10)
(set-language-environment "UTF-8")

;; melpa
(require 'package)
(setq package-check-signature nil)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)
(require 'use-package)
(setq use-package-always-ensure t)
(unless package-archive-contents
  (progn
    (setq warning-minimum-level :emergency) 
    (package-refresh-contents)))

;; theme
(use-package base16-theme
  :ensure t
  :config
  (load-theme 'base16-atelier-sulphurpool-light :no-confirm))

;; xterm
(unless (display-graphic-p)
  (xterm-mouse-mode 1)
  (setq xterm-extra-capabilities '(getSelection setSelection)))

;; misc settings
(electric-pair-mode 1)
(save-place-mode)
(electric-indent-mode t)
(global-display-line-numbers-mode 1)
(global-prettify-symbols-mode)

(setq blink-cursor-mode nil
  use-short-answers t
  comment-empty-lines t
  display-line-numbers-type t
  frame-resize-pixelwise t)

(setq-default tab-width 2
  indent-tabs-mode nil
  truncate-lines t)

(use-package general
  :config
    (general-define-key 
      :keymaps 'indent-rigidly-map
        "TAB" #'indent-rigidly-right-to-tab-stop
        "<tab>" #'indent-rigidly-right-to-tab-stop
        "DEL" #'indent-rigidly-left-to-tab-stop
        "<backtab>" #'indent-rigidly-left-to-tab-stop
        "h" #'indent-rigidly-left
        "l" #'indent-rigidly-right)
    (general-define-key
      :states '(normal emacs)
      :keymaps 'minibuffer-local-map
          "ESC" #'keyboard-escape-quit
          "<escape>" #'keyboard-escape-quit)
    (general-create-definer leader
      :states '(normal insert visual emacs motion)
      :keymaps 'override
      :prefix "SPC"
      :global-prefix "M-SPC")
    (leader
      "b k" '((lambda () (interactive) (kill-buffer (current-buffer))) :wk "Kill buffer")
      "b r" '(revert-buffer :wk "Reload buffer"))
    (leader
      "e" '(:ignore t :wk "Evaluate")    
      "e b" '(eval-buffer :wk "Evaluate buffer")
      "e e" '(eval-expression :wk "Evaluate expression")
      "e r" '(eval-region :wk "Evaluate selected region")) 
    (leader
      "h" '(:ignore t :wk "Help")
      "h f" '(describe-function :wk "Help function")
      "h v" '(describe-variable :wk "Help variable")
      "h m" '(describe-mode :wk "Help mode")
      "h c" '(describe-char :wk "Help character")
      "h k" '(describe-key :wk "Help key/keybind"))
    (leader
      "/" '(comment-line :wk "Comment selection"))
    (leader
      "f f" '(find-file :wk "Find File"))
    (leader
      "i r" '(indent-rigidly :wk "Indent Rigidly")))


(use-package evil
  :general
    (:states 'insert
      "<tab>" #'tab-to-tab-stop
      "TAB" #'tab-to-tab-stop)
    (:states '(normal insert visual emacs)
      "C-u" #'evil-scroll-up
      "C-d" #'evil-scroll-down)
    (:states '(normal emacs)
      "u" #'undo-tree-undo
      "C-r" #'undo-tree-redo)
  :init      
    (setq evil-want-integration t 
          evil-want-keybinding nil
          evil-vsplit-window-right t
          evil-split-window-below t
          evil-shift-width 4)
    (evil-mode)
  :config
    (evil-ex-define-cmd "q" 'kill-this-buffer)
    (evil-ex-define-cmd "quit" 'evil-quit)
    (unless (display-graphic-p)
      (add-hook 'post-command-hook (lambda ()
        (setq visible-cursor nil) 
        (if (eq evil-state 'insert)
          ;; These hooks may not work if TERM isnt xterm/xterm256
          ;; Let cursor change based on mode when using emacs in the terminal
          (send-string-to-terminal "\e[5 q")
          (send-string-to-terminal "\e[2 q"))))))

(use-package evil-collection
  :after evil
  :ensure t
  :config
  (evil-collection-init))

(setq eglot-events-buffer-size 0)
(with-eval-after-load 'eglot
  (mapc (lambda (server-remap) (add-to-list 'eglot-server-programs server-remap))
    '(((java-ts-mode java-mode) . ("java-language-server"))
      ((nix-ts-mode nix-mode) . ("nixd")))))

(add-hook 'find-file-hook (lambda ()
  (unless (file-remote-p (buffer-file-name)) 
    (when (member major-mode 
      '(go-ts-mode python-ts-mode js-ts-mode
        typescript-ts-mode rust-ts-mode elixir-ts-mode c-ts-mode
        bash-ts-mode)) (eglot-ensure)))))

(use-package which-key
  :config
    (which-key-mode 1)
    (setq which-key-side-window-location 'bottom
      which-key-sort-order #'which-key-key-order-alpha
      which-key-sort-uppercase-first nil
      which-key-add-column-padding 1
      which-key-max-display-columns nil
      which-key-min-display-lines 6
      which-key-side-window-slot -10
      which-key-side-window-max-height 0.25
      which-key-idle-delay 0.8
      which-key-max-description-length 25
      which-key-allow-imprecise-window-fit t
      which-key-separator " → " ))

(use-package undo-tree
  :hook (after-init . (lambda () (add-hook 'find-file-hook #'global-undo-tree-mode)))
  :config
    (setq undo-tree-auto-save-history t)
    (setq undo-tree-history-directory-alist `(("." . ,(concat user-emacs-directory "undo")))))

(use-package envrc
  :hook (after-init . (lambda () (add-hook 'find-file-hook #'envrc-global-mode)))
  :config
    (envrc-global-mode 1))

(use-package git-gutter
  :hook (after-init . (lambda () (add-hook 'find-file-hook (lambda ()
    (unless (file-remote-p default-directory)
      (git-gutter-mode 1)))))))


(use-package orderless
  :config
    (setq completion-styles '(orderless basic)
          completion-category-overrides '((file (styles basic partial-completion)))))

(use-package magit 
  :hook (magit-post-stage . (lambda () (message "Staged")))
  :general
    (leader
      "g s" '(magit-stage-file :wk "Stage Files")
      "g S" '(magit-stage-modified :wk "Stage All Files")
      "g u" '(magit-unstage-file :wk "Unstage Files")
      "g U" '(magit-unstage-all :wk "Unstage All Files")
      "g f" '(magit-fetch :wk "Fetch")
      "g F" '(magit-fetch-all :wk "Fetch")
      "g i" '(magit-init :wk "Init")
      "g l" '(magit-log :wk "Log")
      "g b" '(magit-branch :wk "Branch")
      "g d" '(magit-diff :wk "Diff")
      "g c" '(magit-commit :wk "Commit")
      "g r" '(magit-rebase :wk "Rebase")
      "g R" '(magit-reset :wk "Reset")
      "g p" '(magit-push :wk "Push")
      "g P" '(magit-pull :wk "Pull")
      "g m" '(magit :wk "Magit Menu")))

(use-package corfu
  :hook (after-init . (lambda () (add-hook 'find-file-hook #'global-corfu-mode)))
        (eval-expression-minibuffer-setup . corfu-mode)
        (ement-room-read-string-setup . (lambda () 
          (setq-local completion-at-point-functions 
            '(ement-room--complete-members-at-point ement-room--complete-rooms-at-point cape-emoji))
          (corfu-mode 1)))
  :general
    (:keymaps 'corfu-map :states 'insert
      "SPC" #'corfu-insert-separator
      "<tab>" #'corfu-next
      "TAB" #'corfu-next
      "<backtab>" #'corfu-previous)
  :config
    (corfu-popupinfo-mode)
    (corfu-history-mode)
    (setq corfu-auto t
          corfu-cycle t
          corfu-preselect 'prompt
          corfu-auto-delay 0.05
          corfu-auto-prefix 2
          global-corfu-minibuffer nil
          corfu-popupinfo-delay 0)
    (advice-add 'eglot-completion-at-point :around #'cape-wrap-buster)
    (advice-add #'corfu--setup :after (lambda (&rest r) (evil-normalize-keymaps)))
    (advice-add #'corfu--teardown :after (lambda (&rest r) (evil-normalize-keymaps)))
    (evil-make-overriding-map corfu-map)
    (add-hook 'evil-insert-state-exit-hook #'corfu-quit)
    (advice-add 'corfu-insert-separator :after (lambda () 
      (if (= corfu--index -1)
          (when (= corfu--total 0) 
            (corfu-quit))
          (corfu-insert)))))

(use-package corfu-terminal
  :if (not window-system)
  :after corfu
  :config
    (corfu-terminal-mode 1))

(use-package vertico
  :init
    (vertico-mode)
  :general
    (:keymaps 'vertico-map
     :states '(normal insert)
      "RET" #'vertico-directory-enter
      "<tab>" #'vertico-next
      "TAB" #'vertico-next
      "<backspace>" #'vertico-directory-delete-char
      "DEL" #'vertico-directory-delete-char
      "<backtab>" #'vertico-previous))

(use-package marginalia
  :after vertico
  :config
    (marginalia-mode))

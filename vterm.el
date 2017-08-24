;;; vterm.el --- This package implements a terminal via libvterm -*- lexical-binding: t -*-

;;; Commentary:
;;
;; This Emacs module implements a bridge to libvterm to display a terminal in a
;; Emacs buffer.

;;; Code:

(eval-when-compile
  (require 'cl-lib)
  (require 'subr-x))
(require 'vterm-module)

(defvar vterm-term nil
  "Pointer to struct Term.")
(make-variable-buffer-local 'vterm-term)

(defvar vterm-buffers nil
  "List of active vterm-buffers.")

(defvar vterm-keymap-exceptions '("C-x" "C-u" "C-g" "C-h" "M-x" "M-o")
  "Exceptions for vterm-keymap.

If you use a keybinding with a prefix-key that prefix-key cannot
be send to the terminal.")

(define-derived-mode vterm-mode fundamental-mode "VTerm"
  "Mayor mode for vterm buffer."
  (buffer-disable-undo)
  (setq vterm-term (vterm-new (window-height) (window-width))
        buffer-read-only t)
  (setq-local scroll-conservatively 101)
  (setq-local scroll-margin 0)
  (add-hook 'kill-buffer-hook #'vterm-kill-buffer-hook t t)
  (add-hook 'window-size-change-functions #'vterm-window-size-change t t))

;; Keybindings
(define-key vterm-mode-map [t] #'vterm-self-insert)
(dolist (prefix '("M-" "C-"))
  (dolist (char (cl-loop for char from ?a to ?z
                         collect char))
    (let ((key (concat prefix (char-to-string char))))
      (unless (cl-member key vterm-keymap-exceptions)
        (define-key vterm-mode-map (kbd key) #'vterm-self-insert)))))
(dolist (exception vterm-keymap-exceptions)
  (define-key vterm-mode-map (kbd exception) nil))

(defun vterm-self-insert ()
  "Sends invoking key to libvterm."
  (interactive)
  (let* ((modifiers (event-modifiers last-input-event))
         (shift (memq 'shift modifiers))
         (meta (memq 'meta modifiers))
         (ctrl (memq 'control modifiers)))
    (when-let ((key (key-description (vector (event-basic-type last-input-event))))
               (inhibit-redisplay t)
               (inhibit-read-only t))
      (when (equal modifiers '(shift))
        (setq key (upcase key)))
      (vterm-update vterm-term key shift meta ctrl))))

;;;###autoload
(defun vterm-create ()
  "Create a new vterm."
  (interactive)
  (let ((buffer (generate-new-buffer "vterm")))
    (add-to-list 'vterm-buffers buffer)
    (pop-to-buffer buffer)
    (vterm-mode)))

(defun vterm-event ()
  "Update the vterm BUFFER."
  (interactive)
  (let ((inhibit-redisplay t)
        (inhibit-read-only t))
    (mapc (lambda (buffer)
            (with-current-buffer buffer
              (unless (vterm-update vterm-term)
                (insert "\nProcess exited!\n\n"))))
          vterm-buffers)))

(define-key special-event-map [sigusr1] #'vterm-event)

(defun vterm-kill-buffer-hook ()
  "Kill the corresponding process of vterm."
  (when (eq major-mode 'vterm-mode)
    (setq vterm-buffers (remove (current-buffer) vterm-buffers))
    (vterm-kill vterm-term)))

(defun vterm-window-size-change (frame)
  "Notify the vterm over size-change in FRAME."
  (dolist (window (window-list frame 1))
    (let ((buffer (window-buffer window)))
      (with-current-buffer buffer
        (when (eq major-mode 'vterm-mode)
          (vterm-set-size vterm-term (window-height) (window-width)))))))

(provide 'vterm)
;;; vterm.el ends here

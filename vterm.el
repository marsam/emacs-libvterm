(require 'vterm-module)

(defvar vterm-vterm nil
  "Pointer to vterm struct.")
(make-variable-buffer-local 'vterm-vterm)

(defvar vterm-process nil
  "The shell process.")

(define-derived-mode vterm-mode fundamental-mode "VTerm"
  "TODO: Documentation.")

(defun vterm-create ()
  (interactive)
  (let ((buffer (generate-new-buffer "vterm")))
    (with-current-buffer buffer
      (vterm-mode)
      (setq vterm-vterm (vterm-new))
      (setq vterm-process
            (make-process :name "vterm-shell"
                          :buffer buffer
                          :command (list (getenv "SHELL"))
                          :coding 'utf-8
                          :connection-type 'pty
                          :filter #'vterm-process-filter
                          :sentinel #'vterm-process-sentinel)))
    (pop-to-buffer buffer)))

(defun vterm-process-filter (process output)
  (with-current-buffer (process-buffer process)
    (vterm-input-write vterm-vterm output)))

(defun vterm-process-sentinel (process event)
  )

(provide 'vterm)
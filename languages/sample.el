;;; sample.el --- Small helpers for the daily notes workflow  -*- lexical-binding: t; -*-

;;; Commentary:
;; Opens today's note and counts the TODO items in it.

;;; Code:
(require 'subr-x)

(defgroup daily-notes nil "Daily notes." :group 'convenience)

(defcustom daily-notes-directory (expand-file-name "~/notes/")
  "Where the notes live."
  :type 'directory)

(defun daily-notes--path (&optional time)
  "The note file for TIME (default now)."
  (expand-file-name (format-time-string "%Y-%m-%d.org" time) daily-notes-directory))

(defun daily-notes-count-todos ()
  "Count TODO headings in the current buffer."
  (interactive)
  (let ((count 0))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^\\*+ TODO " nil t)
        (setq count (1+ count))))
    (message "%d TODO item%s" count (if (= count 1) "" "s"))
    count))

;;;###autoload
(defun daily-notes-open ()
  "Open today's note, creating it if needed."
  (interactive)
  (find-file (daily-notes--path)))

(provide 'sample)
;;; sample.el ends here

;;; magit-idle-breadcrumbs.el --- Magit breadcrumbs in the header line

;; Copyright (C) 2015 David Holm

;; Author: David Holm <dholmster@gmail.com>
;; Keywords: vc tools
;; Package: magit-idle-breadcrumbs
;; Package-Requires: ((magit "1.2.0"))
;; URL: https://github.com/dholm/magit-idle-breadcrumbs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(eval-when-compile
  (require 'magit))

(defgroup magit-idle-breadcrumbs nil
  "Display Magit breadcrumbs in the header line."
  :link '(url-link "https://github.com/dholm/magit-idle-breadcrumbs")
  :prefix "magit-idle-breadcrumbs"
  :group 'magit)

(defgroup magit-idle-breadcrumbs-marks nil
  "Marks used in Magit idle breadcrumbs."
  :group 'magit-idle-breadcrumbs)

(defcustom magit-idle-breadcrumbs-modes
  '(magit-commit-mode magit-diff-mode)
  "List of major modes for which Magit Idle Breadcrumbs mode should be used.
For other modes it is disabled."
  :group 'magit-idle-breadcrumbs
  :version "24.3"
  :type '(repeat (symbol :tag "Major mode")))

(defcustom magit-idle-breadcrumbs-path-mark "\u2711"
  "*Mark used for file paths."
  :group 'magit-idle-breadcrumbs-marks
  :type 'character)

(defcustom magit-idle-breadcrumbs-location-mark "\u2316"
  "*Mark used for locations."
  :group 'magit-idle-breadcrumbs-marks
  :type 'character)

(defvar magit-idle-breadcrumbs-mode nil
  "Non-nil means display Magit breadcrumb in header line.
This makes a difference only if `magit-idle-breadcrumbs-mode' is non-nil.")
(make-variable-buffer-local 'magit-idle-breadcrumbs-mode)

(defvar magit-idle-breadcrumbs--table
  (make-hash-table :test 'eq :weakness 'key))

(defvar magit-idle-breadcrumbs--update-timer nil)

(defun magit-idle-breadcrumbs--format-header-line (string)
  "Return formatted header line containing STRING."
  (when (and string (stringp string))
    (concat " " string)))

(defun magit-idle-breadcrumbs--format-magit-diff-mode (section)
  "Return formatted string representing magit-diff-mode SECTION."
  (let ((path (magit-section-path section)))
    (mapconcat
     'identity
     (append
      (list magit-idle-breadcrumbs-path-mark (nth 0 path))
      (when (nth 1 path)
        (list magit-idle-breadcrumbs-location-mark (nth 1 path))))
     " ")))

(defun magit-idle-breadcrumbs--format-section (section)
  "Return formatted string representing SECTION."
  (cond
   ((null section)
    (propertize "<not in section>" 'face 'font-lock-comment-face))
   ((member major-mode '(magit-commit-mode magit-diff-mode))
    (magit-idle-breadcrumbs--format-magit-diff-mode section))))

(defun magit-idle-breadcrumbs--update (&optional window)
  "Update the Magit breadcrumbs display for WINDOW."
  (with-selected-window (or window (selected-window))
    (when magit-idle-breadcrumbs-mode
      (condition-case info
          (let ((current (magit-current-section)))
            (unless (equal
                     current (gethash window magit-idle-breadcrumbs--table))
              (puthash window current magit-idle-breadcrumbs--table)
              (setq header-line-format
                    (magit-idle-breadcrumbs--format-header-line
                     (magit-idle-breadcrumbs--format-section current)))
              (force-mode-line-update)))
        (error
         (setq magit-idle-breadcrumbs-mode nil)
         (error "Error in magit-idle-breadcrumbs-update: %S" info))))))

(defun magit-idle-breadcrumbs--on ()
  "Turn Magit Idle Breadcrumbs on."
  (setq magit-idle-breadcrumbs--update-timer
        (run-with-idle-timer
         idle-update-delay t 'magit-idle-breadcrumbs--update))
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (setq magit-idle-breadcrumbs-mode
            (member major-mode magit-idle-breadcrumbs-modes)))))

(defun magit-idle-breadcrumbs--off ()
  "Turn Magit Idle Breadcrumbs off."
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (setq
       magit-idle-breadcrumbs-mode nil
       header-line-format nil))))

;;;###autoload
(define-minor-mode magit-idle-breadcrumbs-mode
  "Toggle header line display of Magit breadcrumb.
With a prefix argument ARG, enable Magit Idle Breadcrumbs mode if
ARG is positive, and disable it otherwise.  If called from Lisp,
enable the mode if ARG is omitted or nil.

Magit Idle Breadcrumbs mode is a global minor mode.  When
enabled, the current Magit breadcrumb is continuously displayed in
the header line in supported major modes."
  :global t :group 'magit-idle-breadcrumbs
  (when (timerp magit-idle-breadcrumbs--update-timer)
    (cancel-timer magit-idle-breadcrumbs--update-timer))
  (setq magit-idle-breadcrumbs--update-timer nil)
  (if magit-idle-breadcrumbs-mode
      (magit-idle-breadcrumbs--on)
    (magit-idle-breadcrumbs--off)))

(defun turn-on-magit-idle-breadcrumbs ()
  "Conditionally turn on magit-idle-breadcrumbs-mode."
  (when (member major-mode magit-idle-breadcrumbs-modes)
    (magit-idle-breadcrumbs-mode t)))

;;;###autoload
(define-globalized-minor-mode global-magit-idle-breadcrumbs-mode
  magit-idle-breadcrumbs-mode turn-on-magit-idle-breadcrumbs
  :group 'magit-idle-breadcrumbs)

(provide 'magit-idle-breadcrumbs)
;;; magit-idle-breadcrumbs.el ends here

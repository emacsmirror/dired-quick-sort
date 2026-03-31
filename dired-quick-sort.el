;;; dired-quick-sort.el --- Persistent quick sorting of Dired buffers in various ways. -*- lexical-binding: t; -*-

;; Copyright (C) 2016-2025 Hong Xu <hong@topbug.net>

;; Author: Hong Xu <hong@topbug.net>
;; URL: https://gitlab.com/xuhdev/dired-quick-sort
;; Version: 1.0.0+
;; Package-Requires: ((emacs "28"))
;; Keywords: convenience, files

;; This file is not part of GNU Emacs

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This package provides ways to quickly sort Dired buffers in various ways.
;; With `savehist-mode' enabled (strongly recommended), the last used sorting
;; criteria are automatically used when sorting, even after restarting Emacs.
;; A transient menu is provided to conveniently change sorting criteria.
;;
;; For a quick setup, Add the following configuration to your "~/.emacs" or
;; "~/.emacs.d/init.el" after autoloads are in effect:
;;
;;     (dired-quick-sort-setup)
;;
;; This will bind "S" in dired-mode to invoke the sorting menu and new Dired
;; buffers are automatically sorted according to the setup in this package.  See
;; the document of `dired-quick-sort-setup` if you need a different setup.  It
;; is recommended that at least "-l" should be put into
;; `dired-listing-switches'.  If used with dired+, you may want to set
;; `diredp-hide-details-initially-flag' to nil.
;;
;; To make full use of this extensions, please make sure that the variable
;; `insert-directory-program' points to the GNU version of ls.
;;
;; To comment, ask questions, report bugs or make feature requests, please open
;; a new ticket at the issue tracker
;; <https://gitlab.com/xuhdev/dired-quick-sort/issues>.  To contribute, please
;; create a merge request at
;; <https://gitlab.com/xuhdev/dired-quick-sort/merge_requests>.

;;; Code:

(require 'dired)
(require 'ls-lisp)
(require 'savehist)
(require 'transient)

(defcustom dired-quick-sort ()
  "Persistent quick sorting of Dired buffers in various ways."
  :group 'dired)

(defcustom dired-quick-sort-suppress-setup-warning nil
  "How to handle the warning in `dired-quick-sort-setup'."
  :type '(choice (const :tag "Display" nil)
                 (const :tag "Suppress" t)
                 (const :tag "Display as a message" 'message))
  :group 'dired-quick-sort)

(defvar dired-quick-sort-sort-by-last "version"
  "The main sort criterion used last time.

The value should be one of none, time, size, version (i.e., natural, an improved
version of name and extension).

See the documentation of the \"--sort\" option of GNU ls for details.")
(add-to-list 'savehist-additional-variables 'dired-quick-sort-sort-by-last)

(defvar dired-quick-sort-reverse-last ?n
  "Whether reversing was enabled when sorting was used last time.

The value should be either ?y or ?n.")
(add-to-list 'savehist-additional-variables 'dired-quick-sort-reverse-last)

(defvar dired-quick-sort-group-directories-last ?n
  "Whether directories are grouped together when sorting was used last time.

The value should either be ?y or ?n.")
(add-to-list 'savehist-additional-variables
             'dired-quick-sort-group-directories-last)

(defvar dired-quick-sort-time-last "default"
  "The time option used last time.

The value should be one of default (modified time), atime, access, use, ctime or
status.  If the sort-by option is set as \"time\", the specified time will be
used as the key for sorting.

See the documentation of the \"--time\" option of GNU ls for details.")
(add-to-list 'savehist-additional-variables 'dired-quick-sort-time-last)

;;;###autoload
(defun dired-quick-sort (&optional sort-by reverse group-directories time)
  "Sort Dired by the given criteria.

The possible values of SORT-BY, REVERSE, GROUP-DIRECTORIES and TIME are
explained in the variable `dired-quick-sort-reverse-last',
`dired-quick-sort-reverse-last', `dired-quick-sort-group-directories-last' and
`dired-quick-sort-time-last' respectively.  Besides, passing nil to any of these
arguments to use the value used last time (that is, the values of the four
variables mentioned before), even after restarting Emacs if `savehist-mode' is
enabled.  When invoked interactively, nil's are passed to all arguments."
  (interactive)
  (setq dired-quick-sort-sort-by-last (or sort-by dired-quick-sort-sort-by-last)
        dired-quick-sort-reverse-last (or reverse dired-quick-sort-reverse-last)
        dired-quick-sort-group-directories-last
        (or group-directories dired-quick-sort-group-directories-last)
        dired-quick-sort-time-last (or time dired-quick-sort-time-last))
  (dired-sort-other (dired-quick-sort--format-switches)))

(defun dired-quick-sort-set-switches ()
  "Set switches according to variables.
For use in `dired-mode-hook'."
  (unless dired-sort-inhibit
    (dired-sort-other (dired-quick-sort--format-switches) t)))

(defun dired-quick-sort--format-switches ()
  "Return a `dired-listing-switches' string according to `dired-quick-sort' settings."
  (mapconcat
   #'identity
   (list dired-listing-switches
         (when (not (string= dired-quick-sort-sort-by-last "default"))
           (concat "--sort=" dired-quick-sort-sort-by-last))
         (when (char-equal dired-quick-sort-reverse-last ?y)
           "-r")
         (when (char-equal dired-quick-sort-group-directories-last ?y)
           "--group-directories-first")
         (when (not (string= dired-quick-sort-time-last "default"))
           (concat "--time=" dired-quick-sort-time-last)))
   " "))

;;; Transient interface

(eval-and-compile
  (defmacro dired-quick-sort--define-transient-suffix
      (name label active-var active-value &rest sort-args)
    "Define a transient suffix for `dired-quick-sort-transient'.
NAME is appended to \"dired-quick-sort--transient-\" to form the command name.
LABEL is the display text.  When ACTIVE-VAR equals ACTIVE-VALUE the
description is highlighted with `transient-value' face.
SORT-ARGS are passed to `dired-quick-sort'."
    (let ((fn-name (intern (format "dired-quick-sort--transient-%s" name))))
      `(transient-define-suffix ,fn-name ()
         :description
         (lambda ()
           (if (string= ,active-var ,active-value)
               (propertize ,label 'face 'transient-value)
             ,label))
         :transient t
         (interactive)
         (dired-quick-sort ,@sort-args)))))

;; Sort by
(dired-quick-sort--define-transient-suffix
 sort-none "none" dired-quick-sort-sort-by-last "none" "none")
(dired-quick-sort--define-transient-suffix
 sort-time "time" dired-quick-sort-sort-by-last "time" "time")
(dired-quick-sort--define-transient-suffix
 sort-size "size" dired-quick-sort-sort-by-last "size" "size")
(dired-quick-sort--define-transient-suffix
 sort-version "version (natural)"
 dired-quick-sort-sort-by-last "version" "version")
(dired-quick-sort--define-transient-suffix
 sort-extension "extension"
 dired-quick-sort-sort-by-last "extension" "extension")
(dired-quick-sort--define-transient-suffix
 sort-default "default"
 dired-quick-sort-sort-by-last "default" "default")

;; Time
(dired-quick-sort--define-transient-suffix
 time-default "default (last modified time)"
 dired-quick-sort-time-last "default" nil nil nil "default")
(dired-quick-sort--define-transient-suffix
 time-atime "atime"
 dired-quick-sort-time-last "atime" nil nil nil "atime")
(dired-quick-sort--define-transient-suffix
 time-access "access"
 dired-quick-sort-time-last "access" nil nil nil "access")
(dired-quick-sort--define-transient-suffix
 time-use "use"
 dired-quick-sort-time-last "use" nil nil nil "use")
(dired-quick-sort--define-transient-suffix
 time-ctime "ctime"
 dired-quick-sort-time-last "ctime" nil nil nil "ctime")
(dired-quick-sort--define-transient-suffix
 time-status "status"
 dired-quick-sort-time-last "status" nil nil nil "status")

;; Toggles
(transient-define-suffix dired-quick-sort--transient-toggle-reverse ()
  :description
  (lambda ()
    (if (char-equal dired-quick-sort-reverse-last ?y)
        (propertize "Reverse" 'face 'transient-value)
      "Reverse"))
  :transient t
  (interactive)
  (dired-quick-sort
   nil (if (char-equal dired-quick-sort-reverse-last ?y) ?n ?y)))

(transient-define-suffix dired-quick-sort--transient-toggle-group-directories ()
  :description
  (lambda ()
    (if (char-equal dired-quick-sort-group-directories-last ?y)
        (propertize "Group directories first" 'face 'transient-value)
      "Group directories first"))
  :transient t
  (interactive)
  (dired-quick-sort
   nil nil (if (char-equal dired-quick-sort-group-directories-last ?y) ?n ?y)))

;;;###autoload (autoload 'dired-quick-sort-transient "dired-quick-sort")
(transient-define-prefix dired-quick-sort-transient ()
  "Sort Dired buffer."
  [[:description
    (lambda ()
      (format "Sort by (%s)" dired-quick-sort-sort-by-last))
    ("n" dired-quick-sort--transient-sort-none)
    ("t" dired-quick-sort--transient-sort-time)
    ("s" dired-quick-sort--transient-sort-size)
    ("v" dired-quick-sort--transient-sort-version)
    ("e" dired-quick-sort--transient-sort-extension)
    ("D" dired-quick-sort--transient-sort-default)]
   [:description
    (lambda ()
      (format "Time (%s)" dired-quick-sort-time-last))
    ("d" dired-quick-sort--transient-time-default)
    ("A" dired-quick-sort--transient-time-atime)
    ("a" dired-quick-sort--transient-time-access)
    ("u" dired-quick-sort--transient-time-use)
    ("c" dired-quick-sort--transient-time-ctime)
    ("S" dired-quick-sort--transient-time-status)]]
  ["Options"
   ("r" dired-quick-sort--transient-toggle-reverse)
   ("g" dired-quick-sort--transient-toggle-group-directories)]
  [("q" "quit" transient-quit-all)])

(defun dired-quick-sort--display-setup-warning (msg)
  "Display setup warning according to `dired-quick-sort-suppress-setup-warning'."
  (let ((display-func
         (pcase-exhaustive dired-quick-sort-suppress-setup-warning
           ('nil (lambda (m) (display-warning 'dired-quick-sort m)))
           ('message #'message)
           ('t #'ignore))))
    (funcall display-func msg)))

;;;###autoload
(defun dired-quick-sort-setup ()
  "Run the default setup.

This will bind the key S in `dired-mode' to invoke the sorting
menu, and automatically run the sorting criteria after entering
`dired-mode'.

You can choose to not call this setup function and run a modified
version of this function to use your own preferred setup:

  ;; Replace \"S\" with other keys to invoke the sorting menu.
  (define-key dired-mode-map \"S\" #'dired-quick-sort-transient)
  ;; Automatically use the sorting defined here to sort.
  (add-hook 'dired-mode-hook 'dired-quick-sort)"

  (if (not ls-lisp-use-insert-directory-program)
      (dired-quick-sort--display-setup-warning
       "`ls-lisp-use-insert-directory-program' is nil. The package `dired-quick-sort'
will not work and thus is not set up by `dired-quick-sort-setup'. Set it to t to
suppress this warning. Alternatively, set
`dired-quick-sort-suppress-setup-warning' to suppress warning and skip setup
silently.")
    (if (not
         (with-temp-buffer
           (call-process insert-directory-program nil t nil "--version")
           (string-match-p "GNU" (buffer-string))))
        (dired-quick-sort--display-setup-warning
         "`insert-directory-program' does
not point to GNU ls.  Please set `insert-directory-program' to GNU ls.  The
package `dired-quick-sort' will not work and thus is not set up by
`dired-quick-sort-setup'. Alternatively, set
`dired-quick-sort-suppress-setup-warning' to suppress warning and skip setup
silently.")
      (define-key dired-mode-map "S" #'dired-quick-sort-transient)
      (add-hook 'dired-mode-hook #'dired-quick-sort-set-switches))))

(provide 'dired-quick-sort)

;;; dired-quick-sort.el ends here

;; Local Variables:
;; coding: utf-8
;; fill-column: 80
;; indent-tabs-mode: nil
;; sentence-end-double-space: t
;; End:

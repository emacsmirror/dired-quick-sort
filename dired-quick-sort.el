;;; dired-quick-sort.el --- Persistent quick sorting of dired buffers in various ways. -*- lexical-binding: t; fill-column: 80; coding: utf-8; indent-tabs-mode: nil; -*-

;; Copyright (C) 2016  Hong Xu <hong@topbug.net>

;; Author: Hong Xu <hong@topbug.net>
;; URL: https://gitlab.com/xuhdev/dired-quick-sort#dired-quick-sort
;; Version: 0.1
;; Package-Requires: ((hydra "0.13.0"))
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
;; This package provides ways to quickly sort dired buffers in various ways.
;; With `savehist-mode' enabled (strongly recommended), the last used sorting
;; criteria are automatically used when sorting, even after restarting Emacs.  A
;; hydra is defined to conveniently change sorting criteria.

;;; Code:

(require 'dired)
(require 'savehist)
(require 'hydra)

(defvar dired-quick-sort-sort-by-last "version"
  "The main sort criteria used last time.

The value should be one of none, time, size, version (natural, an improved
version of name and extension.

See the documentation of the \"--sort\" option of GNU ls for details.")
(push 'dired-quick-sort-sort-by-last savehist-additional-variables)
(defvar dired-quick-sort-reverse-last ?n
  "Whether reversing was enabled when sorting was used last time.

The value should be either ?y or ?n.")
(push 'dired-quick-sort-reverse-last savehist-additional-variables)
(defvar dired-quick-sort-group-directories-last ?n
  "Whether directories are grouped together when sorting was used last time.

The value should either be ?y or ?n.")
(push 'dired-quick-sort-group-directories-last savehist-additional-variables)
(defvar dired-quick-sort-time-last "default"
  "The time option used last time.

The value should be one of default (modified time), atime, access, use, ctime or
status.  If the sort-by option is set as \"time\", the specified time will be
used as the key for sorting.

See the documentation of the \"--time\" option of GNU ls for details.")
(push 'dired-quick-sort-time-last savehist-additional-variables)

;;;###autoload
(defun dired-quick-sort (&optional sort-by reverse group-directories time)
  "Sort dired by the given criteria.

The possible values of SORT-BY, REVERSE, GROUP-DIRECTORIES and TIME are
explained in the variable `dired-quick-sort-reverse-last',
`dired-quick-sort-reverse-last', `dired-quick-sort-group-directories-last' and
`dired-quick-sort-time-last' respectively.  Besides, passing nil to any of these
arguments to use the value used last time (that is, the values of the four
variables mentioned before), even after restarting Emacs if `savehist-mode' is
enabled.  When invoked interactively, nil's are passed to all arguments.

SORT-BY"
  (interactive)
  (setq dired-quick-sort-sort-by-last (or sort-by dired-quick-sort-sort-by-last)
        dired-quick-sort-reverse-last (or reverse dired-quick-sort-reverse-last)
        dired-quick-sort-group-directories-last
        (or group-directories dired-quick-sort-group-directories-last)
        dired-quick-sort-time-last (or time dired-quick-sort-time-last))
  (dired-sort-other
   (format "%s --sort=%s %s %s %s" dired-listing-switches
           dired-quick-sort-sort-by-last
           (if (char-equal dired-quick-sort-reverse-last ?y)
               "-r" "")
           (if (char-equal dired-quick-sort-group-directories-last ?y)
               "--group-directories-first" "")
           (if (not (string= dired-quick-sort-time-last "default"))
               (concat "--time=" dired-quick-sort-time-last) ""))))

(defhydra hydra-dired-quick-sort (:hint none :color pink)
  "
^Sort by^                   ^Reverse^               ^Group Directories^            ^Time
^^^^^^^^^----------------------------------------------------------------------------------------------------------------
_n_: ?n? none               _r_: ?r? yes            _g_: ?g? yes                   _d_: ?d? default (last modified time)
_t_: ?t? time               _R_: ?R? no             _G_: ?G? no                    _A_: ?A? atime
_s_: ?s? size               ^ ^                     ^ ^                            _a_: ?a? access
_v_: ?v? version (natural)  ^ ^                     ^ ^                            _u_: ?u? use
_e_: ?e? extension          ^ ^                     ^ ^                            _c_: ?c? ctime
_q_: quit                   ^ ^                     ^ ^                            _S_: ?S? status
"
  ("n" (lambda () (interactive) (dired-quick-sort "none" nil nil nil))
   (if (string= dired-quick-sort-sort-by-last "none") "[X]" "[ ]"))
  ("t" (lambda () (interactive) (dired-quick-sort "time" nil nil nil))
   (if (string= dired-quick-sort-sort-by-last "time") "[X]" "[ ]"))
  ("s" (lambda () (interactive) (dired-quick-sort "size" nil nil nil))
   (if (string= dired-quick-sort-sort-by-last "size") "[X]" "[ ]"))
  ("v" (lambda () (interactive) (dired-quick-sort "version" nil nil nil))
   (if (string= dired-quick-sort-sort-by-last "version") "[X]" "[ ]"))
  ("e" (lambda () (interactive) (dired-quick-sort "extension" nil nil nil))
   (if (string= dired-quick-sort-sort-by-last "extension") "[X]" "[ ]"))
  ("r" (lambda () (interactive) (dired-quick-sort nil ?y nil nil))
   (if (char-equal dired-quick-sort-reverse-last ?y) "[X]" "[ ]"))
  ("R" (lambda () (interactive) (dired-quick-sort nil ?n nil nil))
   (if (char-equal dired-quick-sort-reverse-last ?n) "[X]" "[ ]"))
  ("g" (lambda () (interactive) (dired-quick-sort nil nil ?y nil))
   (if (char-equal dired-quick-sort-group-directories-last ?y) "[X]" "[ ]"))
  ("G" (lambda () (interactive) (dired-quick-sort nil nil ?n nil))
   (if (char-equal dired-quick-sort-group-directories-last ?n) "[X]" "[ ]"))
  ("d" (lambda () (interactive) (dired-quick-sort nil nil nil "default"))
   (if (string= dired-quick-sort-time-last "default") "[X]" "[ ]"))
  ("A" (lambda () (interactive) (dired-quick-sort nil nil nil "atime"))
   (if (string= dired-quick-sort-time-last "atime") "[X]" "[ ]"))
  ("a" (lambda () (interactive) (dired-quick-sort nil nil nil "access"))
   (if (string= dired-quick-sort-time-last "access") "[X]" "[ ]"))
  ("u" (lambda () (interactive) (dired-quick-sort nil nil nil "use"))
   (if (string= dired-quick-sort-time-last "use") "[X]" "[ ]"))
  ("c" (lambda () (interactive) (dired-quick-sort nil nil nil "ctime"))
   (if (string= dired-quick-sort-time-last "ctime") "[X]" "[ ]"))
  ("S" (lambda () (interactive) (dired-quick-sort nil nil nil "status"))
   (if (string= dired-quick-sort-time-last "status") "[X]" "[ ]"))
  ("q" nil "quit" :hint t :color blue))

;;;###autoload
(defun dired-quick-sort-setup ()
  "Run the default setup.

This will bind \"S\" in `dired-mode' to run `hydra-dired-quick-sort/body', and
automatically run the sorting criteria after entering `dired-mode'.  You can
choose to not call this setup function and run a modified version of this
function to use your own preferred setup:

  ;; Replace \"S\" with other keys to invoke the dired-quick-sort hydra.
  (define-key dired-mode-map \"S\" 'hydra-dired-quick-sort/body)
  ;; Automatically use the sorting defined here to sort.
  (add-hook 'dired-mode-hook 'dired-quick-sort)"

  (define-key dired-mode-map "S" 'hydra-dired-quick-sort/body)
  (add-hook 'dired-mode-hook 'dired-quick-sort))

(provide 'dired-quick-sort)

;;; dired-quick-sort.el ends here


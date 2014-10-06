;;; me-alpheus-gotags --- Tags for Go, using jstemmer/gotags.
;;; Copyright (C) 2014  Craig B. Ludington

;; Author: Craig B. Ludington <me@alpheus.me>
;; Keywords: golang gotags convenience
;; Version: 0.0.1

;; This file is not part of Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;;; Joël Stemmer's "gotags is a ctags-compatible tag generator for Go."
;;; Gotags can be found at https://github.com/jstemmer/gotags
;;;
;;; This program lets you use a gotags tags file in Emacs.
;;;
;;; Quickstart:
;;;   Shell:
;;;     go get -u github.com/jstemmer/gotags
;;;     cd $root_of_your_source_tree
;;;     gotags -R=true * > GOTAGS
;;;
;;;   Emacs:
;;;     Save this file in a directory on your load-path.
;;;
;;;       (add-to-list 'load-path "/directory/containing/this/file")
;;;       (require 'me-alpheus-gotags)
;;;
;;;     M-x customize-group RET me.alpheus/gotags
;;;
;;;     Configure the me.alpheus/gotags-tags-file variable as the pathname of the GOTAGS file you created.
;;;
;;;   Usage
;;;     Visit a Go source file, and with point on any Go symbol, such as a func or struct name, or a var:
;;;
;;;       M-x me.alpheus/gotags/tag-search
;;;
;;;     If the symbol is unique, you'll jump to that symbol's definition.
;;;
;;;     If the symbol is not unique, you'll jump to the first instance of that symbol in the GOTAGS file.
;;;     Move to the specific instance you're interested in, then use:
;;;
;;;       M-x me.alpheus/gotags/tag-search
;;;
;;;     again to jump to the definition.
;;;
;;;     You can bind me.alpheus/gotags/tag-search to a key if you like, e.g.
;;;
;;;       (global-set-key (kbd "s-.") #'me.alpheus/gotags/tag-search)
;;;

;;; Bugs:
;;;
;;;  1) This program shouldn't exist.  Instead, gotags should make an Emacs-style tags file.
;;;     Then we could just use the regular find-tag in etags.el.
;;;  2) You have to use global-set-key instead of using local-set-key in go-mode, because we invoke the
;;;     same function from buffers visiting Go source files and the buffer visiting the GOTAGS file.
;;;  3) If this program sticks around, we should display a nice menu of matching tags,
;;;     not make the end-user grovel around in a GOTAGS file when there are multiple definitions
;;;     for a given symbol.

;;; Code:

(require 'cl)

(defgroup me.alpheus/gotags nil
  "Jump to Go language source definitions using gotags (https://github.com/jstemmer/gotags)."
  :group 'extensions
  :group 'convenience)

(defcustom me.alpheus/gotags-tags-file "~/GOTAGS"
  "Tags file created by the gotags program."
  :type 'string)

(defun me.alpheus/gotags/jump-to-tag ()
  "Must be visiting a gotags file.  Jump to the file and line specified by the current point in a tags file made by gotags."
  (interactive)
  (let* ((toks (split-string (buffer-substring-no-properties (point-at-bol) (point-at-eol)) "[\t]"))
	 (file (nth 1 toks))
	 (line (string-to-number (nth 0 (split-string (nth 2 toks) ";")))))
    (find-file file)
    (goto-line line)))

(defun me.alpheus/gotags/jump-to-tags-file ()
  "Must be visiting a Go source file.  Jump to the definition of the symbol at point, if unique.
Otherwise, jump to the first reference to the symbol at point in the GOTAGS file."
  (interactive)
  (let ((pattern (format "^%s[\t]" (thing-at-point 'word)))
	(matches '()) ;; TODO collect all the matches and show a nice menu if there are more than one.
	(case-fold-search nil))
    (cl-flet ((find () (search-forward-regexp pattern (point-max) :no-error)))
      (switch-to-buffer (find-buffer-visiting me.alpheus/gotags-tags-file))
      (goto-char (point-min))
      (if (find)
	  (when (not (save-excursion (find)))
	    (me.alpheus/gotags/jump-to-tag))
	(progn (message (format "Tag '%s' not found." pattern))
	       (previous-buffer))))))

(defun me.alpheus/gotags/tag-search ()
  "Tags search for the Go programming language.  Requires gotags (https://github.com/jstemmer/gotags).

Interactively, in a Go source file, jumps to the definition of the symbol at point.

If there's one and only one definition for the symbol, you'll jump right to the definition.

If there are multiple definitions for the symbol, you'll jump to the gotags file, and you'll have to move
around until you find the particular definition you want, then invoke me.alpheus/gotags/tag-search again
to jump to the particular Go source file where that symbol's defined.

A symbol is a function name, var, struct name, or anything else that gotags knows about.
"
  (interactive)
  (let ((tags-buf (or (get-file-buffer me.alpheus/gotags-tags-file)
		      (save-excursion (find-file me.alpheus/gotags-tags-file)
				      (current-buffer)))))
  (cond ((and buffer-file-name (string-match "\.go$"  buffer-file-name)) (me.alpheus/gotags/jump-to-tags-file))
	((equal (current-buffer) tags-buf) (me.alpheus/gotags/jump-to-tag))
	(t (message "For use in a Go source file or a file created by gotags.")))))

(provide 'me-alpheus-gotags)
;;; me-alpheus-gotags.el ends here

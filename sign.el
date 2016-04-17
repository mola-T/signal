;;; sign.el --- Advance hook  -*- lexical-binding: t; -*- 
;;
;; Copyright (C) 2015-2016 Mola-T
;; Author: Mola-T <Mola@molamola.xyz>
;; URL: https://github.com/mola-T/sign
;; Version: 1.0
;; Keywords: internal, lisp, processes, tools
;;
;;; License:
;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.
;;
;;; Commentary:
;;
;; See https://github.com/mola-T/sign for introduction
;;
;;; code:


(defmacro defsign (name &optional docstring)

  "Defining a signal.
Connect a signal to a worker function by `sign-connect'.
Use `emit' to emit the signal and the worker function will be called.

Example:
\(defsign my-signal
\"This a docmentation\"\)"
  
  (declare (doc-string 1) (indent 1))
  `(defvar ,name nil
     ,(concat "It is signal.
`sign-connect' of `sign-disconnect' is the only approciate way
to change the value of a signal. Using other setter like `setq', `let'
or etc. ruins the signal mechanism.\n\n" docstring)))


(defmacro undefsign (name)

  "Undefining a signal."

  `(unintern ,name))



(cl-defun sign-connect (&key sign arg worker)

  "Connect a signal SIGN to its WORKER function.
Use `emit' to emit a SIGNAL.

After a signal is emitted, the WORKER function is
called with arguments ARG.

If mutiple connections have been made, the WORKER functions
are called in order or making connection.

Example:
(sign-connect :sign 'my-signal
              :worker 'message
              :arg '(\"To print a message with %d %s.\" 100 \"words\"))"

(unless (and sign worker)
  (error "Sign and worker must be provided."))

(push (or (and arg (list worker arg))
          (list worker))
      (symbol-value sign)))



(cl-defun sign-disconnect (sign worker)

  "Disconnect a signal SIGN form its WORKER function.
If multiple connections of same worker have been made,
all of them are disconnected

Example:
(sign-disconnect :sign 'my-signal
                 :worker 'message"

(while (assoc worker (symbol-value sign))
  (set sign (delete (assoc worker (symbol-value sign)) (symbol-value sign)))))




(cl-defun emit (sign &key delay arg)

  "Emit a singal SIGN. The worker function(s) will be invoked.

DELAY is the second the worker functions delayed to run after
the signal has been emitted. It can be a floating point number
which specifies a fractional number of seconds to wait.
By default, it is 0.01 second.

ARG provides emit-time argument passing to the worker funcitons.

Example:
(emit 'my-signal)"

(when (boundp sign)
  (run-with-timer (or delay 0.01)
                  nil
                  (lambda () 
                    (dolist (sign-1 (nreverse (copy-sequence (symbol-value sign))))
                      (when (fboundp (car sign-1))
                        (ignore-errors (apply (car sign-1) (or arg (cadr sign-1))))))))
  t))



(cl-defun emitB (sign &key arg)

  "Emit a blocking signal SIGN. The worker function(s) will be invoked.

DELAY is the second the worker functions delayed to run after
the signal has been emitted. It can be a floating point number
which specifies a fractional number of seconds to wait.
By default, it is 0.01 second.

ARG provides emit-time argument passing to the worker funcitons

Example:
(emitB 'my-signal)"

(when (boundp sign)
  (dolist (sign-1 (nreverse (copy-sequence (symbol-value sign))))
    (when (fboundp (car sign-1))
      (ignore-errors (apply (car sign-1) (or arg (cadr sign-1))))))
  t))





(font-lock-add-keywords 'emacs-lisp-mode
                        '(("(\\(defsign\\)\\_>[ 	'(]*\\(\\(?:\\sw\\|\\s_\\)+\\)?"
                           (1 font-lock-keyword-face)
                           (2 font-lock-type-face nil t)
                           )
                          ("(\\(undefsign\\|sign-connect\\|sign-disconnect\\|emit\\|emitB\\)\\_>[ 	'(]*\\(\\(?:\\sw\\|\\s_\\)+\\)?"
                           (1 font-lock-warning-face nil))))

(provide 'sign)
;;; sign.el ends here

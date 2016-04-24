# SIGNAL

Signal is an advanced hook feature.

It provides elegant ways to connect functions.

<br><br>

## Requirement

* Emacs 24

<br>

## Basic usage

I will demonstrate its basic features by comparing it with the native `hook` from emacs. 

For programmers having experiences in using `hook`. There should be no difficulties using `signal` as they share very similar syntax and logic.

<br>

##### Creating new `hook` vs creating new `signal`

```elisp
(defcustom my-new-hook nil
  "This is a testing hook."
  :type 'hook
  :group 'some-group)
```

```elisp
(defsignal my-signal
   "This is my signal.")
```

As emacs `hook` is defined by `defcustom`, it is designed to be more friendly to end user.

Signal is designed for developer, it does not expect end users to come across it. It's define method looks easier too.

<br>

##### Function relating : `add-hook` vs `signal-connect`

``` elisp
(add-hook 'my-new-hook 'print-something)
```

``` elisp
(signal-connect :signal 'my-signal
                :worker 'print-something)
```

If you want `print-something` being invoked when the hook runs, you use `add-hook`.

For signal, you connect a worker function to the signal. It is almost the same as `add-hook`.

<br>

##### Function unrelating : `remove-hook` vs `signal-disconnect`

``` elisp
(remove-hook 'my-new-hook 'print-something)
```

```elisp
(signal-disconnect 'my-signal 'print-something)
```

Both of them have similar syntax.

<br>

##### Calling functions : `run-hooks` vs `signal-emitb`

``` elisp
(defun the-function-implementing-the hook ()
;; do jobs
    (run-hooks 'my-new-hook)
;; do jobs
)
```

``` elisp
(defun the-function-implementing-the hook ()
;; do jobs
    (signal-emitb 'my-signal)
;; do jobs
)
```

Again, both of them are using the same implementation.

<br>

##### Brief summary

`defsignal` - To define a new signal.
`signal-connect` - To connect the signal with a worker function.
`signal-disconnect` - To disconnect a worker function from the signal.
`signal-emitb` - To emit a signal.

If you feel comfortable with these four functions, you almost learn
90% of how to use this package. Most of the new features play around with these four functions only.

<br>

________________________________


## Features Showcase

<br>

### `(defsignal signal-name &optional docstring)`

`defsign` - To define a new signal.

<br>

### `(signal-connect &key signal arg worker)`

`signal-connect` is to connect the signal with a worker function.

If you connect more than one functions to a signal, they will be called in the same order of making the connections.

```elisp
(defsignal my-signal)

(signal-connect :signal 'my-signal
                :worker 'function1)
(signal-connect :signal 'my-signal
                :worker 'function2)

(signal-emitb 'my-signal)
;; ==> function1 invoked first
;; ==> function2 invoked after
```

If you connect the worker function twice to the same signal, the worker function will be invoked twice.

```elisp
(defsignal my-signal)

(signal-connect :signal 'my-signal
                :worker 'function1)
(signal-connect :signal 'my-signal
                :worker 'function1)

(signal-emitb 'my-signal)
;; ==> function1 invoked the first time
;; ==> function1 invoked the second time
```

Sometimes, you may want to provide arguments to the worker function.
You can use `:arg` to pass the argument. The arguments passed are evalusted at connection making time. Arguments are provided in list.


```elisp

(defsignal my-signal)

(signal-connect :signal 'my-signal
                :worker 'message
                :arg (list "Current-time is %s" (format-time-string "%H:%M:%S")))


(signal-emitb 'my-signal)
;; ==> Current-time is 17:01:16
(signal-emitb 'my-signal)
;; ==> Current-time is 17:01:16
;; Arguments are fixed at connection-making time
;; No matter how many times it called, you will get the same time
```

If the argument passed is incorrect, it just omits it without signalling any errors.

```elisp

(defsignal my-signal)

(signal-connect :signal 'my-signal
                :worker 'message
                :arg '(124567))

(signal-emitb 'my-signal)
;; ==> nothing happen
```
<br>

### `(signal-disconnect signal worker)`

`signal-disconnect` - To disconnect a worker function from the signal.

If singals had been connected to worker function mutiple times, they will be all removed.

```elisp
(defsignal my-signal)

(signal-connect :signal 'my-signal
                :worker 'function1)
(signal-connect :signal 'my-signal
                :worker 'function1)

(signal-disconnect 'my-signal 'function1)

(signal-emitb 'my-signal)
;; ==> nothing happen
```
<br>

### `(signal-emitb signal &key arg)`

`signal-emitb` - To emit a signal.

You can provide arguments at emit-time.

```elisp
(defsignal my-signal)

(signal-connect :signsl 'my-signal
                :worker 'message)

(signal-emitb 'my-signal :arg (list "Current-time is %s" (format-time-string "%H:%M:%S")))
;; ==> Current-time is 17:22:34
(signal-emitb 'my-signal :arg (list "Current-time is %s" (format-time-string "%H:%M:%S")))
;; ==> Current-time is 17:22:37
;; In this way, arguments are evaluated at emit-time
```

If you defined arguments at both connection time and and emit-time. The emit-time arguments will have higher priority.

```elisp
(defsignal my-signal)

(signal-connect :signal 'my-signal
                :worker 'message
                :arg (list "connect"))

(signal-emitb 'my-signal :arg (list "emit"))
;; ==> "emit" is printed
```

There would not be any errors signals even the worker function is undefined or arguments are incorrect.

<br><br>

## Final boss

You may wonder if there is an `signal-emitb`, there should be a `signal-emitA`. Sorry,
there is no such `signal-emitA`.

However, an `signal-emit` is indeed existed. The `B` stands for blocking. It means when the signal is emitted, it blocks the calling function, works through all functions stored in the signal first. And continue the original function afterward.

In contrast `emit` is non-blocking by letting the original function finished first.

<br>

### `(signal-emit signal &key delay arg)`

`signal-emit` - To emit a *non-blocking* signal.

```elisp
(defsignal my-signal)

(signal-connect :signal 'my-signal
                :worker 'message
                :arg (list "I am emitted."))

(progn
  (message "1 2 3 4")
  (signal-emitb 'my-signal)
  (message "5 6 7 8"))
;; ==> 1 2 3 4
;; ==> I am emitted.
;; ==> 5 6 7 8

(progn
  (message "1 2 3 4")
  (signal-emit 'my-signal)
  (message "5 6 7 8"))
;; ==> 1 2 3 4
;; ==> 5 6 7 8
;; ==> I am emitted.
```

Can you notice that the sequence of program code changed?

By providing the `:delay`, the worker functions will be called with delayed time. `delay` can be a floating point number which specifies a fractional number of seconds to delay.

```elisp
(defsignal my-signal)

(signal-connect :signal 'my-signal
                :worker 'message
                :arg (list "I am emitted."))

(progn
  (message "1 2 3 4")
  (signal-emit 'my-signal :delay 3)
  (message "5 6 7 8"))
  
;; ==> "I am emitted." will print after 3 second.
```

Same as `signal-emitb` you can also provide arguments to `signal-emit`

With everything combined, you can also write something like this:

```elisp
(defsignal my-signal)

(defun my-function (count &optional connected)

  (when (> count 0)
        ;; do job
        (message "signal is great")
    
        (unless connected
          (signal-connect :signal 'my-signal
                          :worker 'my-function))
        (signal-emit 'my-signal :arg (list (1- count) t)))
        
  (when (= count 0)
    (signal-disconnect 'my-signal 'my-function)))

(my-function 1000)
;; ==> signal is great [1000 times]


(defun my-function2 (count)
  (when (> count 0)
    (message "signal is great")
    (apply 'my-function2 (list (1- count)))))

(my-function2 1000)
;; ==> (error "Lisp nesting exceeds `max-lisp-eval-depth'")
```
_______________________________
<br>

## Contacts

mola@molamola.xyz

If you find any bugs or have any suggestions, you can make a pull request, report an issue or send me an email.

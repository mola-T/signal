# SIGN

Sign is an advanced hook feature.

It provides elegant ways to connect functions.

<br><br>

## Requirement

* Emacs 24

<br>

## Basic usage

I will demonstrate its basic features by comparing it with the native `hook` from emacs. 

For programmers having experiences in using `hook`. There should be no difficulties using `sign` as they share very similar syntax and logic.

<br>

##### Creating new `hook` vs creating new `signal`

```elisp
(defcustom my-new-hook nil
  "This is a testing hook."
  :type 'hook
  :group 'some-group)
```

```elisp
(defsign my-signal
   "This is my signal.")
```

As emacs `hook` is defined by `defcustom`, it is designed to be more friendly to end user.

Signal is designed for developer, it does not expect end users to come across it. It's define method looks easier too.

<br>

##### Function relating : `add-hook` vs `sign-connect`

``` elisp
(add-hook 'my-new-hook 'print-something)
```

``` elisp
(sign-connect :sign 'my-signal
              :worker 'print-something)
```

If you want `print-something` being invoked when the hook runs, you use `add-hook`.

For signal, you connect a worker function to the signal. It is almost the same as `add-hook`.

<br>

##### Function unrelating : `remove-hook` vs `sign-disconnect`

``` elisp
(remove-hook 'my-new-hook 'print-something)
```

```elisp
(sign-disconnect 'my-signal 'print-something)
```

Both of them have similar syntax.

<br>

##### Calling functions : `run-hooks` vs `emitB`

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
    (emitB 'my-signal)
;; do jobs
)
```

Again, both of them are using the same implementation.

<br>

##### Brief summary

`defsign` - To define a new signal.
`sign-connect` - To connect the signal with a worker function.
`sign-disconnect` - To disconnect a worker function from the signal.
`emitB` - To emit a signal.

If you feel comfortable with these four functions, you almost learn
90% of how to use this package. Most of the new features play around with these four functions only.

<br>

________________________________


## Features Showcase

<br>

### `(defsign signal-name &optional docstring)`

`defsign` - To define a new signal.

<br>

### `(sign-connect &key sign arg worker)`

`sign-connect` is to connect the signal with a worker function.

If you connect more than one functions to a signal, they will be called in the same order of making the connections.

```elisp
(defsign my-signal)

(sign-connect :sign 'my-signal
              :worker 'function1)
(sign-connect :sign 'my-signal
              :worker 'function2)

(emitB 'my-signal)
;; ==> function1 invoked first
;; ==> function2 invoked after
```

If you connect the worker function twice to the same signal, the worker function will be invoked twice.

```elisp
(defsign my-signal)

(sign-connect :sign 'my-signal
              :worker 'function1)
(sign-connect :sign 'my-signal
              :worker 'function1)

(emitB 'my-signal)
;; ==> function1 invoked the first time
;; ==> function1 invoked the second time
```

Sometimes, you may want to provide arguments to the worker function.
You can use `:arg` to pass the argument. The arguments passed are evalusted at connection making time. Arguments are provided in list.


```elisp

(defsign my-signal)

(sign-connect :sign 'my-signal
              :worker 'message
              :arg (list "Current-time is %s" (format-time-string "%H:%M:%S")))


(emitB 'my-signal)
;; ==> Current-time is 17:01:16
(emitB 'my-signal)
;; ==> Current-time is 17:01:16
;; Arguments are fixed at connection-making time
;; No matter how many times it called, you will get the same time
```

If the argument passed is incorrect, it just omits it without signalling any errors.

```elisp

(defsign my-signal)

(sign-connect :sign 'my-signal
              :worker 'message
              :arg '(124567))

(emitB 'my-signal)
;; ==> nothing happen
```
<br>

### `(sign-disconnect sign worker)`

`sign-disconnect` - To disconnect a worker function from the signal.

If singals had been connected to worker function mutiple times, they will be all removed.

```elisp
(defsign my-signal)

(sign-connect :sign 'my-signal
              :worker 'function1)
(sign-connect :sign 'my-signal
              :worker 'function1)

(sign-disconnect 'my-signal 'function1)

(emitB 'my-signal)
;; ==> nothing happen
```
<br>

### `(emitB signal &key arg)`

`emitB` - To emit a signal.

You can provide arguments at emit-time.

```elisp
(defsign my-signal)

(sign-connect :sign 'my-signal
              :worker 'message)

(emitB 'my-signal :arg (list "Current-time is %s" (format-time-string "%H:%M:%S")))
;; ==> Current-time is 17:22:34
(emitB 'my-signal :arg (list "Current-time is %s" (format-time-string "%H:%M:%S")))
;; ==> Current-time is 17:22:37
;; In this way, arguments are evaluated at emit-time
```

If you defined arguments at both connection time and and emit-time. The emit-time arguments will have higher priority.

```elisp
(defsign my-signal)

(sign-connect :sign 'my-signal
              :worker 'message
              :arg (list "connect"))

(emitB 'my-signal :arg (list "emit"))
;; ==> "emit" is printed
```

There would not be any errors signals even the worker function is undefined or arguments are incorrect.

<br><br>

## Final boss

You may wonder if there is an `emitB`, there should be a `emita`. Sorry,
there is no such `emita`.

However, an `emit` is indeed existed. The `b` stands for blocking. It means when the signal is emitted, it blocks the calling function, works through all functions stored in the signal first. And continue the original function afterward.

In contrast `emit` is non-blocking by letting the original function finished first.

<br>

### `(emit sign &key delay arg)`

`emit` - To emit a *non-blocking* signal.

```elisp
(defsign my-signal)

(sign-connect :sign 'my-signal
              :worker 'message
              :arg (list "I am emitted."))

(progn
  (message "1 2 3 4")
  (emitB 'my-signal)
  (message "5 6 7 8"))
;; ==> 1 2 3 4
;; ==> I am emitted.
;; ==> 5 6 7 8

(progn
  (message "1 2 3 4")
  (emit 'my-signal)
  (message "5 6 7 8"))
;; ==> 1 2 3 4
;; ==> 5 6 7 8
;; ==> I am emitted.
```

Can you notice that the sequence of program code changed?

By providing the `:delay`, the worker functions will be called with delayed time. `delay` can be a floating point number which specifies a fractional number of seconds to delay.

```elisp
(defsign my-signal)

(sign-connect :sign 'my-signal
              :worker 'message
              :arg (list "I am emitted."))

(progn
  (message "1 2 3 4")
  (emit 'my-signal :delay 3)
  (message "5 6 7 8"))
  
;; ==> "I am emitted." will print after 3 second.
```

Same as `emitB` you can also provide arguments to `emit`

With everything combined, you can also write something like this:

```elisp
(defsign my-signal)

(defun my-function (count &optional connected)

  (when (> count 0)
        ;; do job
        (message "sign is great")
    
        (unless connected
          (sign-connect :sign 'my-signal
                        :worker 'my-function))
        (emit 'my-signal :arg (list (1- count) t)))
        
  (when (= count 0)
    (sign-disconnect 'my-signal 'my-function)))

(my-function 1000)
;; ==> sign is great [1000 times]

(defun my-function2 (count)
  (when (> count 0)
    (message "sign is great")
    (apply 'my-function2 (list (1- count)))))

(my-function2 1000)
;; ==> (error "Lisp nesting exceeds `max-lisp-eval-depth'")
```
_______________________________
<br>

## Contacts

mola@molamola.xyz

If you find any bugs or have any suggestions, you can make a pull request, report an issue or send me an email.

# Swank Client

Swank Client is a Common Lisp implementation of the client side of the Swank
debugging protocol used by [Slime](https://en.wikipedia.org/wiki/SLIME), a [GNU
Emacs](https://www.gnu.org/software/emacs) mode that implements an IDE for Lisp
programming.  Emacs uses the Swank protocol to communicate with a Lisp system
when a user runs the IDE, but the protocol is useful independently of Emacs
because it allows a client to evaluate expressions on a remote Lisp that's
running a Swank server.

Swank Client is used by [Swank Crew](https://github.com/brown/swank-crew) to
implement a Slime IDE for developing distributed algorithms in Lisp.

## The Swank Client API

```
swank-connection        An object representing a Swank connection.
slime-connect           Connects to a remote Common Lisp using the Swank protocol.
slime-close             Closes a Swank connection.
slime-eval              Evaluates an expression on a remote Lisp.
slime-eval-async        Evaluates an expression on a remote Lisp asynchronously.
slime-migrate-evals     Migrates work pending on one Swank connection to another.
slime-network-error     A condition that represents a network error.
slime-pending-evals-p   Does a Swank connection have unfinished work pending?
with-slime-connection   Macro that operates like with-open-file.
```

For more information, see the documentation strings in
[swank-client.lisp](https://github.com/brown/swank-client/blob/master/swank-client.lisp)
and the example code in
[swank-client-test.lisp](https://github.com/brown/swank-client/blob/master/swank-client-test.lisp).

## Swank Client example

### Starting a Swank server

The code below starts two Swank servers, one listening on port 4005 and the
other listening on port 10000.

```
(load-quicklisp)
(asdf:load-system 'com.google.base)
(asdf:load-system 'swank)

(defvar *emacs-port* 4005)
(defvar *swank-client-port* 10000)

(defun swank-thread ()
  "Returns a thread that's acting as a Swank server."
  (dolist (thread (sb-thread:list-all-threads))
    (when (com.google.base:prefixp "Swank" (sb-thread:thread-name thread))
      (return thread))))

(defun wait-for-swank-thread ()
  "Wait for the Swank server thread to exit."
  (let ((swank-thread (swank-thread)))
    (when swank-thread
      (sb-thread:join-thread swank-thread))))

(defun main ()
  (setf swank:*configure-emacs-indentation* nil
        swank::*enable-event-history* nil
        swank:*log-events* t)
  (swank:create-server :port *emacs-port* :dont-close t)
  (swank:create-server :port *swank-client-port* :dont-close t)
  (wait-for-swank-thread))

(main)
```

### Using Swank Client to evaluate an expression on the server

Once the Swank servers are running, you can connect to the server on port 4005
from Emacs using the command ```M-x slime-connect```.  This connection is a
normal Slime IDE session.  From the Slime IDE you can evaluate the following
code, which creates a Swank Client connection to the server running on port
10000 and remotely evaluates the expression ```(cons 1 2)```.

```
(load-quicklisp)
(asdf:load-system 'swank-client)

(swank-client:with-slime-connection (connection "localhost" 10000)
  (swank-client:slime-eval '(cons 1 2) connection))
```
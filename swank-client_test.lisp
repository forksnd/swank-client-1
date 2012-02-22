;;;; Copyright 2011 Google Inc.

;;;; This program is free software; you can redistribute it and/or
;;;; modify it under the terms of the GNU General Public License
;;;; as published by the Free Software Foundation; either version 2
;;;; of the License, or (at your option) any later version.

;;;; This program is distributed in the hope that it will be useful,
;;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;;; GNU General Public License for more details.

;;;; You should have received a copy of the GNU General Public License
;;;; along with this program; if not, write to the Free Software
;;;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
;;;; MA  02110-1301, USA.

;;;; Author: brown@google.com (Robert Brown)

;;;; Swank client unit tests.

(in-package #:common-lisp-user)

(defpackage #:swank-client-test
  (:documentation "Test code in the SWANK-CLIENT package.")
  (:use #:common-lisp
        #:com.google.base
        #:hu.dwim.stefil
        #:swank-client)
  (:export #:test-swank-client))

(in-package #:swank-client-test)
(declaim #.*optimize-default*)

(defsuite (test-swank-client :in root-suite) ()
  (run-child-tests))

(in-suite test-swank-client)

(defconst +server-port+ 12345)
(defconst +server-count+ 4)

(deftest simple-eval ()
  (swank:create-server :port +server-port+)
  (with-slime-connection (connection "localhost" +server-port+)
    (is (= (slime-eval 123 connection) 123))))

(deftest simple-eval-async ()
  (swank:create-server :port +server-port+)
  (with-slime-connection (connection "localhost" +server-port+)
    (let ((result nil))
      (slime-eval-async 123 connection (lambda (x) (setf result x)))
      (sleep 0.1)
      (is (= result 123)))))

(deftest several-connections ()
  (loop repeat +server-count+
        for port from +server-port+
        do (swank:create-server :port port))
  (let* ((connections (loop repeat +server-count+
                            for port from +server-port+
                            collect (slime-connect "localhost" port)))
         (work (make-array +server-count+
                           :initial-contents (loop repeat +server-count+ for i from 2 collect i)))
         (golden (map 'vector (lambda (x) (* x 2)) work)))
    (unwind-protect
         (let ((results (make-array +server-count+ :initial-element nil)))
           ;; Synchronous
           (loop for i below (length work)
                 for connection in connections
                 do (setf (aref results i) (slime-eval `(* 2 ,(aref work i)) connection)))
           (is (equalp results golden))
           ;; Reset results.
           (loop for i below (length results) do (setf (aref results i) nil))
           ;; Asynchronous
           (loop for i below (length work)
                 for connection in connections
                 do (let ((index i))
                      (slime-eval-async `(* 2 ,(aref work i))
                                        connection
                                        (lambda (result) (setf (aref results index) result)))))
           (sleep 0.1)
           (is (equalp results golden)))
      (dolist (connection connections)
        (slime-close connection)))))

(deftest non-ascii-characters ()
  (swank:create-server :port +server-port+)
  (flet ((create-string (code)
           (concatenate 'string "hello " (string (code-char code)) " world")))
      (with-slime-connection (connection "localhost" +server-port+)
        (loop for code from 0 below 2000 by 100 do
          (let ((string (create-string code)))
            (is (string= (slime-eval string connection) string)))))))

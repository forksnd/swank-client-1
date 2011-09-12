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

(in-package #:common-lisp-user)

(defpackage #:swank-client-test-system
  (:documentation "System definition for testing the SWANK-CLIENT package.")
  (:use #:common-lisp #:asdf))

(in-package #:swank-client-test-system)

(defsystem swank-client-test
  :depends-on (:swank-client #:hu.dwim.stefil :swank)
  :components
  ((:file "swank-client_test")))

(defmethod perform ((operation test-op) (component (eql (find-system :swank-client-test))))
  (funcall (read-from-string "swank-client-test::test-swank-client")))
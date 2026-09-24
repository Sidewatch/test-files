;;;; A memoised Fibonacci and a small CLOS class, Common Lisp.
(defpackage :sample
  (:use :cl)
  (:export #:fib #:describe-account))
(in-package :sample)

(defvar *fib-cache* (make-hash-table))

(defun fib (n)
  "The nth Fibonacci number, memoised."
  (or (gethash n *fib-cache*)
      (setf (gethash n *fib-cache*)
            (if (< n 2) n (+ (fib (- n 1)) (fib (- n 2)))))))

(defclass account ()
  ((owner   :initarg :owner   :reader owner)
   (balance :initarg :balance :accessor balance :initform 0)))

(defmethod describe-account ((a account))
  (format nil "~a has ~,2f" (owner a) (balance a)))

(let ((acct (make-instance 'account :owner "Ada" :balance 120.5)))
  (incf (balance acct) (fib 10))          ; +55
  (format t "~a~%" (describe-account acct)))

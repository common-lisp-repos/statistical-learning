(cl:in-package #:cl-user)


(defpackage #:statistical-learning.random
  (:use #:cl #:statistical-learning.aux-package)
  (:nicknames #:sl.random)
  (:export
   #:discrete-distribution))

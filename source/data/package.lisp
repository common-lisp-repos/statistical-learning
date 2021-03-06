(cl:in-package #:cl-user)


(defpackage #:statistical-learning.data
  (:use #:cl #:statistical-learning.aux-package)
  (:nicknames #:sl.data)
  (:export
   #:split-vector
   #:split
   #:attributes-count
   #:universal-data-matrix
   #:double-float-data-matrix
   #:dispatch-data-matrix
   #:bind-data-matrix-dimensions
   #:data-matrix
   #:data-matrix-dimensions
   #:mref
   #:map-data-matrix
   #:make-data-matrix-like
   #:reduce-data-points
   #:iota-vector
   #:reshuffle
   #:select-random-indexes
   #:selecting-random-attributes
   #:selecting-random-indexes
   #:cross-validation-folds
   #:check-data-points
   #:make-data-matrix
   #:sample
   #:data-points-count))

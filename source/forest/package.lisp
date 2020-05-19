(cl:in-package #:cl-user)


(defpackage #:cl-grf.forest
  (:use #:cl #:cl-grf.aux-package)
  (:export
   #:classification-random-forest
   #:fundamental-random-forest
   #:leafs-for
   #:predict
   #:predictions-from-leafs
   #:tree-batch-size
   #:tree-sample-rate
   #:trees
   #:attributes
   #:forest-class
   #:random-forest-parameters
   ))

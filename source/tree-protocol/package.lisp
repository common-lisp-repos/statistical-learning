(cl:in-package #:cl-user)


(defpackage #:cl-grf.tree-protocol
  (:use #:cl #:cl-grf.aux-package)
  (:nicknames #:cl-grf.tp)
  (:export
   #:attribute
   #:attribute-indexes
   #:attribute-value
   #:depth
   #:force-tree
   #:force-tree*
   #:fundamental-leaf-node
   #:fundamental-node
   #:fundamental-training-state
   #:fundamental-tree-node
   #:fundamental-tree-training-parameters
   #:leafp
   #:leafs-for
   #:leaf-for
   #:root
   #:contribute-predictions
   #:left-node
   #:make-leaf
   #:make-leaf*
   #:make-node
   #:maximal-depth
   #:minimal-size
   #:parallel
   #:right-node
   #:split
   #:split*
   #:target-data
   #:training-data
   #:training-parameters
   #:training-state-clone
   #:treep
   #:trials-count
   #:tree-model
   #:extract-predictions
   #:visit-nodes))

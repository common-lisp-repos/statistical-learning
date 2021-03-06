(ql:quickload :statistical-learning)
(ql:quickload :vellum)

(cl:in-package #:cl-user)

(defpackage #:iris-som-example
  (:use #:cl #:statistical-learning.aux-package))

(cl:in-package #:iris-som-example)

;; loading data set
(defvar *data*
  (~> (vellum:copy-from :csv (~>> (asdf:system-source-directory :statistical-learning)
                                  (merge-pathnames "examples/iris.data"))
                        :header nil)
      (vellum:to-table :columns '((:alias sepal-length :type float)
                                  (:alias sepal-width :type float)
                                  (:alias petal-length :type float)
                                  (:alias petal-width :type float)
                                  (:alias class :type string)))))

(defvar *training-data*
  (~> *data*
      (vellum:select :columns '(:take-from sepal-length :take-to petal-width))
      (vellum:to-matrix :element-type 'double-float)))

(defparameter *training-parameters*
  (make 'sl.som:self-organizing-map
        :grid-dimensions '(4 4)
        :number-of-iterations 10000
        :initial-alpha 0.6d0
        :initial-sigma 2.0d0
        :decay sl.som:<linear-decay>
        :parallel nil))

(defparameter *model*
  (sl.mp:make-unsupervised-model *training-parameters* *training-data*))

(defparameter *positions* (sl.mp:predict *model* *training-data*))

(defparameter *with-positions*
  (~> *positions* cl-ds.utils:unfold-table (batches 2)
      (cl-ds.alg:on-each #'vector :key (curry #'map 'list #'truncate))
      (vellum:to-table :columns '((:alias position)))
      list
      (vellum:hstack *data* _)))

(defparameter *classes* (vellum:pipeline (*with-positions*)
                          (cl-ds.alg:group-by :test 'equal
                                              :key (vellum:brr position))
                          (cl-ds.alg:group-by :test 'equal
                                              :key (vellum:brr class))
                          cl-ds.alg:count-elements
                          (vellum:to-table :columns '((:alias position)
                                                      (:alas class)
                                                      (:alias count)))
                          (vellum:order-by 'position
                                           (curry #'cl-ds.utils:lexicographic-compare
                                                  #'< #'=))))


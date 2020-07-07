(cl:in-package #:sl.proxy-tree)


(defclass honest-tree (proxy-tree)
  ())


(defclass honest-state (proxy-state)
  ((%attributes :initarg :attributes
                :reader attributes)))


(defmethod cl-ds.utils:cloning-information append ((state honest-state))
  `((:attributes attributes)))


(defmethod sl.mp:sample-training-state* ((parameters honest-tree)
                                         state
                                         &key data-points
                                           train-attributes
                                           target-attributes
                                           initargs)
  (let* ((inner-sample (sl.mp:sample-training-state*
                        (inner parameters)
                        (inner state)
                        :data-points data-points
                        :target-attributes target-attributes
                        :initargs initargs)))
    (cl-ds.utils:quasi-clone* state
      :inner inner-sample
      :attributes (map '(vector fixnum)
                       (curry #'aref (attributes state))
                       train-attributes))))


(defmethod sl.mp:make-model* ((parameters honest-tree)
                              state)
  (bind ((inner-state (inner state))
         (training-data (sl.mp:train-data inner-state))
         (inner-parameters (inner parameters))
         (data-points-count (~> inner-state
                                sl.mp:data-points
                                length))
         (indexes (sl.data:reshuffle (sl.data:iota-vector data-points-count)))
         (division-indexes (take (truncate data-points-count 2)
                                 indexes))
         (adjust-indexes (drop (truncate data-points-count 2)
                               indexes))
         (attributes (attributes state))
         (division (sl.mp:sample-training-state inner-state
                                                :train-attributes attributes
                                                :data-points division-indexes))
         (adjust (sl.mp:sample-training-state inner-state
                                              :data-points adjust-indexes))
         (inner (inner parameters))
         (model (sl.mp:make-model* inner division))
         (root (sl.tp:root model))
         (splitter (sl.tp:splitter parameters))
         ((:flet assign-leaf (index))
          (cons index
                (sl.tp:leaf-for splitter root
                                training-data index)))
         ((:flet adjust-leaf (leaf.indexes))
          (bind (((leaf . indexes) leaf.indexes)
                 (no-fill-pointer (cl-ds.utils:remove-fill-pointer indexes)))
            (~> inner-parameters
                (sl.mp:sample-training-state* adjust :data-points no-fill-pointer)
                (sl.tp:initialize-leaf inner _ leaf)))))
    (~> (cl-ds.alg:on-each adjust-indexes #'assign-leaf)
        (cl-ds.alg:group-by :key #'cdr :test 'eq)
        (cl-ds.alg:to-vector :key #'car :element-type 'fixnum)
        (cl-ds:traverse #'adjust-leaf))
    model))


(defmethod sl.mp:make-training-state ((parameters honest-tree)
                                      &rest initargs
                                      &key attributes train-data &allow-other-keys)
  (let ((inner (apply #'sl.mp:make-training-state
                      (inner parameters)
                      :attributes nil
                      initargs)))
    (make 'honest-state
          :training-parameters parameters
          :attributes (or attributes (~> train-data
                                         sl.data:attributes-count
                                         sl.data:iota-vector))
          :inner inner)))


(defun honest (parameters)
  (make 'honest-tree
        :inner parameters))

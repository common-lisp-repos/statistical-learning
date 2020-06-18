(cl:in-package #:statistical-learning.tree-protocol)


(defmethod (setf training-parameters) :before (new-value state)
  (check-type new-value fundamental-tree-training-parameters))


(defmethod make-node (node-class &rest arguments)
  (apply #'make node-class arguments))


(defmethod (setf maximal-depth) :before (new-value
                                         training-parameters)
  (check-type new-value (integer 1 *)))


(defmethod (setf depth) :before (new-value training-parameters)
  (check-type new-value (integer 0 *)))


(defmethod (setf training-data) :before (new-value training-state)
  (statistical-learning.data:check-data-points new-value))


(defmethod treep ((node fundamental-tree-node))
  t)


(defmethod treep ((node fundamental-leaf-node))
  nil)


(defmethod force-tree* ((node fundamental-tree-node))
  (setf (left-node node) (~> node left-node lparallel:force)
        (right-node node) (~> node right-node lparallel:force))
  (unless (null (left-node node))
    (~> node left-node force-tree*))
  (unless (null (right-node node))
    (~> node right-node force-tree*))
  node)


(defmethod force-tree* ((node fundamental-leaf-node))
  node)


(defmethod cl-ds.utils:cloning-information append
    ((object tree-training-state))
  `((:depth depth)
    (:loss loss)
    (:attributes attribute-indexes)))


(defmethod split* :around ((training-parameters fundamental-tree-training-parameters)
                           training-state leaf)
  (let* ((training-data (sl.mp:training-data training-state))
         (depth (depth training-state))
         (attribute-indexes (attribute-indexes training-state))
         (loss (loss leaf))
         (maximal-depth (maximal-depth training-parameters))
         (minimal-size (minimal-size training-parameters)))
    (declare (type statistical-learning.data:data-matrix training-data)
             (type (integer 1 *) minimal-size))
    (if (or (< (statistical-learning.data:data-points-count training-data)
               (* 2 minimal-size))
            (emptyp attribute-indexes)
            (>= depth maximal-depth)
            (<= loss (minimal-difference training-parameters)))
        nil
        (call-next-method))))


(defmethod contribute-predictions* :before ((parameters fundamental-tree-training-parameters)
                                            (model tree-model)
                                            data
                                            state
                                            parallel)
  (unless (forced model)
    (force-tree model)))


(defmethod statistical-learning.mp:predict ((model tree-model)
                                            data
                                            &optional parallel)
  (~> (contribute-predictions model data nil parallel)
      extract-predictions))


(defmethod initialize-instance :after
    ((instance fundamental-tree-training-parameters)
     &rest initargs)
  (declare (ignore initargs))
  (let ((maximal-depth (maximal-depth instance))
        (minimal-size (minimal-size instance))
        (minimal-difference (minimal-difference instance))
        (trials-count (trials-count instance)))
    (parallel instance) ; here just to check if slot is bound
    (unless (integerp maximal-depth)
      (error 'type-error :expected 'integer
                         :datum maximal-depth))
    (unless (< 0 maximal-depth)
      (error 'cl-ds:argument-value-out-of-bounds
             :argument :maximal-depth
             :bounds '(< 0 :maximal-depth)
             :value maximal-depth))
    (unless (integerp minimal-size)
      (error 'type-error :expected 'integer
                         :datum minimal-size))
    (unless (<= 0 minimal-size)
      (error 'cl-ds:argument-value-out-of-bounds
             :argument :minimal-size
             :bounds '(<= 0 :minimal-size)
             :value minimal-size))
    (unless (integerp trials-count)
      (error 'type-error :expected 'integer
                         :datum trials-count))
    (unless (< 0 trials-count)
      (error 'cl-ds:argument-value-out-of-bounds
             :argument :trials-count
             :bounds '(< 0 :trials-count)
             :value trials-count))))


(defmethod sl.mp:sample-training-state* ((parameters fundamental-tree-training-parameters)
                                         state
                                         &key data-points train-attributes target-attributes
                                           initargs)
  (apply #'make (class-of state)
         :training-data (sl.data:sample (sl.mp:training-data state)
                                        :data-points data-points
                                        :attributes train-attributes)
         :target-data (sl.data:sample (sl.mp:target-data state)
                                      :data-points data-points
                                      :attributes target-attributes)
         :weights (if (null (sl.mp:weights state))
                      nil
                      (sl.data:sample (sl.mp:weights state)
                                      :data-points data-points))
         :attributes (if (null target-attributes)
                         (attribute-indexes state)
                         train-attributes)
         (append initargs (cl-ds.utils:cloning-list state))))


(defmethod make-leaf* ((parameters fundamental-tree-training-parameters)
                       state)
  (make 'fundamental-leaf-node))


(defmethod sl.tp:split*
    ((training-parameters fundamental-tree-training-parameters)
     training-state
     leaf)
  (declare (optimize (speed 3) (safety 0)))
  (bind ((training-data (sl.mp:training-data training-state))
         (trials-count (trials-count training-parameters))
         (minimal-difference (minimal-difference training-parameters))
         (score (loss leaf))
         (minimal-size (minimal-size training-parameters))
         (parallel (parallel training-parameters))
         (attributes (attribute-indexes training-state)))
    (declare (type fixnum trials-count)
             (type (simple-array fixnum (*)) attributes)
             (type double-float score minimal-difference)
             (type boolean parallel))
    (iterate
      (declare (type fixnum attempt left-length right-length
                     optimal-left-length optimal-right-length
                     optimal-attribute data-size)
               (type double-float
                     left-score right-score
                     minimal-score optimal-threshold))
      (with optimal-left-length = -1)
      (with optimal-right-length = -1)
      (with optimal-attribute = -1)
      (with minimal-score = most-positive-double-float)
      (with minimal-left-score = most-positive-double-float)
      (with minimal-right-score = most-positive-double-float)
      (with optimal-threshold = most-positive-double-float)
      (with data-size = (sl.data:data-points-count training-data))
      (with split-array = (sl.opt:make-split-array data-size))
      (with optimal-array = (sl.opt:make-split-array data-size))
      (for attempt from 0 below trials-count)
      (for (values attribute threshold) = (random-test attributes training-data))
      (for (values left-length right-length) = (fill-split-array
                                                training-data
                                                attribute
                                                threshold
                                                split-array))
      (when (or (< left-length minimal-size)
                (< right-length minimal-size))
        (next-iteration))
      (for (values left-score right-score) = (calculate-loss*
                                              training-parameters
                                              training-state
                                              split-array))
      (for split-score = (+ (* (/ left-length data-size) left-score)
                            (* (/ right-length data-size) right-score)))
      (when (< split-score minimal-score)
        (setf minimal-score split-score
              optimal-threshold threshold
              optimal-attribute attribute
              optimal-left-length left-length
              optimal-right-length right-length
              minimal-left-score left-score
              minimal-right-score right-score)
        (rotatef split-array optimal-array))
      (finally
       (let ((difference (- (the double-float score)
                            (the double-float minimal-score))))
         (declare (type double-float difference))
         (when (< difference minimal-difference)
           (return nil))
         (bind ((new-depth (~> training-state depth 1+))
                (new-attributes (subsample-vector attributes
                                                  optimal-attribute))
                ((:flet new-state (position size loss))
                 (split-training-state* training-parameters
                                        training-state
                                        optimal-array
                                        position
                                        size
                                        `(:depth ,new-depth :loss ,loss)
                                        optimal-attribute
                                        new-attributes))
                ((:flet subtree-impl (position
                                      size
                                      loss
                                      &aux (state (new-state position size loss))))
                 (~>> state make-leaf (split state)))
                ((:flet subtree (position size loss &optional parallel))
                 (if parallel
                     (lparallel:future (subtree-impl position size loss))
                     (subtree-impl position size loss))))
           (return (make-node 'fundamental-tree-node
                              :left-node (subtree sl.opt:left
                                                  optimal-left-length
                                                  minimal-left-score
                                                  parallel)
                              :right-node (subtree sl.opt:right
                                                   optimal-right-length
                                                   minimal-right-score)
                              :support data-size
                              :loss score
                              :attribute (aref attributes optimal-attribute)
                              :attribute-value optimal-threshold))))))))


(defmethod split-training-state* ((parameters fundamental-tree-training-parameters)
                                  state split-array
                                  position size arguments
                                  &optional attribute-index attribute-indexes)
  (bind ((cloning-list (cl-ds.utils:cloning-list state))
         (training-data (sl.mp:training-data state))
         (target-data (sl.mp:target-data state))
         (weights (sl.mp:weights state))
         (class (class-of state))
         (attributes (attribute-indexes state))
         (new-attributes (or attribute-indexes
                             (and attribute-index
                                  (subsample-vector attributes
                                                    attribute-index))
                             attributes)))
    (apply #'make class
           :weights (if (null weights)
                        nil
                        (subsample-array weights size
                                         split-array position
                                         nil))
           :training-data (subsample-array training-data
                                           size split-array
                                           position attribute-index)
           :target-data (subsample-array target-data
                                         size split-array
                                         position nil)
           :attributes new-attributes
           (append arguments cloning-list))))


(defmethod sl.mp:sample-training-state* ((parameters fundamental-tree-training-parameters)
                                         (state tree-training-state)
                                         &key
                                           data-points
                                           train-attributes
                                           target-attributes
                                           initargs)
  (let ((cloning-list (cl-ds.utils:cloning-list state))
        (training-data (sl.mp:training-data state))
        (target-data (sl.mp:target-data state))
        (weights (sl.mp:weights state))
        (class (class-of state)))
    (apply #'make class
           :weights (if (null weights)
                        nil
                        (sl.data:sample weights :data-points data-points))
           :training-data (sl.data:sample training-data
                                          :data-points data-points
                                          :attributes train-attributes)
           :target-data (sl.data:sample target-data
                                        :data-points data-points
                                        :attributes target-attributes)
           :attributes (if (null train-attributes)
                           (attribute-indexes state)
                           (map '(vector fixnum)
                                (curry #'aref (attribute-indexes state))
                                train-attributes))
           (append initargs cloning-list))))

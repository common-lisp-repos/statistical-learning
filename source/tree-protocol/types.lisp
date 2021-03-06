(cl:in-package #:statistical-learning.tree-protocol)


(defclass fundamental-splitter (sl.common:proxy-enabled)
  ())


(defclass random-attribute-splitter (fundamental-splitter)
  ())


(defclass distance-splitter (fundamental-splitter)
  ((%distance-function :initarg :distance-function
                       :reader distance-function)
   (%repeats :initarg :repeats
             :reader repeats)
   (%iterations :initarg :iterations
                :reader iterations))
  (:default-initargs :iterations 2))


(defclass fundamental-node ()
  ())


(defclass fundamental-tree-node (fundamental-node)
  ((%left-node :initarg :left-node
               :accessor left-node)
   (%right-node :initarg :right-node
                :accessor right-node)
   (%point :initarg :point
           :accessor point)))


(defclass fundamental-leaf-node (fundamental-node)
  ())


(defclass standard-leaf-node (fundamental-leaf-node fundamental-node)
  ((%predictions :initarg :predictions
                 :accessor predictions))
  (:default-initargs :predictions nil))


(defclass fundamental-tree-training-parameters
    (statistical-learning.mp:fundamental-model-parameters)
  ())


(defclass standard-tree-training-parameters (fundamental-tree-training-parameters)
  ((%maximal-depth :initarg :maximal-depth
                   :reader maximal-depth)
   (%minimal-difference :initarg :minimal-difference
                        :reader minimal-difference)
   (%minimal-size :initarg :minimal-size
                  :reader minimal-size)
   (%trials-count :initarg :trials-count
                  :reader trials-count)
   (%parallel :initarg :parallel
              :reader parallel)
   (%splitter :initarg :splitter
              :reader splitter))
  (:default-initargs
   :splitter (make-instance 'random-attribute-splitter)))


(defclass tree-training-state (sl.mp:fundamental-training-state)
  ((%attribute-indexes :initarg :attributes
                       :accessor attribute-indexes)
   (%data-points :initarg :data-points
                 :accessor sl.mp:data-points)
   (%depth :initarg :depth
           :reader depth)
   (%loss :initarg :loss
          :reader loss)
   (%target-data :initarg :target-data
                 :reader sl.mp:target-data)
   (%weights :initarg :weights
             :reader sl.mp:weights)
   (%split-point :initarg :split-point
                 :accessor split-point)
   (%optimal-split-point :initarg :optimal-split-point
                         :accessor optimal-split-point)
   (%train-data :initarg :train-data
                :reader sl.mp:train-data))
  (:default-initargs :depth 0
                     :attributes nil
                     :split-point nil
                     :optimal-split-point nil
                     :weights nil
                     :data-points nil))


(defclass tree-model (statistical-learning.mp:supervised-model)
  ((%root :initarg :root
          :writer write-root
          :reader root)
   (%forced :initarg :forced
            :accessor forced))
  (:default-initargs :forced nil))


(defclass contributed-predictions ()
  ((%training-parameters :initarg :training-parameters
                         :reader sl.mp:training-parameters)
   (%contributions-count :initarg :contributions-count
                         :accessor contributions-count)
   (%indexes :initarg :indexes
             :reader indexes)
   (%sums :initarg :sums
          :reader sums))
  (:default-initargs :contributions-count 0))

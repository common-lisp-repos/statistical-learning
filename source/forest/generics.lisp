(cl:in-package #:cl-grf.forest)


(defgeneric forest-class (random-forest-parameters))
(defgeneric trees (random-forest))
(defgeneric attributes (random-forest))
(defgeneric trees-count (random-forest-parameters))
(defgeneric tree-attributes-count (random-forest-parameters))
(defgeneric parallel (parameters))
(defgeneric tree-parameters (parameters))
(defgeneric tree-sample-rate (parameters))
(defgeneric tree-batch-size (parameters))
(defgeneric weights-calculator (training-parameters parallel weights
                                train-data target-data))

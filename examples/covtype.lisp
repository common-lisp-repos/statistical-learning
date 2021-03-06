(ql:quickload :statistical-learning)
(ql:quickload :vellum)

(cl:in-package #:cl-user)

(defpackage #:covtype-example
  (:use #:cl #:statistical-learning.aux-package))

(in-package #:covtype-example)

(defvar *data*
  (~> (vellum:copy-from :csv (~>> (asdf:system-source-directory :statistical-learning)
                                  (merge-pathnames "examples/covtype.data"))
                        :header nil)
      (vellum:to-table :columns '((:alias elevation :type integer)
                                  (:alias aspect :type integer)
                                  (:alias slope :type integer)
                                  (:alias Horizontal_Distance_To_Hydrology :type number)
                                  (:alias Vertical_Distance_To_Hydrology :type number)
                                  (:alias Horizontal_Distance_To_Roadways :type number)
                                  (:alias Hillshade_9am :type integer)
                                  (:alias Hillshade_Noon :type integer)
                                  (:alias Hillshade_3pm :type integer)
                                  (:alias Horizontal_Distance_To_Fire_Points :type integer)
                                  (:alias Wilderness_Area_1 :type integer)
                                  (:alias Wilderness_Area_2 :type integer)
                                  (:alias Wilderness_Area_3 :type integer)
                                  (:alias Wilderness_Area_4 :type integer)
                                  (:alias Soil_Type_1 :type integer)
                                  (:alias Soil_Type_2 :type integer)
                                  (:alias Soil_Type_3 :type integer)
                                  (:alias Soil_Type_4 :type integer)
                                  (:alias Soil_Type_5 :type integer)
                                  (:alias Soil_Type_6 :type integer)
                                  (:alias Soil_Type_7 :type integer)
                                  (:alias Soil_Type_8 :type integer)
                                  (:alias Soil_Type_9 :type integer)
                                  (:alias Soil_Type_10 :type integer)
                                  (:alias Soil_Type_11 :type integer)
                                  (:alias Soil_Type_12 :type integer)
                                  (:alias Soil_Type_13 :type integer)
                                  (:alias Soil_Type_14 :type integer)
                                  (:alias Soil_Type_15 :type integer)
                                  (:alias Soil_Type_16 :type integer)
                                  (:alias Soil_Type_17 :type integer)
                                  (:alias Soil_Type_18 :type integer)
                                  (:alias Soil_Type_19 :type integer)
                                  (:alias Soil_Type_20 :type integer)
                                  (:alias Soil_Type_21 :type integer)
                                  (:alias Soil_Type_22 :type integer)
                                  (:alias Soil_Type_23 :type integer)
                                  (:alias Soil_Type_24 :type integer)
                                  (:alias Soil_Type_25 :type integer)
                                  (:alias Soil_Type_26 :type integer)
                                  (:alias Soil_Type_27 :type integer)
                                  (:alias Soil_Type_28 :type integer)
                                  (:alias Soil_Type_29 :type integer)
                                  (:alias Soil_Type_30 :type integer)
                                  (:alias Soil_Type_31 :type integer)
                                  (:alias Soil_Type_32 :type integer)
                                  (:alias Soil_Type_33 :type integer)
                                  (:alias Soil_Type_34 :type integer)
                                  (:alias Soil_Type_35 :type integer)
                                  (:alias Soil_Type_36 :type integer)
                                  (:alias Soil_Type_37 :type integer)
                                  (:alias Soil_Type_38 :type integer)
                                  (:alias Soil_Type_39 :type integer)
                                  (:alias Soil_Type_40 :type integer)
                                  (:alias Cover_Type :type integer))
                       :body (vellum:body (cover_type horizontal_distance_to_roadways)
                               (decf cover_type)))))

(defvar *cover-types* ; 7
  (vellum:with-table (*data*)
    (bind (((min . max) (cl-ds.alg:extrema *data* #'< :key
                                           (vellum:brr cover_type))))
      (assert (zerop min))
      (1+ (- max min)))))

(defvar *train-data*
  (vellum:to-matrix (vellum:select *data*
                      :columns '(:take-to soil_type_40))
                    :element-type 'double-float))

(defvar *target-data*
  (vellum:to-matrix (vellum:select *data*
                      :columns '(:v cover_type))
                    :element-type 'double-float))

(defparameter *training-parameters*
  (make 'statistical-learning.dt:classification
        :optimized-function (sl.opt:gini-impurity *cover-types*)
        :maximal-depth 30
        :minimal-difference 0.00001d0
        :minimal-size 10
        :trials-count 80
        :parallel t))

(defparameter *forest-parameters*
  (make 'statistical-learning.ensemble:random-forest
        :trees-count 250
        :parallel t
        :weights-calculator-class 'sl.ensemble:dynamic-weights-calculator
        :tree-batch-size 5
        :tree-attributes-count 50
        :tree-sample-rate 0.2
        :tree-parameters *training-parameters*))

(defparameter *confusion-matrix*
  (statistical-learning.performance:cross-validation *forest-parameters*
                                                     2
                                                     *train-data*
                                                     *target-data*
                                                     :parallel t))

(print (statistical-learning.performance:accuracy *confusion-matrix*)) ; 0.80

(~> (make 'statistical-learning.ensemble:gradient-boost-ensemble
          :trees-count 250
          :parallel t
          :tree-batch-size 5
          :tree-attributes-count 50
          :shrinkage 0.2d0
          :tree-sample-rate 0.2
          :tree-parameters (make 'sl.gbt:classification
                                 :optimized-function (sl.opt:k-logistic *cover-types*)
                                 :maximal-depth 25
                                 :minimal-size 10
                                 :minimal-difference 0.00001d0
                                 :trials-count 50
                                 :parallel t))
    (statistical-learning.performance:cross-validation 2
                                                       *train-data*
                                                       *target-data*
                                                       :parallel t)
    statistical-learning.performance:accuracy
    print) ; 0.84

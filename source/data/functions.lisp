(cl:in-package #:cl-grf.data)


(declaim (inline attributes-count))
(defun attributes-count (data-matrix)
  (check-type data-matrix data-matrix)
  (array-dimension data-matrix 1))


(declaim (inline data-points-count))
(defun data-points-count (data-matrix)
  (check-type data-matrix data-matrix)
  (array-dimension data-matrix 0))


(defun data-matrix-dimensions (data-matrix)
  (check-type data-matrix data-matrix)
  (array-dimensions data-matrix))


(declaim (inline mref))
(defun mref (data-matrix data-point attribute)
  (check-type data-matrix data-matrix)
  (aref data-matrix data-point attribute))


(declaim (inline (setf mref)))
(defun (setf mref) (new-value data-matrix data-point attribute)
  (check-type data-matrix data-matrix)
  (setf (aref data-matrix data-point attribute) new-value))


(defun make-data-matrix (data-points-count attributes-count)
  (check-type data-points-count fixnum)
  (check-type attributes-count fixnum)
  (make-array `(,data-points-count ,attributes-count)
              :initial-element 0.0d0
              :element-type 'double-float))


(-> sample (data-matrix &key
                        (:data-points (or null (simple-array fixnum (*))))
                        (:attributes (or null (simple-array fixnum (*)))))
    data-matrix)
(defun sample (data-matrix &key data-points attributes)
  (declare (optimize (speed 3) (safety 0)))
  (check-type data-matrix data-matrix)
  (assert (or data-points attributes))
  (cl-ds.utils:cases ((null attributes)
                      (null data-points))
    (iterate
      (declare (type fixnum i attributes-count data-points-count))
      (with attributes-count = (if (null attributes)
                                   (attributes-count data-matrix)
                                   (length attributes)))
      (with data-points-count = (if (null data-points)
                                    (data-points-count data-matrix)
                                    (length data-points)))
      (with result = (make-data-matrix data-points-count
                                       attributes-count))
      (for i from 0 below data-points-count)
      (iterate
        (declare (type fixnum j))
        (for j from 0 below attributes-count)
        (setf (mref result i j)
              (mref data-matrix
                    (if (null data-points) i (aref data-points i))
                    (if (null attributes) j (aref attributes j)))))
      (finally (return result)))))

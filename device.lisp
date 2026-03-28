;;;; -*- Mode: Lisp -*-

;;;; device.lisp
;;;;
;;;; Device (i.e., a 3270) representation for minimal 3720 data stream
;;;; emulation.
;;;;
;;;; See the file COPYING for copyright and licensing information.
;;;;
;;;; Notes:
;;;;
;;;; Just roughly following Matthew R. Wilson's API.

(in-package "CL3270")

(defclass device-info ()
  ((rows      :initarg :rows      :accessor rows      :initform 0         :type (mod 1024))
   (cols      :initarg :cols      :accessor cols      :initform 0         :type (mod 1024))
   (term-type :initarg :term-type :accessor term-type :initform "IBM 3270" :type string)
   (codepage  :initarg :codepage  :accessor codepage  :initform nil       :type (or null codepage))
   (tls-p     :initarg :tls-p     :accessor tls-p     :initform nil       :type boolean))
  (:documentation "The Device Info Class.

Minimal information about the device, i.e., the 3270 terminal."))

(defun device-info-p (object)
  (typep object 'device-info))


(defun alt-dimensions (d)
  (declare (type device-info d))
  (values (rows d) (cols d)))

;;;; end of file -- device.lisp

;;;; -*- Mode: Lisp; Coding: utf-8 -*-

;;;; example4.lisp
;;;; cl3270 example 4 from Matthew Wilson's GO code.
;;;;
;;;; See the file COPYING in the top folder for copyright and
;;;; licensing information.
;;;;
;;;; Notes:
;;;;
;;;; This example works only in Lispworks for the time being.
;;;; Eventually there will be a portable Multiprocessing and MAILBOX
;;;; implementation to fill in for GO channels (yes, I know about
;;;; Bordeaux Threads and ChanL).


(in-package "CL3270.E4")

;;; Declarations and definitions.

(declaim (ftype cl3270:tx login main-menu))


(defclass global ()
  ((usercount :initarg :usercount :accessor global-usercount :initform 0)
   (countlock :initarg :countlock :accessor global-countlock :initform (mp:make-lock :name "E4 Global Lock"))))
          

(defclass session (cl3270:abstract-session)
  ((db     :initarg :db     :accessor session-db     :initform nil)
   (user   :initarg :user   :accessor session-user   :initform nil)
   (global :initarg :global :accessor session-global :initform nil)))


(defun cl3270-example4 (&key (handler 'cl3270-handle-4) (host "127.0.0.1") (debug t))
  (prog1 ; Why did I use PROG1 in the first place?
      (let ((dbconn (db-connect)) ; Fake DB.
            (gblstate (make-instance 'global)) ; Need to set up the lock.
            )
        (usocket:with-socket-listener (conn host 3270
                                            :element-type 'octet
                                            :reuse-address t
                                            )
          (format t ";;; CL3270: example 4: server listening on host ~S, port 3270...~%"
                  host)
          (usocket:with-connected-socket (c (usocket:socket-accept conn))
            (let ((*do-debug* debug))
              (funcall handler c dbconn gblstate))))
        (format t ";;; CL3270: example 4: server closed~%"))))



(defun cl3270-handle-4 (c db global)
  ;; C is a USOCKET:SOCKET

  (declare (type usocket:stream-usocket c))

  (unwind-protect

      (let ((state (make-instance 'session :db db :global global)))
        (declare (ignorable state))

        (mp:with-lock ((global-countlock global))
          (incf (global-usercount global)))
      
        (multiple-value-bind (devinfo err)
            (negotiate-telnet c)

          (when err
            (let ((*do-debug* t))
              (dbgmsg "HANDLE 4: error: TR generated a ~S~%" err)
              (return-from cl3270-handle-4 nil)))

          (dbgmsg "telnet negotiated.~2%")

          (when (setq err (run-transactions c devinfo #'login nil state))
            (let ((*do-debug* t))
              (dbgmsg "HANDLE 4: error: RUN-TRANSACTIONS generated a ~S~%" err)))
          ))

    ;; Cleanup...

    (dbgmsg "unlocking and closing connection.~%")

    (mp:with-lock ((global-countlock global))
      (decf (global-usercount global)))

    (usocket:socket-close c))
  )


;;;; end of file -- example4.lisp

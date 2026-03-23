;;;; -*- Mode: Lisp -*-

;;;; tls.lisp
;;;;
;;;; TLS support for CL3270: dedicated TLS port and STARTTLS negotiation.

(in-package "CL3270")

(defclass tls-config ()
  ((certificate-file :initarg :certificate-file :accessor tls-config-certificate-file
                     :initform nil :type (or null string pathname))
   (key-file :initarg :key-file :accessor tls-config-key-file
             :initform nil :type (or null string pathname))
   (key-password :initarg :key-password :accessor tls-config-key-password
                 :initform nil :type (or null string))
   (starttls-p :initarg :starttls-p :accessor tls-config-starttls-p
               :initform t :type boolean))
  (:documentation "Configuration for TLS connections."))

(defun wrap-socket-with-tls (socket tls-config)
  "Upgrade SOCKET's stream to TLS using CL+SSL.
Returns the socket with its stream replaced by an SSL stream."
  (declare (type usocket:stream-usocket socket)
           (type tls-config tls-config))
  (let* ((raw-stream (usocket:socket-stream socket))
         (ssl-stream (cl+ssl:make-ssl-server-stream
                      raw-stream
                      :certificate (tls-config-certificate-file tls-config)
                      :key (tls-config-key-file tls-config))))
    (setf (usocket:socket-stream socket) ssl-stream)
    socket))

(defun negotiate-starttls (c tls-config)
  "Offer STARTTLS to the client on connection C.
If the client accepts (WILL START-TLS), perform the TLS handshake.
If the client declines (WONT START-TLS), continue in plain mode.
Returns T if TLS was established, NIL otherwise."
  (declare (type usocket:stream-usocket c)
           (type tls-config tls-config))
  ;; Send: IAC DO START-TLS
  (send-sequence (bufferize +iac+ +do+ +start-tls+) c)
  ;; Read response
  (let ((buf (make-array 3 :element-type 'octet :initial-element 0))
        (ss (usocket:socket-stream c)))
    (read-sequence buf ss)
    (unless (and (= (aref buf 0) +iac+)
                 (= (aref buf 1) +will+)
                 (= (aref buf 2) +start-tls+))
      ;; Client declined or sent unexpected response -- continue plain
      (return-from negotiate-starttls nil))
    ;; Client accepted. Send: IAC SB START-TLS FOLLOWS IAC SE
    (send-sequence (bufferize +iac+ +sb+ +start-tls+ +start-tls-follows+ +iac+ +se+) c)
    ;; Read client's SB FOLLOWS: IAC SB START-TLS FOLLOWS IAC SE
    (let ((sb-buf (make-array 6 :element-type 'octet :initial-element 0)))
      (read-sequence sb-buf ss)
      (unless (and (= (aref sb-buf 0) +iac+)
                   (= (aref sb-buf 1) +sb+)
                   (= (aref sb-buf 2) +start-tls+)
                   (= (aref sb-buf 3) +start-tls-follows+)
                   (= (aref sb-buf 4) +iac+)
                   (= (aref sb-buf 5) +se+))
        (return-from negotiate-starttls nil)))
    ;; Perform TLS handshake
    (wrap-socket-with-tls c tls-config)
    t))

;;;; end of file -- tls.lisp

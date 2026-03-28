;;;; -*- Mode: Lisp; Coding: utf-8 -*-

;;;; codepage.lisp
;;;;
;;;; Codepage representations for minimal 3720 data stream
;;;; emulation.
;;;;
;;;; See the file COPYING for copyright and licensing information.
;;;;
;;;; Notes:
;;;;
;;;; Again, just roughly following Matthew R. Wilson's API.
;;;;
;;;; Probably, all of this can be replaced by BABEL, but not yet.

(in-package "CL3270")

(deftype codepage-id ()
  "A Codepage ID.

Notes:

According to Wikipedia (https://https://en.wikipedia.org/wiki/Code_page)
the IBM convention was to use a 16 bits number to identify a codepage.
Hence the (MOD #x10000) limitation.

Of course, vendors messed up, as the Wikipedia page explains."

  '(mod #x10000))


(defclass codepage ()
  (;; (id 0 :type codepage-id :read-only t) ; LW complains.
   (id       :initarg :id       :reader codepage-id       :initform 0                      :type codepage-id)
   (name     :initarg :name     :reader codepage-name     :initform ""                     :type string)

   ;; EBCDIC byte to Unicode code point for bytes #x00 to #xff.
   ;; Let's just do codes.

   (e2u      :initarg :e2u      :reader codepage-e2u      :initform nil                    :type (or null (vector rune 256)))

   ;; Unicode code point to EBCDIC byte for code points #x00 to #xff.

   (u2e      :initarg :u2e      :reader codepage-u2e      :initform nil                    :type (or null (vector octet 256)))

   ;; Map of Unicode code points to EBCDIC bytes for code points above #xff.

   (high-u2e :initarg :high-u2e :reader codepage-high-u2e :initform (make-dict :test #'eql) :type dict)

   ;; The EBCDIC substitute character to use if there is no EBCDIC character
   ;; for the requested Unicode code point (typically #x3f).

   (esub     :initarg :esub     :reader codepage-esub     :initform #x3f                   :type octet)

   ;; The "graphic escape" EBCDIC byte (is it ever anything other than 0x0E?).

   (ge       :initarg :ge       :reader codepage-ge       :initform #x0e                   :type octet)

   ;; Graphic escape codepage EBCDIC byte to Unicode code point for bytes
   ;; #x00 to #xff.  Use character `#\Replacement-Character` (`#\Ufffd`)
   ;; for unmapped bytes.

   (ge2u     :initarg :ge2u     :reader codepage-ge2u     :initform nil                    :type (or null (vector character 256)))

   ;; Map of Unicode code points to graphic escape EBCDIC bytes.

   (u2ge     :initarg :u2ge     :reader codepage-u2ge     :initform (make-dict :test #'eql) :type dict))

  (:documentation "The Codepage Class."))

(defun codepage-p (object)
  (typep object 'codepage))


;;; Functions and methods.

(defmethod print-object ((cp codepage) stream)
  (print-unreadable-object (cp stream)
    (format stream "CODEPAGE ~D ~S"
            (codepage-id cp)
            (codepage-name cp))))


;;; Codepage construction and handling functions etc.

(defparameter *codepages* (make-dict :test #'equal)
  "The codepage table.")


(define-condition no-codepage-error (error)
  ((id :reader no-codepage-error-id
       :initarg :id
       :initform 0
       :type codepage-id))
  (:report (lambda (nce stream)
             (format stream "codepage ~d is unknown."
                     (no-codepage-error-id nce))))
  (:documentation
   "The No Codpage Error Condition.

This error is signaled when codepage ID (initarg :ID) was not found in
the internal data structures.

See Also:

*CODEPAGES* hash table."))


(define-condition unencodable-character (error)
  ((character :reader unencodable-character-char
              :initarg :character
              :type character)
   (codepage :reader unencodable-character-codepage
             :initarg :codepage
             :type codepage))
  (:report (lambda (c stream)
             (format stream "Character ~S (U+~4,'0X) cannot be encoded in ~A."
                     (unencodable-character-char c)
                     (char-code (unencodable-character-char c))
                     (codepage-name (unencodable-character-codepage c)))))
  (:documentation
   "Signaled when a character has no mapping in the target codepage.

Established restarts:
  USE-SUBSTITUTE - Replace the character with the codepage's substitute byte."))


(defun make-codepage (&rest keys &key &allow-other-keys)
  "Create a CODEPAGE and inserts it isn the internal data structures.

KEYS are passed to the internal CODEPAGE constructor.

See Also:

*CODEPAGES*."

  (let ((cp (apply #'make-instance 'codepage keys)))
    (setf (gethash (codepage-id cp) *codepages*) cp)))


(defun get-codepage (cp-id &optional (errorp t))
  "Get a CODEPAGE given an identified CP-ID.

Exceptional Situations:

If ERRORP is non-NIL (the default) and codepage CP-ID is not found,
then a NO-CODEPAGE-ERROR is signaled.

See Also:

*CODEPAGES*."

  (multiple-value-bind (cp cp-found)
      (gethash cp-id *codepages*)
    (cond (cp-found (values cp t))
          ((null errorp) (values nil nil))
          (t (error 'no-codepage-error :id cp-id)))))


(defun remove-codepage (cp-id)
  "Remove codepage CP-ID from the iternal data structures."

  (remhash cp-id *codepages*))


(defun list-codepages ()
  "Return a list of the known codepages."
  (dict-values *codepages*))


(defun clean-codepages ()
  "Clean the internal codepage repository.

Notes:

Codepages that are values of variables are not affected.

See Also:

*CODEPAGES*."
  (clrhash *codepages*))


;;; decode-ebcdic

(defun decode-ebcdic (cp bytes)
  "Decode an EBCDIC byte array into a 'character' string.

The decoding handles graphic escape to codepage CP310 as needed."

  (declare (type codepage cp)
           (type (vector octet) bytes))
  
  ;; #+sbcl
  ;; (declare (optimize (safety 0))) ; SBCL is too fussy (and wrong on 2.2.9)

  (let ((runes (make-array (length bytes)
                           :fill-pointer 0
                           :element-type 'character
                           :initial-element #\ufffd ; Replacement Character.
                           ))
        (escape nil)
        (ge2u (codepage-ge2u cp))
        (e2u  (codepage-e2u cp))
        (ge   (codepage-ge cp))
        (repl-char-code (char-code #\ufffd)) ; Replacement Character Code.
        (sub-char (code-char #x1a)) ; Substitution Character.
        )
    (declare (type (vector character) runes)
             (type boolean escape)
	     (type (or null (vector rune 256)) e2u)
             (type (or null (vector character 256)) ge2u)
             (type rune repl-char-code)
             (type octet ge) ; octet
             (type character sub-char)
             )

    (loop for b of-type octet across bytes
          if escape
            do (let* ((r (aref ge2u b))
		      (rcc (char-code r))
		      )
                 (declare (type character r)
			  (type rune rcc)) ; SBCL is right, but toooooo fussy.

                 (setq escape nil)
                 (if (/= rcc repl-char-code)

                     (vector-push r runes)
                     (vector-push sub-char runes) ; Unicode "substitute".
                     ))
          else
            ;; Enter graphic escape mode if necessary.
            do (if ;; (/= b (char-code ge))
                   (/= b ge)
                   ;; (vector-push (the character (code-char (aref e2u b))) runes)
		   (vector-push (code-char (aref e2u b)) runes)
                   (setf escape t)))

    ;; Finally return the string (UNICODE).

    (with-output-to-string (s nil :element-type 'character)
      (loop for r of-type character across runes do (write-char r s)))))


;;; encode-characters

(defun encode-characters (cp s)
  "Encode CHARACTER string S into an EBCDIC byte array.

The encoding will handle graphic escape to CP310 as needed.
Signals UNENCODABLE-CHARACTER for characters that have no mapping,
with a USE-SUBSTITUTE restart that replaces them with the codepage's
substitute byte."

  (declare (type codepage cp)
           (type string s))

  (let ((u2e    (codepage-u2e cp))
        (high2e (codepage-high-u2e cp))
        (u2ge   (codepage-u2ge cp))
        (ge     (codepage-ge cp))
        (esub   (codepage-esub cp)))
    (declare (type (vector octet) u2e)
             (type hash-table high2e u2ge)
             (type octet ge esub))

    (loop with out = (make-buffer :capacity (length s))
          with u2e-len of-type fixnum = (length u2e)

          for c of-type character across s
          for cc = (char-code c)

          do (cond
               ;; Direct mapping for code points < 256
               ((< cc u2e-len)
                (write-buffer out (aref u2e cc)))

               ;; High Unicode to EBCDIC (no graphic escape needed)
               ((multiple-value-bind (byte found) (gethash c high2e)
                  (when found
                    (write-buffer out byte)
                    t)))

               ;; Graphic escape mapping via CP310
               ((multiple-value-bind (byte found) (gethash c u2ge)
                  (when found
                    (write-buffer out ge)
                    (write-buffer out byte)
                    t)))

               ;; No mapping - signal with restart
               (t
                (restart-case
                    (error 'unencodable-character :character c :codepage cp)
                  (use-substitute ()
                    :report "Replace with the codepage substitute character."
                    (write-buffer out esub)))))

          finally (return-from encode-characters out))))


;;;; end of file -- codepage.lisp

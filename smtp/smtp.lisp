;;; -*- Mode: lisp; Syntax: ansi-common-lisp; Package:  smtp; Base: 10 -*-
;;;
;;; Copyright Rainer Joswig and John C. Mallery,  1995, 2006.
;;; All rights reserved.
;;;
;;;------------------------------------------------------------------- 
;;;
;;;  SIMPLE SMTP MAILER
;;;
;;; Just send mail right now. -- JCMa 8/3/1995.
;;; Replace format with faster string writing functions will help if
;;; this ever gets heavy use.  8/3/95 -- JCMa.
;;; Does CRAM-MD5 Authentication now. 2003-10-06, Rainer Joswig

(in-package :smtp)


;;;------------------------------------------------------------------- 
;;;
;;; PLATFORM MAILER-STREAM
;;;

;; this should use the http stream so that we have faster buffer-level
;; operations supported. It should be resourced so we don't cons for effect.
;; 10/9/97 -- JCMa.

;; The Genera message stream is lossage. The MCL wrapper on tyo is slow.  Both
;; should be implemented for real on a stream inheriting from http stream.
;; These kludges will just slow things down and fail to work on the margin.
;; 4/21/98 -- JCMa.
;;
;; Addec CC and BCC awareness -- JCMa 9/4/2006


;;; MAILER-STREAM

#+MCL
(defclass mailer-stream (ccl::opentransport-tcp-stream)
  ((newline-p     :initform t)))


#+franz-inc
(deftype acl-mailer-stream () 'ipc:tcp-client-stream)
#+franz-inc
(setf (find-class 'acl-mailer-stream) (find-class 'ipc:tcp-client-stream))

;;; stream-tyi

#+MCL
(defmethod stream-tyi ((stream mailer-stream))
  (let ((char (call-next-method)))
    (cond ((and (eql char #\Return)
		(eql (peek-char nil stream) #\Linefeed))
	   (read-char stream)
	   #\Return)
	  (t char)))) 


;;; stream-tyo

#+MCL
(defmethod stream-tyo ((stream mailer-stream) ch)
  (with-slots (newline-p) stream
    (when (and newline-p (eql ch #\.))
      (call-next-method stream #\.))
    (setq newline-p (eql ch #\Return))
    (call-next-method stream ch)))

;;; genera stuff

#+genera
(scl:defflavor message-body-stream
	((output-stream nil)
	 (newline-p     t))
	()
  (:initable-instance-variables output-stream))

#+genera
(scl:defmethod (:tyo message-body-stream) (ch)
  (when (and newline-p (char= ch #\.))
    (scl:send output-stream :tyo #\.))
  (setq newline-p (char= ch #\return))
  (scl:send output-stream :tyo ch))

#+genera
(scl:defmethod (:string-out message-body-stream) (vector &optional (start 0) (end (length vector)))
  (www-utils:with-fast-array-references ((vector vector vector))
    (loop for i from start below end
	  do (scl:send scl:self :tyo (svref vector i)))))

#+genera
(scl:defmethod (:force-output message-body-stream) ()
  (scl:send output-stream :force-output))


;;; with-message-body-encoding

#+Genera 
(defmacro with-message-body-encoding ((stream output-stream) &body body)
  `(let ((,stream (scl:make-instance 'message-body-stream :output-stream ,output-stream)))
     . ,body))

#-(or Genera (and LispWorks (not LispWorks3.2)))
(defmacro with-message-body-encoding ((stream output-stream) &body body)
  `(let ((,stream ,output-stream))
     . ,body))

;;; open-mailer-stream

(declaim (inline %open-mailer-stream))

#+MCL
(defun %open-mailer-stream (host port args)
  (apply #'make-instance 'mailer-stream :host host :port port args))

#+Genera
(defun %open-mailer-stream (host port args)
  (declare (ignore args))
  (tcp:open-tcp-stream host port :ascii-translation t))

#+Franz-Inc
(defmethod %open-mailer-stream (host port &rest args)
  #+(and Allegro (not (version>= 5 0)))
  (make-instance 'acl-mailer-stream :host host :port port)
  #+ACLPC
  (socket:make-socket :remote-host host :remote-port port)
  #+ACL5
  (change-class (socket:make-socket :remote-host host :remote-port port) 'ipc:tcp-client-stream))

;;;------------------------------------------------------------------- 
;;;
;;; 
;;;

(defvar *send-mail-locally* nil
  "When set to T, causes all mail to be routed through the local mailer.")

(defvar *local-mailer-strings* nil
  "Substrings for identifing local mail address. (to prevent loop back problems)")

(defparameter *local-mail-host* nil
   "The local store and forward mail host at the local site.
This is the domain name of the mail host. It may also by the IP address.
If this is NIL, no mail will be sent by functions REPORT-BUG and SEND-MAIL-FROM.")

(defparameter *network-mail-host* nil
   "The primary store and forward mail host at the local site.
This is the domain name of the mail host. It may also by the IP address.
If this is NIL, no mail will be sent by functions REPORT-BUG and SEND-MAIL-FROM.")

(defvar *store-and-forward-mail-hosts* nil
   "This is a list of all store and forward mail hosts accessible from the site.
This mail hosts will be used whenever the primary mail host is unaccessible.
Mail hosts should be listed in decreasing order of priority.")

(defvar *smtp-authentication-method* nil
  "Symbol, one of NIL or :CRAM-MD5.")

(defvar *smtp-authentication-user* nil
  "The username (a string) for SMTP authentication.")

(defvar *smtp-authentication-password* nil
  "The password (a string) for SMTP authentication.")

(defun store-and-forward-mailer-hosts ()
   *store-and-forward-mail-hosts*) 

(defparameter *debug-mailer* nil
   "Debugging switch to trace the activities of the Mailer.")

(defun debug-mailer (&optional on-p)
   (setq *debug-mailer* (not (null on-p))))

(defun standard-smtp-port () :smtp)

(defparameter *standard-smtp-port* (standard-smtp-port))

(defparameter *local-smtp-port* (standard-smtp-port))

(defmacro with-network-mail-host ((host &key port) &body body)
  "Binds the standard host for store and forward mail to HOST."
  `(let ((*network-mail-host* ,host)
	 ,.(when port `((*standard-smtp-port* , port))))
     ,@body)) 

; in a revision of this authentication support, there should be
; user/password combinations for each different mail host.

(defun get-smtp-authentication-user (host)
  (declare (ignore host))
  *smtp-authentication-user*)

(defun get-smtp-authentication-password (host)
  (declare (ignore host))
  *smtp-authentication-password*)

;;;------------------------------------------------------------------- 
;;;
;;; CONDITION HANDLING
;;;

(defgeneric report-mailer-error (mailer-error stream))

;; general protocol independent error classes first
(define-condition mailer-error (network-error) ())

(define-condition mailer-temporary-error (mailer-error) ())

(define-condition mailer-permanent-error (mailer-error) ())

(define-condition mailer-protocol-error (mailer-permanent-error) ())

(define-condition mailer-timeout (mailer-temporary-error #-(or LispWorks MCL CMU) no-action-mixin)
  ((stream :initarg :stream :reader mailer-error-stream)
   (direction :initarg :direction :reader mailer-error-direction)
   (timeout :initarg :timeout :reader mailer-error-timeout)))

(define-condition mailer-connection-timeout (mailer-timeout)
  ((host :initarg :host :reader mailer-error-host))
  (:report report-mailer-error)) 

(defmethod report-mailer-error ((mailer-connection-timeout mailer-connection-timeout) report-stream)
  (let ((host (mailer-error-host mailer-connection-timeout))
	(timeout (mailer-error-timeout mailer-connection-timeout)))
    (format report-stream "Timed out~@[ after ~A~] while trying to connect to ~A."
	    (and timeout (floor timeout 60)) host)))

(define-condition mailer-unknown-recipient
		  (mailer-permanent-error)
  ((recipient :initarg :recipient :reader mailer-error-unknown-recipient))
  (:report report-mailer-error))

(defmethod report-mailer-error ((mailer-unknown-recipient mailer-unknown-recipient) stream)
  (let ((recipient (mailer-error-unknown-recipient mailer-unknown-recipient)))
    (format stream "Recipient ~A is not defined on this host."
	    recipient)))

(define-condition mailer-incomplete-delivery-error
		  (mailer-error)
  ((recipient-and-status-list :initarg :recipient-and-status-list
			      :reader mailer-error-recipient-and-status-list)))

(defmethod report-mailer-error ((mailer-incomplete-delivery-error mailer-incomplete-delivery-error) stream)
  (let ((recipient-and-status-list (mailer-error-recipient-and-status-list mailer-incomplete-delivery-error)))
    (loop for (recipient . status) in recipient-and-status-list
	  unless (eq status :completed-OK)
	    do (format stream "~&Error delivering message to: ~30T~A ~40T~A"
		       recipient status))))

;; SMTP specific error classes second.
(define-condition smtp-error
		  (mailer-error)
  ((response-reply-code :initarg :response-reply-code :reader mailer-error-response-reply-code
			#-Genera :allocation #-Genera :class)
   (host :initarg :host :reader mailer-error-host)
   (command :initarg :command :reader mailer-error-command)
   (expected-reply-code :initarg :expected-reply-code :reader mailer--error-expected-reply-code)
   (response-reply-text :initarg :response-reply-text :reader mailer-error-response-reply-text))
  (:report report-mailer-error))

(define-condition unknown-smtp-error
		  (smtp-error)
  ((response-reply-code :initarg :response-reply-code :reader mailer-error-response-reply-code 
			#-Genera :allocation #-Genera :instance)))

(defmethod report-mailer-error ((smtp-error smtp-error) stream)
  (let ((host (mailer-error-host smtp-error))
	(command (mailer-error-command smtp-error))
	(expected-reply-code (mailer--error-expected-reply-code smtp-error))
	(response-reply-code (mailer-error-response-reply-code smtp-error))
	(response-reply-text (mailer-error-response-reply-text smtp-error)))
    (format stream "SMTP error from host ~A:~@[~@
                  ~4@TCommand issued: ~A~]~@
                  ~4@TExpected repl~:[y~;ies~]: ~{~D~@{, ~D~}~}~@
                  ~:[~4@TNo reply received~;~
                                 ~4@TReceived reply: ~:*~A~]"
	    (www-utils:host-mail-name host)
	    command
	    (> (length expected-reply-code) 1) expected-reply-code
	    (or response-reply-text response-reply-code))))

(define-condition smtp-protocol-violation
		  (smtp-error mailer-protocol-error)
  ())

(defmacro define-smtp-error-codes (&body errors)
  `(progn 'compile
	  (defconstant *smtp-error-alist* ',errors)
	  . ,(loop for (code smtp-err mailer-err) in errors
		   collect `(define-condition ,smtp-err 
					      (smtp-error ,mailer-err)
			      ((response-reply-code :initform ,code
						    #-Genera :allocation #-Genera :class))))))

(define-smtp-error-codes
  (421 smtp-host-not-available mailer-temporary-error)
  (450 smtp-mailbox-unavailable mailer-temporary-error)
  (451 smtp-local-error mailer-temporary-error)
  (452 smtp-insufficient-system-storage mailer-temporary-error)
  (500 smtp-unrecognized-command mailer-protocol-error)
  (501 smtp-syntax-error mailer-protocol-error)
  (502 smtp-unimplemented-command mailer-protocol-error)
  (503 smtp-bad-command-sequence mailer-protocol-error)
  (504 smtp-unimplemented-parameter mailer-protocol-error)
  (535 smtp-incorrect-authentication-data mailer-permanent-error)
  (550 smtp-mailbox-not-found mailer-permanent-error)
  (551 smtp-mailbox-not-local mailer-permanent-error)
  (552 smtp-no-more-room mailer-permanent-error)
  (553 smtp-invalid-mailbox-name mailer-permanent-error)
  (554 smtp-transaction-failed mailer-permanent-error))

(defun get-smtp-error-class (code &optional no-error-p)
  (check-type code integer)
  (cond ((second (assoc code *smtp-error-alist* :test #'eql)))
	(no-error-p nil)
	(t (error "Unknown error code ~D." code))))

(defmacro signal-smtp-condition
	  (&key host command response-reply-code expected-reply-code response-reply-text)
  `(macrolet ((%ensure-list (item)
		`(typecase ,item
		   (list ,item)
		   (t (list,item)))))
     (let ((error-class (get-smtp-error-class ,response-reply-code nil)))
       (cond (error-class
	      (error error-class
		     :host ,host
		     :command ,command
		     :expected-reply-code (%ensure-list ,expected-reply-code)
		     :response-reply-text ,response-reply-text))
	     (t (error 'unknown-smtp-error
		       :host ,host
		       :command ,command
		       :expected-reply-code (%ensure-list ,expected-reply-code)
		       :response-reply-code ,response-reply-code
		       :response-reply-text ,response-reply-text))))))

;;;------------------------------------------------------------------- 
;;;
;;; MAILER STREAM OPERATIONS 
;;;


(defgeneric open-mailer-stream (host port &rest args))


(defmethod open-mailer-stream (host port &rest args)
  (declare (dynamic-extent args))
  (%open-mailer-stream host (www-utils:tcp-service-port-number port) args))


; shouldn't the next just use WITH-STREAM ? RJ

(defmacro with-mailer-stream ((stream host port &rest args) &body body)
  `(let ((,stream nil))
     (unwind-protect
	 (progn
	   (setq ,stream (open-mailer-stream ,host ,port ,@args))
	   ,@body)
       (when ,stream
	 (close ,stream))))) 

(defun telnet-read-line (stream)
  "Read a CRLF-terminated line"
    (let ((line (Make-Array 10 :Element-Type 'Character :Adjustable T :Fill-Pointer 0))
          (char nil))
      (do () ((or (null (setq char (read-char stream nil nil)))
                  (and (eq char #\CR) (eq (peek-char nil stream) #\LF)))
              (when char (read-char stream nil nil))
              (values line (null char)))
        (vector-push-extend char line))))

;(defmethod read-mailer-response (stream expected-reply-code/s)
;  (let* ((codes-p (listp expected-reply-code/s))
;	 (*read-eval* nil))			;no read time evaluation, thank you.
;    (finish-output stream)
;    (let* ((response-reply-text (read-line stream))
;	   (len (length response-reply-text))
;	   (start (position-if #'digit-char-p response-reply-text :start 0 :end len))
;	   (end (position-if-not #'digit-char-p response-reply-text :start start :end len)))
;      (flet ((match-result (value elt)
;	       (string-equal value elt :start1 0 :end1 3 :start2 start :end2 end))
;	     (parse-code (string)
;	       (parse-integer string :start 0 :end 3)))
;	(declare (dynamic-extent #'match-result #'parse-code))
;	(let ((result-index
;		(cond (codes-p
;		       (position response-reply-text expected-reply-code/s
;				 :test #'match-result))
;		      ((match-result response-reply-text expected-reply-code/s) 0)
;		      (t nil))))
;	  (cond ((null result-index)
;		 (signal-smtp-condition
;		   :host (www-utils:foreign-host stream)
;		   ;; :command command
;		   :response-reply-code (parse-integer response-reply-text
;						       :start start :end end)
;		   :expected-reply-code (if codes-p
;					    (mapcar #'parse-code expected-reply-code/s)
;					    (parse-code expected-reply-code/s))
;		   :response-reply-text response-reply-text))
;		(*debug-mailer*
;		 (format *debug-io* "~A~%" response-reply-text)))
;	  result-index)))))

;; Handle ESMTP Mailers 3/29/97 -- JCMa.
;; Handle multi-line responses 4/23/2001 -- Naha, JCMa.
;; Return the response-reply-text
(defmethod read-mailer-response (stream expected-reply-code/s)
  (let* ((codes-p (listp expected-reply-code/s))
	 (*read-eval* nil))					;no read time evaluation, thank you.
    (finish-output stream)
    (labels ((parse-response-line (stream)
	       (let* ((line (telnet-read-line stream))   ; READ-LINE is wrong!!!
		      (start (position-if #'digit-char-p line :start 0))
		      (end (position-if-not #'digit-char-p line :start start)))
		 (assert (= start 0))				; response code should be start of line
		 (values line start end (char-equal #\- (char line end)))))
	     (parse-continued-text (stream)
	       (loop with line and continued-p
		     doing (multiple-value-bind (l s e c-p)
			       (parse-response-line stream)
			     (declare (ignore s e))
			     (setq line l continued-p c-p))
		     collect line
		     while continued-p)))
      (let (response-reply-text start end continued-p continued-text)
	(multiple-value-setq (response-reply-text start end continued-p)
	  (parse-response-line stream))
	(when continued-p
	  (setq continued-text (parse-continued-text stream)))
	(flet ((match-result (value elt)
		 (string-equal value elt :start1 0 :end1 3 :start2 start :end2 end))
	       (parse-code (string &optional (start 0) (end 3))
		 (parse-integer string :start start :end end)))
	  (declare (dynamic-extent #'match-result #'parse-code))
	  (let ((result-index (cond (codes-p
				     (position response-reply-text expected-reply-code/s :test #'match-result))
				    ((match-result response-reply-text expected-reply-code/s) 0)
				    (t nil))))
	    (cond ((null result-index)
		   (signal-smtp-condition
		     :host (www-utils:foreign-host stream)
		     ;; :command command
		     :response-reply-code (parse-code response-reply-text start end)
		     :expected-reply-code (if codes-p
					      (mapcar #'parse-code expected-reply-code/s)
					      (parse-code expected-reply-code/s))
		     :response-reply-text response-reply-text))
		  (*debug-mailer*
		   (format *debug-io* "~A~%~{~A~%~}" response-reply-text continued-text)))
	    (values result-index response-reply-text)))))))

;;;------------------------------------------------------------------- 
;;;
;;; Authentication stuff, Rainer Joswig
;;;

; see *smtp-authentication-method*

; rfc2104.txt , HMAC: Keyed-Hashing for Message Authentication
; rfc2195.txt , IMAP/POP AUTHorize Extension for Simple Challenge/Response
; rfc2554.txt , http://www.ietf.org/rfc/rfc2554.txt   , SMTP AUTH


(defun hex-to-bit-string (string)
  (assert (evenp (length string)) (string))
  (let ((result (make-string (/ (length string) 2))))
    (loop for i from 0 by 2
          for k from 0
          while (< i (length string))
          do (setf (aref result k)
                   (code-char (parse-integer string :start i :end (+ i 2) :radix 16))))
    result))

(defun hmac (hash block-length hash-length key text)
  (declare (ignore hash-length))
  (when (> (length key) block-length)
    (setf key (funcall hash key)))
  (flet ((make-k-pad (x)
           (let ((result (make-sequence 'string block-length :initial-element (code-char 0))))
             (setf (subseq result 0 (length key)) key)
             (map-into result
                       (lambda (c) (code-char (logxor (char-code c) x)))
                       result))))
    (funcall hash
             (concatenate
              'string
              (make-k-pad 92)
              (hex-to-bit-string (funcall hash (concatenate 'string (make-k-pad 54) text)))))))

(defun mail-md5-string (timestamp user password)
  (base64:base64-encode-vector
   (concatenate 'string
                user
                " "
                (hmac
                 'md5:md5-digest-hexadecimal-string 64 16 password
                 (map 'string 'code-char (base64:base64-decode-vector timestamp))))))


;;;------------------------------------------------------------------- 
;;;
;;; SMTP APPLICATION
;;; 

;; replacing format with faster string writing functions will help if
;; this ever gets heavy use.  8/3/95 -- JCMa.
;(defun %send-email-message (from to subject mail-writer
;				 &optional reply-to keywords comments file-references additional-headers)
;  (macrolet ((cond-every (&rest clauses)
;	       (loop for (antecedent . consequent) in clauses
;		     collect `(when ,antecedent ,@consequent) into result
;		     finally (return `(progn . ,result)))))
;    (with-mailer-stream
;      (stream *network-mail-host* *standard-smtp-port*)
;      (flet ((write-recipient (recipient)
;	       (mailer-command stream "250" "RCPT TO:<~A>~%" recipient))
;	     (write-header (header value)
;	       (etypecase value
;		 (cons (format stream "~A: ~{~A~^,~}~%" header value))
;		 (string (format stream "~A: ~A~%" header value)))))
;	(declare (inline write-recipient write-header))           
;	(mailer-command stream "220" "")
;	(mailer-command stream "250" "HELO ~A~%" (www-utils:local-host-domain-name))
;	(mailer-command stream "250" "MAIL FROM:<~A>~%" from)
;	(etypecase to
;	  (cons (mapc #'write-recipient to))
;	  (string (write-recipient to)))
;	(mailer-command stream "354" "DATA~%")
;	(write-header "From" from)
;	(write-header "To" to)
;	(cond-every
;	  (subject (write-header "Subject" subject))
;	  (reply-to (write-header "Reply-To" reply-to))
;	  (keywords (write-header "Keywords" keywords))
;	  (comments (write-header "Comments" comments))
;	  (file-references (write-header "File-References" file-references)))
;	(loop for (header value) in additional-headers
;	      do (write-header header value))
;	(terpri stream)
;	(etypecase mail-writer
;	  (string (write-string mail-writer stream))
;	  (function (funcall mail-writer stream)))
;	(mailer-command stream "250" "~%.~%")
;	(mailer-command stream "221" "QUIT~%")))))

; Patch: check HELO result for esmtp-p   3/29/97 -- JCMa.
(defun %send-email-message (from to subject mail-writer
				 &optional reply-to keywords comments file-references additional-headers user password)
  (macrolet ((cond-every (&rest clauses)
               (loop for (antecedent . consequent) in clauses
                     collect `(when ,antecedent ,@consequent) into result
                     finally (return `(progn . ,result)))))
    (unless (or to 
                (getf additional-headers :cc)
                (getf additional-headers :bcc))
      (error "No destination was supplied for the outgoing SMTP message."))
    (let* ((*print-pretty* nil)			;basic printing
	   (*print-circle* nil)
	   (from-length (length from))
	   (from-start  (1+ (or (position #\< from :end from-length) -1)))
	   (from-end    (or (position #\> from :end from-length
				      :start from-start :from-end t)
			    from-length))
	   (local-stream  nil)
	   (local-esmtp-p nil)
	   (prime-stream  nil)
	   (prime-esmtp-p nil))
      (labels ((write-line-1 (string stream)
                 (write-line string stream)
                 #+mcl(write-char #\linefeed stream))
               (terpri-1 (stream)
                 (terpri stream)
                 #+mcl(write-char #\linefeed stream))
               (write-recipient-1 (recipient stream)
		 (write-string "RCPT TO:<" stream)
                 (write-recipient-email recipient stream) 
		 (write-line-1 ">" stream)
		 (read-mailer-response stream "250"))
	       (local-recipient-p (recipient)
		 (or *send-mail-locally* 
		     (loop for substr in *local-mailer-strings*
			   thereis (search substr recipient)) ))
               (write-recipient-email (string stream &optional (start 0) (end (length string))) ;added to use only the email address for the recipient -- JCMa 10/7/2010
                 (let ((s (1+ (or (position #\< string :start start :end end) -1)))
                       (e (or (position #\> string  :start start :end end :from-end t) end)))
                   (write-string string stream :start s :end e)))
	       (write-recipient (recipient)
		 (cond ((local-recipient-p recipient)
			(ensure-local-stream)
			(write-recipient-1 recipient local-stream))
		       (t (ensure-network-stream)
			  (write-recipient-1 recipient prime-stream))))
               (write-recipients (recipients)
                 (etypecase recipients
                   (cons (mapc #'write-recipient recipients))
                   (string (write-recipient recipients))))
	       (write-header (header value stream)
                 (write-string (typecase header
                                 (string header)
                                 (keyword (string-capitalize header)))        ; lame, should use header tokenization
                               stream)
                 (write-string ": "   stream)
                 (etypecase value
                   (cons (loop for (val . more-p) on value
                               do (write-string val stream)
                               when more-p
                               do (write-string "," stream)))
                   (string (write-string value stream))
                   (function (funcall value stream))) ;add function JCMa 10/11/2007
                 (terpri-1 stream))
               (cram-md5-authenticate-user (stream)
                 (when *debug-mailer*
                   (write-line-1 "Trying CRAM-MD5 Authentication." *debug-io*))
                 (write-string "AUTH CRAM-MD5" stream)
                 (terpri-1 stream)
                 (let ((response (multiple-value-bind (index text)
                                     (read-mailer-response stream '("334"))
                                   (declare (ignore index))
                                   (mail-md5-string (subseq text 4)
                                                    user
                                                    password))))
                   (write-string response stream)
                   (terpri-1 stream)
                   (read-mailer-response stream '("235"))
                   (when *debug-mailer*
                     (write-line-1 "CRAM-MD5 Authentication succeeded." *debug-io*))))
	       (open-mail-stream (host port)
		 (declare (values stream esmtp-p))
		 (let ((stream (open-mailer-stream host port))
		       (res nil))
		   (read-mailer-response stream '("220" "250"))	;250 added by SLH 7/17/98
		   (write-string "HELO " stream)
		   (write-string (www-utils:local-host-domain-name) stream)
		   (terpri-1 stream)
		   (setq res (read-mailer-response stream '("220" "250")))
                   (when (eq *smtp-authentication-method* :cram-md5)
                     (cram-md5-authenticate-user stream))
		   (write-string "MAIL FROM:<" stream)
		   (write-string from stream :start from-start :end from-end)
		   (write-line-1 ">" stream)
		   (read-mailer-response stream "250")
		   (values stream (eql res 0))))
	       (ensure-local-stream ()
		 (unless local-stream
		   (when *debug-mailer* (write-line-1 "Opening local mailer" *debug-io*))
		   (multiple-value-setq (local-stream local-esmtp-p)
                       (open-mail-stream *local-mail-host* *local-smtp-port*))))
	       (ensure-network-stream ()
                 (assert *network-mail-host* (*network-mail-host*))
		 (unless prime-stream
		   (when *debug-mailer* (write-line-1 "Opening network mailer" *debug-io*))
		   (multiple-value-setq (prime-stream prime-esmtp-p)
                       (open-mail-stream *network-mail-host* *standard-smtp-port*))))
	       (write-message-body (stream esmtp-p)
		 (when stream
		   (write-line-1 "DATA" stream)
		   (when esmtp-p
		     (read-mailer-response stream "250") )
		   (read-mailer-response stream "354")
		   (write-header "From" (or from (getf additional-headers :from)) stream)
		   ;; To allow mailers to mask their recipient lists.
		   (write-header "To" (getf additional-headers :to to) stream)
		   (let ((subject
			  (or subject (getf additional-headers :subject)))
			 (reply-to
			  (or reply-to (getf additional-headers :reply-to)))
			 (keywords
			  (or keywords (getf additional-headers :keywords)))
			 (comments
			  (or comments (getf additional-headers :comments))))
		     (cond-every
                      (subject  (write-header "Subject" subject stream))
                      (reply-to (write-header "Reply-To" reply-to stream))
                      (keywords (write-header "Keywords" keywords stream))
                      (comments (write-header "Comments" comments stream))
                      (file-references
                       (write-header "File-References"
                                     file-references stream))))
		   (loop for (header value) on additional-headers by #'cddr
			 unless (member header '(:from :to :bcc :subject :reply-to
                                                 :keywords :comments))
                         do (write-header header value stream))
		   (terpri-1 stream)
		   (with-message-body-encoding (stream stream)
		     (etypecase mail-writer
		       (string (write-string mail-writer stream))
		       (function (funcall mail-writer stream))))
		   (terpri-1 stream)))
	       (finalize-message (stream)
		 (when stream
		   (when *debug-mailer* (write-line-1 "Finalizing Mail stream" *debug-io*))
		   (write-line-1 "." stream)
		   (read-mailer-response stream "250")
		   (write-line-1 "QUIT" stream)
		   (read-mailer-response stream "221")
		   (close stream))))
	(unwind-protect
	    (progn
              (destructuring-bind (&key cc bcc &allow-other-keys) additional-headers
                (cond-every
                 (to (write-recipients to))
                 (cc (write-recipients cc))
                 (bcc (write-recipients bcc))))
	      (write-message-body prime-stream prime-esmtp-p)
	      (write-message-body local-stream local-esmtp-p)
	      (finalize-message prime-stream)
	      (setq prime-stream nil)
	      (finalize-message local-stream)
	      (setq local-stream nil)
	      t)
	  (when prime-stream
	    (close prime-stream :abort t))
	  (when local-stream
	    (close local-stream :abort t)))))))

(declaim (inline send-mail))

(defun send-mail (from to subject mail-writer &key keywords comments file-references reply-to additional-headers
                       (user (get-smtp-authentication-user *network-mail-host*))
                       (password (get-smtp-authentication-password *network-mail-host*)))
  "Sends mail from FROM to TO with subject SUBJECT.
MAIL-WRITER is either a string or a function of one argument that writes the message body to a stream."
  (%send-email-message from to subject mail-writer reply-to keywords comments file-references additional-headers
                       user password))

;;;------------------------------------------------------------------- 
;;;
;;; EXAMPLES
;;;

#|

(send-mail "rusty@pub.pub.whitehouse.gov"
	   '("rusty@pub.pub.whitehouse.gov" "johnson_dg@a1.eop.gov")
	   "Testing the Split brain bulk mailer."
	   "just a test")

(smtp:send-mail "JCMA@ai.mit.edu (John C. Mallery)"
                "joswig@lisp.de"
                "Sending mail with LispWorks 4.3.6."
                (lambda (stream)
                  (princ "This is a hack to send mail. It is code form G. Cartier, changed a little by me.
What do you think? It is a first shot." stream)
                  (terpri stream) (terpri stream)))


|#



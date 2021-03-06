;;; -*- Mode: LISP; Syntax: ANSI-COMMON-LISP; Package: HTML-PARSER -*-
;;
;; This file contains class and variable definitions for the html parser.
;;
;; Copyright (c) 1996-98 Sunil Mishra <smishra@cc.gatech.edu>,
;; portions copyright (c) 1999 Kaelin Colclasure <kaelin@acm.org>,
;; all rights reserved.
;;
;; $Id: //depot/rev/lisp/html-parser-10.0-alpha/defs.lisp#1 $

(in-package :html-parser)

;;; Constants & Variables

(defconstant *html-dtd-list*
    '(("-//KLC//DTD LSP 1.0//EN" "lsp-1-0")
      ("-//KLC//DTD LSP//EN" "lsp-1-0")
      ("-//W3C//DTD HTML 4.0 Transitional//EN" "html-4-0-transitional")
      ("-//W3C//DTD HTML 4.0 Frameset//EN" "html-4-0-frameset")
      ("-//W3C//DTD HTML 4.0//EN" "html-4-0-strict")
      ("-//W3C//DTD HTML 3.2 Draft//EN" "html-3-2")
      ("-//IETF//DTD HTML 2.0//EN" "html-2-0")
      ("-//IETF//DTD HTML//EN" "html-2-0")))

(defvar *default-dtd* "-//W3C//DTD HTML 4.0 Transitional//EN")
(defvar *current-dtd* nil)

#-MCL
(defconstant *eof* '(()))

#+MCL
(defvar *eof* '(()))

(defconstant *string-char-type*
    #+cl-http http::*standard-character-type*
    #+(and (not cl-http) (or mcl lispworks)) 'base-character
    #+(and (not cl-http) (or allegro cmu scl)) 'base-char)

(defconstant *source-file-extension* "lisp")

(defconstant *compiled-file-extension*
    (or #+allegro excl:*fasl-default-type*
	#+ACLPC (first acl:*fsl-extensions*)
	#+lispworks compiler:*fasl-extension-string*
	#+(and imach (not vlm))"ibin"
	#+vlm"vbin"
	#+3600"bin"
	#+mcl (pathname-type *.fasl-pathname*)
	#+(or cmu scl) (c:backend-fasl-file-type c:*backend*)
	(error "Not ported to this platform.")))


;;; Tokenizers

(eval-when (load eval compile)
  (defclass html-parser-token (property-list-mixin)
    ((name :type string
	   :reader token-name
	   :initarg :name)))
  
  (defclass html-name-token (html-parser-token)
    ())
  
  (defclass html-entity-token (html-parser-token)
    ())
  
  (defmethod print-object ((token html-parser-token) stream)
    (print-unreadable-object (token stream :type t)
      (prin1 (token-name token))))
  
  (defmethod print-object ((token html-name-token) stream)
    (format stream "#t~S" (token-name token)))
  
  (defmethod print-object ((token html-entity-token) stream)
    (format stream "#e~S" (token-name token)))
  
  #-(or :ansi-cl :draft-ansi-cl-2)
  (defmethod make-load-form ((token html-entity-token))
    `(tokenize-entity ,(token-name token)))
  
  #-(or :ansi-cl :draft-ansi-cl-2)
  (defmethod make-load-form ((token html-name-token))
    `(tokenize-name ,(token-name token)))
  
  ;; Make-load-form needs an environment variable in ANSI-CL
  #+(or :ansi-cl :draft-ansi-cl-2)
  (defmethod make-load-form ((token html-name-token) &optional environment)
    (declare (ignore environment))
    `(tokenize-name ,(token-name token)))
  
  #+(or :ansi-cl :draft-ansi-cl-2)
  (defmethod make-load-form ((token html-entity-token) &optional environment)
    (declare (ignore environment))
    `(tokenize-entity ,(token-name token)))
  
  (defun make-html-name-token (string start end)
    (make-instance 'html-name-token
      :name (string-upcase (subseq string start end))))
  
  (defun make-html-entity-token (string start end)
    (make-instance 'html-entity-token
      :name (subseq string start end)))
  
  ;; Tokenizer function: tokenize-name
  (define-tokenizer name
      :test 'char-equal
      :tokenizer 'make-html-name-token
      :documentation 
      "Tokenizer for storing case insensitive HTML name strings")
  
  ;; Tokenizer function: tokenize-entity
  (define-tokenizer entity
      :test 'char=
      :tokenizer 'make-html-entity-token
      :documentation
      "Tokenizer for storing case sensitive HTML entity strings"))

#-Genera
(defun parser-sharp-sign-reader-helper (stream sub-char arg)
  (declare (ignore arg))
  (let ((name (read stream t nil t)))
    (funcall (ecase sub-char
               ((#\T #\t) #'tokenize-name)
               ((#\E #\e) #'tokenize-entity))
             (string name))))

#+Genera
(defun parser-sharp-sign-reader-helper (stream sub-char arg)
  (declare (ignore arg))
  (let* ((name (read stream t nil t))
	 (token (funcall (ecase sub-char
			   ((#\T #\t) #'tokenize-name)
			   ((#\E #\e) #'tokenize-entity))
			 (string name))))
    token))

;; Handy dandy macro character #T"BR", #E"uuml"
;; The former creates a name (case insensitive) token, while the latter
;; constructs an entity (case sensitive) token.
;; We should probably have our own read table for modularity reasons.
(set-dispatch-macro-character #\# #\t  'parser-sharp-sign-reader-helper)
(set-dispatch-macro-character #\# #\e 'parser-sharp-sign-reader-helper)


;;; Class definitions

;; The parser is a structure because I doubt I will be doing any
;; dispatching on it.
 
(defstruct (parser (:print-function print-parser))
  (cdata-element nil)
  (toplevel-tag nil)
  (stack nil)
  (input "")
  (read-position 0)
  (save-fragments nil)
  (tag-instance-class 'html-tag-instance)
  (unknown-instance-class 'unknown-tag-instance)
  (open-tag-fn nil)
  (close-tag-fn nil)
  (cdata-fn nil)
  (pcdata-fn nil))

(defun print-parser (parser stream ignore)
  (declare (ignore ignore))
  (print-unreadable-object
      (parser stream :type t)
    (let ((print-string (if (> (length (parser-input parser)) 10)
			    (concatenate 'string (subseq (parser-input parser)
							 0 10) "...")
			  (parser-input parser))))
      (format stream "~S ~D/~D" print-string
	      (parser-read-position parser) (length (parser-input parser))))))

(defclass html-tag ()
  ((name :initarg :name
	 :type html-name-token
	 :reader name)
   (contains :initarg :contains
	     :reader contains)
   (inclusions :initarg :inclusions
	       :reader inclusions)
   (exclusions :initarg :exclusions
	       :reader exclusions)
   (containers :initform nil
	       :accessor containers)
   (default-container :initarg :default-container
		      :initform nil
		      :accessor default-container)
   #+debug
   (instances :initform nil
	      :accessor instances)
   (attributes :type list
	       :initarg :attributes
	       :reader attributes)
   (start-optional :initform nil
		   :initarg :start-optional
		   :reader start-optional-p)
   (end-optional :initform nil
		 :initarg :end-optional
		 :reader end-optional-p)))

(defclass html-attribute ()
  ((name :initarg :name
	 :type html-name-token
	 :reader name)
   (default :initarg :default-value
	    :reader default-value)
   (values :initarg :values
	   :accessor allowed-values)))

(defclass abstract-tag-instance ()
  ((instance-of :initarg :instance-of
		:type html-tag
		:reader instance-of)
   (parts :initform nil
	  :accessor parts)
   (part-of :initarg :part-of
	    :initform nil
	    :type abstract-tag-instance
	    :accessor part-of)
   (attribute-values :initform nil
		     :initarg :attr-values
		     :accessor attr-values)
   (html-fragment :initform ""
		  :accessor html-fragment
		  :type string)))

(defstruct (tag-parser-data (:conc-name "PD-"))
  (instance nil)
  (storep nil)
  (start-pos nil)
  (end-pos nil)
  (contexts nil))

(defclass html-tag-instance (abstract-tag-instance)
  ())

(defclass unknown-tag-instance (abstract-tag-instance)
  ((name :reader name
	 :type html-name-token
	 :initarg :name)))


;;; Print methods

(defmethod print-object ((attribute html-attribute) stream)
  (print-unreadable-object
   (attribute stream :type t)
   (princ (name attribute) stream)))

(defmethod print-object ((tag html-tag) stream)
  (print-unreadable-object
   (tag stream :type t)
   (princ (name tag) stream)))

(defmethod print-object ((tag-instance abstract-tag-instance) stream)
  (print-unreadable-object
   (tag-instance stream :type t)
   (format stream "~A: ~A"
	   (name tag-instance) (attr-values tag-instance))))


;;; Access methods

(defmethod name ((name string))
  (name (tokenize-name name)))

(defmethod name ((name html-name-token))
  name)

(defmethod name ((tag-instance abstract-tag-instance))
  (name (instance-of tag-instance)))

(defmethod contains ((name string))
  (contains (tokenize-name name)))

(defmethod contains ((name html-name-token))
  (let ((defn (get-value name :tag-definition)))
    (and defn (contains defn))))

(defmethod contains ((tag-instance abstract-tag-instance))
  (contains (instance-of tag-instance)))

(defmethod inclusions ((name string))
  (inclusions (tokenize-name name)))

(defmethod inclusions ((name html-name-token))
  (let ((defn (get-value name :tag-definition)))
    (and defn (inclusions defn))))

(defmethod inclusions ((tag-instance abstract-tag-instance))
  (inclusions (instance-of tag-instance)))

(defmethod exclusions ((name string))
  (exclusions (tokenize-name name)))

(defmethod exclusions ((name html-name-token))
  (let ((defn (get-value name :tag-definition)))
    (and defn (exclusions defn))))

(defmethod exclusions ((tag-instance abstract-tag-instance))
  (exclusions (instance-of tag-instance)))

(defmethod containers ((name string))
  (containers (tokenize-name name)))

(defmethod containers ((name html-name-token))
  (let ((defn (get-value name :tag-definition)))
    (and defn (containers defn))))

(defmethod containers ((tag-instance abstract-tag-instance))
  (containers (instance-of tag-instance)))

(defmethod default-container ((name string))
  (default-container (tokenize-name name)))

(defmethod default-container ((name html-name-token))
  (let ((defn (get-value name :tag-definition)))
    (and defn (default-container defn))))

(defmethod default-container ((tag-instance abstract-tag-instance))
  (default-container (instance-of tag-instance)))

#+debug
(defmethod instances ((name string))
  (instances (tokenize-name name)))

#+debug
(defmethod instances ((name html-name-token))
  (let ((defn (get-value name :tag-definition)))
    (and defn (instances defn))))

#+debug
(defmethod instances ((tag-instance abstract-tag-instance))
  (instances (instance-of tag-instance)))

(defmethod attributes ((name string))
  (attributes (tokenize-name name)))

(defmethod attributes ((name html-name-token))
  (let ((defn (get-value name :tag-definition)))
    (and defn (attributes defn))))

(defmethod attributes ((tag-instance abstract-tag-instance))
  (attributes (instance-of tag-instance)))

(defmethod start-optional ((name string))
  (start-optional (tokenize-name name)))

(defmethod start-optional ((name html-name-token))
  (let ((defn (get-value name :tag-definition)))
    (and defn (start-optional defn))))

(defmethod start-optional ((tag-instance abstract-tag-instance))
  (start-optional (instance-of tag-instance)))

(defmethod end-optional ((name string))
  (end-optional (tokenize-name name)))

(defmethod end-optional ((name html-name-token))
  (let ((defn (get-value name :tag-definition)))
    (and defn (end-optional defn))))

(defmethod end-optional ((tag-instance abstract-tag-instance))
  (end-optional (instance-of tag-instance)))


;;; Utilities

;;; Miscellaneous list operations

(defun flatten (tree &key (test #'listp) (key #'identity)
		     &aux result result-end)
  (labels ((collect-result (list)
	     (cond (result-end
		    (setf (cdr result-end) list)
		    (setq result-end (last result-end)))
		   (t (setq result list)
		      (setq result-end (last list)))))
	   (%flatten (tree)
	     (if (funcall test tree)
		 (dolist (el (funcall key tree))
		   (etypecase el
		     (atom (collect-result (list el)))
		     (cons (%flatten el))))
		 (collect-result (list tree)))))
    (declare (inline collect-result)
	     (dynamic-extent #'%flatten))
    (cond ((and (consp tree) (funcall test tree))
	   (%flatten tree)
	   result)
	  ((null tree) nil)
	  (t (list tree)))))
  
(defun delete-from-tree (item tree)
  (delete-from-children item (delete item tree)))

(defun delete-from-children (item tree)
  (etypecase tree
     (atom tree)
     (cons
      (when (consp (car tree))
        (setf (car tree) (delete-from-tree item (car tree))))
      (delete-from-children item (cdr tree))
      tree)))

;;; Tokenizing

(defun tokenize-list (l tokenize-fn)
  (loop for item in l
	collect (etypecase item
		  (html-parser-token item)
		  (symbol (funcall tokenize-fn (symbol-name item)))
		  (string (funcall tokenize-fn item)))))

;;; Tag and entity predicates

(defmethod tag-definition ((tag-instance abstract-tag-instance))
  (instance-of tag-instance))

(defmethod tag-definition ((name string))
  (get-value (tokenize-name name) :tag-definition))

(defmethod tag-definition ((name html-name-token))
  (get-value name :tag-definition))

(defmethod tag-definition ((name symbol))
  (get-value (tokenize-name (symbol-name name)) :tag-definition))

(defun parameter-entity-name-p (symbol)
  (and (symbolp symbol)
       (char= (char (symbol-name symbol) 0) #\%)))

;;; EOF

;;; -*- Mode: lisp; Syntax: ansi-common-lisp; Base: 10; Package: xml-query; -*-

#|
<DOCUMENTATION>
 <DESCRIPTION>
the static and dynamic semantics specify three environments:
 static types
 dynamic variable and function values

the dynamic environments are handled by translated code through appropriate
let/flet/lambda construction.
in addition, there is a static value environment, which is used to discover
constants.
the static type environment is managed within the code-generator through a
three-part type enviroment.
there is one dynamic binding each for the function, value, and type binding
for a given variable.
they are generated by function, variable, and type declarations, respectively.

the implementation comprises three layers.
 primitives: these are either imported from xpath (see "XPath:operators.lisp")
 algebra: macros and functions which implement the quary algebra's operational
  semantic
 constructors: parser reduction methods which rewrite XQuery expressions
  into statements in the algebra. (see "constructors.lisp")

 this file comprises the algebra macros and functions
 </DESCRIPTION>
  <COPYRIGHT YEAR='2001' AUTHOR='james adam anderson' MARK='(C)'
            href='file://xml/sysdcl.lisp' />
 </DOCUMENTATION>
|#

(in-package "XML-QUERY") 

;;
;;
;; query algebra operations / names

(defun xqa:make-tname (literal)
  (intern-type literal *xqa-package*))

(defun is-tname (datum)
  (and (symbolp datum) (eq (symbol-package datum) *xqa-package*)))

(defun xqa:make-ncname (namestring &optional (namespace *null-namespace*))
  (etypecase namestring
    ((and symbol (not null))
     (intern-name (string namestring) namespace))
    (string
     (intern-name namestring namespace))))

(defun xqa:make-uname (namespace local-part)
  (setf namespace (find-namespace namespace :if-does-not-exist :create))
  (etypecase local-part
      ((and symbol (not null))
       (intern-name (string local-part) namespace))
      (string
       (intern-name local-part namespace))))

(defun xqa::IS-UNAME (x)
  (and (symbolp x)
       (not (eq (symbol-package x) *xqa-package*))
       (not (eq (symbol-package x) *null-namespace*))))

(defun compile-time-name (name-expr)
  ;; try to resolve a name at compile-time. if that succeeds, the value
  ;; can be treated as a constant.
  (typecase name-expr
    (symbol name-expr)
    (cons (case (first name-expr)
            (xql:qname (destructuring-bind (prefix local-part
                                                   &aux namespace)
                                           (rest name-expr)
                         (when (setf namespace (ignore-errors
                                                (prefix-value prefix)))
                           (xqa::make-uname namespace local-part))))))))


;;
;;
;; query algebra operations / ...
;;
;; function application is simply a list, 
;; binary op is expressed as function application
;; unary op is expressed as function application


(defun xqa:attribute (name value &aux node)
  (cond ((eq (symbol-package name) *xmlns-namespace*)
         (setf node (make-ns-node :name name
                                  :children (if (listp value)
                                              value (list value))))
         (push node *namespace-bindings*)
         node)
        (t
         (make-string-attr-node :name name :children (if (listp value)
                                                       value (list value))))))

(defun xqa::difference (&rest args)
  (declare (dynamic-extent args))
  (if args
    (if (rest args)
      (reduce #'(lambda (set1 set2)
                  (set-difference (if (listp set1) set1 (list set1))
                                  (if (listp set2) set1 (list set2))))
              args :initial-value nil)
      (if (listp (first args))
        (first args)
        (list (first args))))))

(defun xqa:element (name children)
  (make-elem-node :name name
                  :attributes (collect-attributes children)
                  :namespaces (collect-namespaces children)
                  :children (collect-node-by-type
                             #'(lambda (n) (and (not (is-attr-node n))
                                                (not (is-ns-node n))))
                             children)))

(defMacro xqa::error (&optional (message-or-condition "unspecified."))
  `(error ,message-or-condition))

(defMacro xqa::for ((variable value-exp) body-exp)
  (let ((head (xqa::gensym)) (tail (xqa::gensym)) (body-result (xqa::gensym "V-")))
    `(let* ((,head (list nil)) (,tail ,head))
       (xp:map-nodes (function (lambda (,variable &aux ,body-result)
                              (when (setf ,body-result ,body-exp)
                                (setf (rest ,tail) (list ,body-result)
                                      ,tail (rest ,tail)))))
                  ,value-exp)
       (rest ,head))))

(defMacro xqa::fun (name parameters type body-exp)
  ;; where this appears as part of a query unit, it is rewritten as part
  ;; of reduction
  ;; when it appears elsewhere, it is expanded here and evaluated.
  `(progn
     (declaim (ftype (function ,(mapcar #'(lambda (typed-parameter)
                                            (compute-type-value
                                             (second typed-parameter)))
                                        parameters)
                               ,(compute-type-value type))
                     ,name))
     (defun ,name ,(mapcar #'first parameters)
       ,@(mapcar #'(lambda (typed-parameter)
                     `(declare (type ,(compute-type-value 
                                       (second typed-parameter))
                                     ,(first typed-parameter))))
                 parameters)
       ,body-exp)))

(defMacro xqa::if (predicate-exp then-exp &optional else-exp)
  `(if ,predicate-exp ,then-exp ,@(when else-exp (list else-exp))))

(defun xqa::intersection (&rest args)
  (declare (dynamic-extent args))
  (if args
    (if (rest args)
      (reduce #'(lambda (set1 set2)
                  (intersection (if (listp set1) set1 (list set1))
                                (if (listp set2) set1 (list set2))))
              args :initial-value nil)
      (if (listp (first args))
        (first args)
        (list (first args))))))

(defMacro xqa::let ((variable value-exp) &optional body-exp)
  ;; when this appears at the top-level of a query unit, it is rewritten as part
  ;; of reduction,
  ;; when it appears elsewhere, it is expanded her and evaluated. in that case,
  ;; it can appear in four forms: with/without type, with/without body.
  ;; with a body entails an environment for the value and optionally the type
  ;; the query algebra let form comprises strictly one binding and a body.
  ;; multiple bindings, which the query language supports, must be expanded.
  ;; (as per WD-xml-query-20010215/E.2.3)
  (if body-exp
    (if (consp variable)
      (destructuring-bind (variable type &aux (c-type (compute-type-value type)))
                          variable
        (setf (variable-type variable) c-type)
        `(let ((,variable ,value-exp))
           (declare (type ,c-type ,variable))
           ,body-exp))
      `(let ((,variable ,value-exp))
         ,body-exp))
    (if (consp variable)
      (destructuring-bind (variable type &aux (c-type (compute-type-value type)))
                          variable
        (setf (variable-type variable) c-type)
        `(progn (declaim (type ,c-type ,variable))
                (defParameter ,variable ,value-exp)))
      `(defParameter ,variable ,value-exp))))

#|
(defMacro xqa::match (exp &rest body
                          &aux (var (if (symbolp exp) exp (xqa::gensym "V-"))))
  (unless (and (not (find-if (complement #'(lambda (clause)
                                             (and (consp clause)
                                                  (member (first clause)
                                                          '(xqa::case
                                                            xqa::else)))))
                             body))
               (case (count 'xqa::else body :key #'first)
                 (0 t)
                 (1 (eq (first (last body)) 'xqa::else))))
    (error "syntax error in: ~s." (list* 'xqa::match exp body)))
  (setf body (mapcar #'(lambda (clause)
                         (case (first clause)
                           (xqa::case
                            (destructuring-bind ((name type) &rest body)
                                                (rest clause)
                              `(when (xsd:typep ,var ,type)
                                 (let ((,name ,var))
                                   (declare (type ,type ,var))
                                   ,@body))))
                           (xqa::else
                            `(progn ,@(rest clause)))))
                     body))
  (if (symbolp exp)
    `(progn ,@body)
    `(let ((,var ,exp)) ,@body)))|#

(defMacro xqa::match ((var expr) &rest body)
  (unless (and (not (find-if (complement #'(lambda (clause)
                                             (and (consp clause)
                                                  (member (first clause)
                                                          '(xqa:case
                                                            xqa:else)))))
                             body))
               (case (count 'xqa:else body :key #'first)
                 (0 t)
                 (1 (eq (first (last body)) 'xqa:else))))
    (error "syntax error in: ~s." (list* 'xqa::match expr body)))
  (setf body (mapcar #'(lambda (clause)
                         (case (first clause)
                           (xqa::case
                            (destructuring-bind (type &rest body)
                                                (rest clause)
                              `(when (xsd:typep ,var ,type)
                                 (locally
                                   (declare (type ,type ,var))
                                   ,@body))))
                           (xqa::else
                            `(progn ,@(rest clause)))))
                     body))
  (if (eq var expr)
    `(progn ,@body)
    `(let ((,var ,expr)) ,@body)))

(defun xqa::sequence (&rest args &aux (head (list nil)) (tail head))
  (declare (dynamic-extent args))
  (xp:map-nodes #'(lambda (node) (setf (rest tail) (list node)
                                    tail (rest tail)))
             args)
  (rest head))

(defMacro xqa::sort (value-expr spec-list)
  (dolist (spec spec-list)
    (destructuring-bind (key test) spec
      (setf value-expr
            `(sort ,value-expr ,test
                   :key (function (lambda (*context-node*) ,key)))))
    value-expr))

(defMacro xqa::type (variable type)
  ;; the form (xqa::type <type>) appears as the result of type attributes
  ;; and explicit typing tests. in the former case, it is rewritten to a
  ;; declaration. in the second case it should be evaluated and will be
  ;; macro-expanded here. there are two options:
  ;; a. a type varaible was specified, in which case the compile-time
  ;;    declaration is extracted and used.
  ;; b. a type constant was supplied, in which case its specified value is used.
  (setf (type-variable-value variable) (compute-type-value type))
  (values))

(defun xqa::union (&rest args)
  (declare (dynamic-extent args))
  (if args
    (if (rest args)
      (reduce #'(lambda (set1 set2)
                  (union (if (listp set1) set1 (list set1))
                         (if (listp set2) set1 (list set2))))
              args :initial-value nil)
      (if (listp (first args))
        (first args)
        (list (first args))))))

(defMacro xqa::where (predicate-expr body)
  `(if ,predicate-expr ,body nil))

(defMacro xqa::query (expression)
  expression)


;;
;;
;; compile-time operations

(defun type-variable-value (name &aux binding)
  (if (setf binding (rest (assoc name *type-variables*)))
    binding
    (error 'unbound-variable :name name)))

(defun (setf type-variable-value) (type name)
  (setf *type-variables* (acons name type *type-variables*))
  type)

(defun compute-type-value (variable-or-type)
  (if (is-tname variable-or-type)
    (type-variable-value variable-or-type)
    variable-or-type))



(defun variable-type (name &aux binding)
  (if (setf binding (rest (assoc name *variable-types*)))
    binding
    (error 'unbound-variable :name name)))

(defun (setf variable-type) (type name)
  (let ((binding (assoc name *variable-types*)))
    (if binding
      (setf (rest binding) type)
      (setf *variable-types* (acons name type *variable-types*))))
  type)

(defun variable-value (name &aux binding)
  "used to maintain global type bindings"
  (if (setf binding (rest (assoc name *variables*)))
    binding
    (error 'unbound-variable :name name)))

(defun (setf variable-value) (value name)
  (setf *variables* (acons name value *variables*))
  value)


(defun function-type (name &aux binding)
  (if (setf binding (rest (assoc name *function-types*)))
    binding
    (error 'undefined-function :name name)))

(defun (setf function-type) (type name)
  (setf *function-types* (acons name type *function-types*))
  type)

(defun function-value (name &aux binding)
  (if (setf binding (rest (assoc name *functions*)))
    binding
    (error 'undefined-function :name name)))

(defun (setf function-value) (type name)
  (setf *functions* (acons name type *functions*))
  type)

(defun intern-variable (prefix local-part)
  "variables are names which appear lexically as qualified names - which makes
   them look like element and attribute identifiers, but which bind values
   within a query, rather than a component in content.
   they must be amenable to appearing in the parameter list of a
   function and are therefore implemented with symbols. the symbols are
   interned in the '$' package, in order to facilitate compiling, but are
   also identified by universal name during the parse process via the type
   declarations to limit consing."
  (let* ((namespace (prefix-value prefix))
         (namespace-name (if namespace (namespace-name namespace) "")))
    (or (first (assoc-if #'(lambda (vn)
                             (and (string= namespace-name vn
                                           :start2 1
                                           :end2 (+ 1 (length namespace-name)))
                                  (string= local-part vn
                                           :start2 (+ 2 (length namespace-name)))))
                         *variables*))
        (let ((variable-name
               (intern (concatenate 'string "{"
                                    (if namespace (namespace-name namespace) "")
                                    "}"
                                    local-part)
                       "$")))
          (push (cons variable-name nil) *variables*)
          variable-name))))
;;
;;
;; primitive operations

(defMacro collect-nodes (&rest body
                               &aux (head (xqa::gensym)) (tail (xqa::gensym)))
  `(let* ((,head (list nil)) (,tail ,head))
     ,@(mapcar #'(lambda (form)
                   `(xp:map-nodes #'(lambda (node)
                                     (setf (rest ,tail) (list node)
                                           ,tail (rest ,tail)))
                                 ,form))
               body)
     (rest ,head)))

;;
;;
;; additional path code generators

(defMethod xpa::compute-predicate-combination
           ((predicate (eql 'xqa:id-test)) source &key name type target)
  (destructuring-bind (&key local-part namespace) (rest name)
    (destructuring-bind (&key t-local-part t-namespace) (rest target)
      (setf namespace 
            (or (find-package (if namespace namespace ""))
                (error "unknown namespace: ~s." namespace)))
      (setf t-namespace 
            (or (find-package (if t-namespace t-namespace ""))
                (error "unknown namespace: ~s." t-namespace)))
      (unless local-part (setf local-part "*"))
      (unless t-local-part (setf t-local-part "*"))
      (setf name (intern-name local-part namespace))
      (setf target (intern-type t-local-part t-namespace)))
    `(function (lambda (&aux node target-node)
                 (loop (unless (setf node (funcall ,source))
                         (return))
                       (when (and (xsd:typep node ,type)
                                  (eq ',name (name node))
                                  (setf target-node
                                        (find-element-by-id node
                                                            (value node)))
                                  (eq ',target (name target-node)))
                         (return target-node)))))))

(defMethod xpa::compute-predicate-combination
           ((predicate (eql 'xqa:range-test)) source &key min max)
  (unless (and min max)
    (error "min, max required."))
  `(function (lambda (&aux node)
               (loop (unless (setf node (funcall ,source))
                       (return))
                     (when (and (<= min xpa:*position*)
                                (<= xpa:*position* max))
                         (return target-node))))))



#+CCL
(progn
  (pushnew '(xqa::for . 1) *FRED-SPECIAL-INDENT-ALIST* :key #'first)
  (pushnew '(xqa::match . 1) *FRED-SPECIAL-INDENT-ALIST* :key #'first)
  nil)
     
:EOF

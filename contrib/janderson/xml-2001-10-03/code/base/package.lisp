;;; -*- Mode: lisp; Syntax: ansi-common-lisp; Base: 10; Package: cl-user; -*-

#|
<DOCUMENTATION>
 nb. see XQueryDataModel:XQDM-classes for exports for class predicate and constructors
 <COPYRIGHT YEAR='2001' AUTHOR='james adam anderson' MARK='(C)'
            href='file://xml/sysdcl.lisp' /> <CHRONOLOGY>
  <DELTA DATE='20010507'>incorporated character class exports</DELTA>
  <DELTA DATE='20010617'>moved parsetable to XML-UTILS</DELTA>
  <DELTA DATE='20010621'>exported xml serialization iterface</DELTA>
  <DELTA DATE='20010622'>parameters for reader adjustments for null symbol names</DELTA>
  <DELTA DATE='20010624'>node graph interface</DELTA>
  <DELTA DATE='20010702'><code>DATA-URL</code>; differentiated qname contexts</DELTA>
  <DELTA DATE='20010714'>factored namespaces out</DELTA>
  <DELTA DATE='20010718'>xmlparser package renamed to XMLP</DELTA>
  <DELTA DATE='20010808'>added '$' package for XQL variables</DELTA>
  <DELTA DATE='20010816'>additions for schema types</DELTA>
  <DELTA DATE='20010902'>www-utils and tk1 package for cl-http tokenizer</DELTA>
  </CHRONOLOGY>
 </DOCUMENTATION>
|#

(in-package "CL-USER")

(defPackage "XML-UTILS"
  (:nicknames "XUTILS")
  #+CCL (:import-from "CCL" "STREAM-POSITION")
  #+CL-HTTP (:import-from "URL" "URI" "URL" "PARSE-URL" "INTERN-URL"
                          "HTTP-URL" "FILE-URL" "NAME-STRING"
                          "PATH" "HOST" "HOST-STRING" "PORT" "OBJECT" "EXTENSION"
                          "TRANSLATED-PATHNAME"
                          ;; for the file-url function
                          "DIRECTORY-NAME-STRING" "WITH-VALUE-CACHED"
                          "WRITE-SCHEME-PREFIX" "WRITE-HOST-PORT-STRING" "WRITE-PATH")
  #+CL-HTTP (:import-from "HTTP" "MERGE-URL")
  #+ALLEGRO (:import-from "EXCL" "WITHOUT-INTERRUPTS")
  (:EXPORT 
   "DEFALTERNATIVECONSTRUCTOR"
   "DEFCONSTANTCONSTRUCTOR"
   "DEFCONSTRUCTOR"
   "DEFCONSTRUCTORMETHOD"
   "DEFIDENTITYCONSTRUCTOR"
   "DEFLITERALCONSTRUCTOR"
   "DEFNULLCONSTRUCTOR"
   "DEFTOKENCONSTRUCTOR"
   "DEFTOKENCONSTRUCTORS"
   "DEFTOKEN"
   "DEFTOKENS"
   "*TOKEN-PACKAGE*"
   
   "MERGE-URIS"
   "STREAM-POSITION"
   #-CCL "STREAM-READER"
   #-CCL "STREAM-WRITER"
   #-CCL "STREAM-COLUMN"
   "STREAM-STATE"
   "SPLIT-SEQ"
   "SPLIT-STRING"
   #+ALLEGRO "WITHOUT-INTERRUPTS"
   
   ;; configuration parameters
   "NOTE-newline-200101314"
   "REC-xml-names-19990114"
   "REC-xml-19980210.End-of-Line Handling"
   "REC-xml-19980210.Validate Attribute Defaults"
   "REC-xml-19980210.PEs in Internal Subset"
   "REC-xml-names-19990114.VC: Attribute Declared"
   
   "CANONICAL-ENCODING"
   "COMPUTE-PARSER-MACROS"
   "COMPUTE-TOKEN-READER"
   "CLEAR-PARSETABLE"
   "CLEAR-PARSETABLES"
   "COPY-PARSETABLE"
   "DATA-URL"
   "DEFPARSETABLE"
   "EXPORT-NAME"
   "FILE-URL"
   "FILE-URL-PATHNAME"
   "HTTP-URL"
   "MAKE-URI"
   "MAKE-DATA-URL"
   "PARSER-MACRO"
   "PARSETABLE"
   "PATHNAME-FILE-URL"
   "RESOLVE-ENTITY-IDENTIFIERS"
   "TABLE.NAME"
   "TABLE.MACROS"
   "TABLE.PROPERTIES"
   "URI"
   "URI-NAMESTRING"
   "URN"
   "URL"
   "URL-DATA"
   "WITH-FILE-STREAM"
   "WITH-HTTP-STREAM"
   "WITH-DATA-STREAM"
   "WITH-PARSETABLE"

   "VECTOR-INPUT-STREAM"

   "*ENCODING-MAP*"
   "*PARSETABLE*"
   "*XML-BASE*"
   "*XML-VERBOSE*"
   ))


(defPackage "XML-QUERY-DATA-MODEL" 
  (:nicknames "XQDM")
  (:shadowing-import-from "BNFP" "PARSE-ERROR")
  #+LISPWORKS
  (:import-from "HCL" "VALIDATE-SUPERCLASS")
  (:use "BNFP" #+CCL "CCL" "COMMON-LISP" "XUTILS")
  #+CCL (:shadow "TARGET")
  (:export
   ;; the defTypePredicate macro exports for classes and predicate names
   ;; the defException macro exports exception class names
   
   "ABSTRACT-CLASS"
   "ABSTRACT-NODE"
   "NAMED-NODE"
   "UNAMED-NODE"
   "NCNAMED-NODE"
   "TYPED-NODE"
   "DOCUMENT-SCOPED-NODE"
   "ORDINAL-NODE"
   "ENTITY-DELEGATE"
   "DOC-NODE-INTERFACE"
   "ELEM-NODE-INTERFACE"
   "ELEM-PROPERTY-NODE-INTERFACE"
   
   ;; model classes: all classes export the symbol and a predicate
   ;; concrete classes have an instantiation function and parameter
   ;; see defTypePredicate for generation
   "ABSTRACT-ATTR-NODE" "IS-ABSTRACT-ATTR-NODE"
   "ABSTRACT-DEF-NODE" "IS-ABSTRACT-DEF-NODE"
   "ABSTRACT-DEF-TYPE" "IS-ABSTRACT-DEF-TYPE"
   "ABSTRACT-ELEM-NODE" "IS-ABSTRACT-ELEM-NODE"
   "ABSTRACT-ELEM-PROPERTY-NODE" "IS-ABSTRACT-ELEM-PROPERTY-NODE"
   "ABSTRACT-NS-NODE" "IS-ABSTRACT-NS-NODE"
   "ABSTRACT-TOP-LEVEL-DEF-NODE" "IS-ABSTRACT-TOP-LEVEL-DEF-NODE"
   "ATTR-CHILD-NODE" "IS-ATTR-CHILD-NODE" "*CLASS.ATTR-CHILD-NODE*" "MAKE-ATTR-CHILD-NODE"
   "ATTR-NODE" "IS-ATTR-NODE" "*CLASS.ATTR-NODE*" "MAKE-ATTR-NODE"
   "BINARY-VALUE" "IS-BINARY-VALUE" "*CLASS.BINARY-VALUE*" "MAKE-BINARY-VALUE"
   "BOOL-VALUE" "IS-BOOL-VALUE" "*CLASS.BOOL-VALUE*" "MAKE-BOOL-VALUE"
   "CHARACTER-DATA-NODE" "IS-CHARACTER-DATA-NODE" "*CLASS.CHARACTER-DATA-NODE*" "MAKE-CHARACTER-DATA-NODE"
   "COMMENT-NODE" "IS-COMMENT-NODE" "*CLASS.COMMENT-NODE*" "MAKE-COMMENT-NODE"
   "CONDITIONAL-SECTION" "IS-CONDITIONAL-SECTION" "*CLASS.CONDITIONAL-SECTION*" "MAKE-CONDITIONAL-SECTION"
   "DECIMAL-ATTR-NODE" "IS-DECIMAL-ATTR-NODE" "*CLASS.DECIMAL-ATTR-NODE*" "MAKE-DECIMAL-ATTR-NODE"
   "DECIMAL-VALUE" "IS-DECIMAL-VALUE" "*CLASS.DECIMAL-VALUE*" "MAKE-DECIMAL-VALUE"
   "DEF-ATTR" "IS-DEF-ATTR" "*CLASS.DEF-ATTR*" "MAKE-DEF-ATTR"
   "DEF-ELEM-PROPERTY-TYPE" "IS-DEF-ELEM-PROPERTY-TYPE" "*CLASS.DEF-ELEM-PROPERTY-TYPE*" "MAKE-DEF-ELEM-PROPERTY-TYPE"
   "DEF-ELEM-TYPE" "IS-DEF-ELEM-TYPE" "*CLASS.DEF-ELEM-TYPE*" "MAKE-DEF-ELEM-TYPE"
   "DEF-ENTITY" "IS-DEF-ENTITY" "*CLASS.DEF-ENTITY*" "MAKE-DEF-ENTITY"
   "DEF-EXTERNAL-ENTITY" "IS-DEF-EXTERNAL-ENTITY" "*CLASS.DEF-EXTERNAL-ENTITY*" "MAKE-DEF-EXTERNAL-ENTITY"
   "DEF-EXTERNAL-GENERAL-ENTITY" "IS-DEF-EXTERNAL-GENERAL-ENTITY" "*CLASS.DEF-EXTERNAL-GENERAL-ENTITY*" "MAKE-DEF-EXTERNAL-GENERAL-ENTITY"
   "DEF-EXTERNAL-PARAMETER-ENTITY" "IS-DEF-EXTERNAL-PARAMETER-ENTITY" "*CLASS.DEF-EXTERNAL-PARAMETER-ENTITY*" "MAKE-DEF-EXTERNAL-PARAMETER-ENTITY"
   "DEF-GENERAL-ENTITY" "IS-DEF-GENERAL-ENTITY" "*CLASS.DEF-GENERAL-ENTITY*" "MAKE-DEF-GENERAL-ENTITY"
   "DEF-INTERNAL-ENTITY" "IS-DEF-INTERNAL-ENTITY" "*CLASS.DEF-INTERNAL-ENTITY*" "MAKE-DEF-INTERNAL-ENTITY"
   "DEF-INTERNAL-GENERAL-ENTITY" "IS-DEF-INTERNAL-GENERAL-ENTITY" "*CLASS.DEF-INTERNAL-GENERAL-ENTITY*" "MAKE-DEF-INTERNAL-GENERAL-ENTITY"
   "DEF-INTERNAL-PARAMETER-ENTITY" "IS-DEF-INTERNAL-PARAMETER-ENTITY" "*CLASS.DEF-INTERNAL-PARAMETER-ENTITY*" "MAKE-DEF-INTERNAL-PARAMETER-ENTITY"
   "DEF-NOTATION" "IS-DEF-NOTATION" "*CLASS.DEF-NOTATION*" "MAKE-DEF-NOTATION"
   "DEF-PARAMETER-ENTITY" "IS-DEF-PARAMETER-ENTITY" "*CLASS.DEF-PARAMETER-ENTITY*" "MAKE-DEF-PARAMETER-ENTITY"
   "DOC-CHILD-NODE" "IS-DOC-CHILD-NODE" "*CLASS.DOC-CHILD-NODE*" "MAKE-DOC-CHILD-NODE"
   "DOC-NODE" "IS-DOC-NODE" "*CLASS.DOC-NODE*" "MAKE-DOC-NODE"
   "DOCTYPE-CHILD-NODE" "IS-DOCTYPE-CHILD-NODE" "*CLASS.DOCTYPE-CHILD-NODE*" "MAKE-DOCTYPE-CHILD-NODE"
   "DOCUMENT-TYPE-DECLARATION-INFORMATION-NODE" "IS-DOCUMENT-TYPE-DECLARATION-INFORMATION-NODE" "*CLASS.DOCUMENT-TYPE-DECLARATION-INFORMATION-NODE*" "MAKE-DOCUMENT-TYPE-DECLARATION-INFORMATION-NODE"
   "DOUBLE-ATTR-NODE" "IS-DOUBLE-ATTR-NODE" "*CLASS.DOUBLE-ATTR-NODE*" "MAKE-DOUBLE-ATTR-NODE"
   "DOUBLE-VALUE" "IS-DOUBLE-VALUE" "*CLASS.DOUBLE-VALUE*" "MAKE-DOUBLE-VALUE"
   "ELEM-CHILD-NODE" "IS-ELEM-CHILD-NODE" "*CLASS.ELEM-CHILD-NODE*" "MAKE-ELEM-CHILD-NODE"
   "ELEM-NODE" "IS-ELEM-NODE" "*CLASS.ELEM-NODE*" "MAKE-ELEM-NODE"
   "ELEM-PROPERTY-NODE" "IS-ELEM-PROPERTY-NODE" "*CLASS.ELEM-PROPERTY-NODE*" "MAKE-ELEM-PROPERTY-NODE"
   "ENTITIES-ATTR-NODE" "IS-ENTITIES-ATTR-NODE" "*CLASS.ENTITIES-ATTR-NODE*" "MAKE-ENTITIES-ATTR-NODE"
   "ENTITY-ATTR-NODE" "IS-ENTITY-ATTR-NODE" "*CLASS.ENTITY-ATTR-NODE*" "MAKE-ENTITY-ATTR-NODE"
   "ENTITY-INFORMATION-NODE" "IS-ENTITY-INFORMATION-NODE" "*CLASS.ENTITY-INFORMATION-NODE*" "MAKE-ENTITY-INFORMATION-NODE"
   "ENTITY-VALUE" "IS-ENTITY-VALUE" "*CLASS.ENTITY-VALUE*" "MAKE-ENTITY-VALUE"
   "ENUMERATION-ATTR-NODE" "IS-ENUMERATION-ATTR-NODE" "*CLASS.ENUMERATION-ATTR-NODE*" "MAKE-ENUMERATION-ATTR-NODE"
   "EXT-SUBSET-NODE" "IS-EXT-SUBSET-NODE" "*CLASS.EXT-SUBSET-NODE*" "MAKE-EXT-SUBSET-NODE"
   "EXTERNAL-PARSED-ENTITY" "IS-EXTERNAL-PARSED-ENTITY" "*CLASS.EXTERNAL-PARSED-ENTITY*" "MAKE-EXTERNAL-PARSED-ENTITY"
   "FLOAT-VALUE" "IS-FLOAT-VALUE" "*CLASS.FLOAT-VALUE*" "MAKE-FLOAT-VALUE"
   "FUNCTION-VALUE" "IS-FUNCTION-VALUE" "*CLASS.FUNCTION-VALUE*" "MAKE-FUNCTION-VALUE"
   "ID-ATTR-NODE" "IS-ID-ATTR-NODE" "*CLASS.ID-ATTR-NODE*" "MAKE-ID-ATTR-NODE"
   "ID-REF-ATTR-NODE" "IS-ID-REF-ATTR-NODE" "*CLASS.ID-REF-ATTR-NODE*" "MAKE-ID-REF-ATTR-NODE"
   "ID-REF-VALUE" "IS-ID-REF-VALUE" "*CLASS.ID-REF-VALUE*" "MAKE-ID-REF-VALUE"
   "ID-REFS-ATTR-NODE" "IS-ID-REFS-ATTR-NODE" "*CLASS.ID-REFS-ATTR-NODE*" "MAKE-ID-REFS-ATTR-NODE"
   "ID-VALUE" "IS-ID-VALUE" "*CLASS.ID-VALUE*" "MAKE-ID-VALUE"
   "INFO-ITEM-NODE" "IS-INFO-ITEM-NODE" "*CLASS.INFO-ITEM-NODE*" "MAKE-INFO-ITEM-NODE"
   "NMTOKEN-ATTR-NODE" "IS-NMTOKEN-ATTR-NODE" "*CLASS.NMTOKEN-ATTR-NODE*" "MAKE-NMTOKEN-ATTR-NODE"
   "NMTOKENS-ATTR-NODE" "IS-NMTOKENS-ATTR-NODE" "*CLASS.NMTOKENS-ATTR-NODE*" "MAKE-NMTOKENS-ATTR-NODE"
   "NOTATION-ATTR-NODE" "IS-NOTATION-ATTR-NODE" "*CLASS.NOTATION-ATTR-NODE*" "MAKE-NOTATION-ATTR-NODE"
   "NOTATION-VALUE" "IS-NOTATION-VALUE" "*CLASS.NOTATION-VALUE*" "MAKE-NOTATION-VALUE"
   "NS-NODE" "IS-NS-NODE" "*CLASS.NS-NODE*" "MAKE-NS-NODE"
   "NUMBER-VALUE" "IS-NUMBER-VALUE" "*CLASS.NUMBER-VALUE*" "MAKE-NUMBER-VALUE"
   "ORDINAL-NODE" "IS-ORDINAL-NODE" "*CLASS.ORDINAL-NODE*" "MAKE-ORDINAL-NODE"
   "PI-NODE" "IS-PI-NODE" "*CLASS.PI-NODE*" "MAKE-PI-NODE"
   "QNAME-ATTR-NODE" "IS-QNAME-ATTR-NODE" "*CLASS.QNAME-ATTR-NODE*" "MAKE-QNAME-ATTR-NODE"
   "QNAME-CONTEXT" "IS-QNAME-CONTEXT" "*CLASS.QNAME-CONTEXT*" "MAKE-QNAME-CONTEXT"
   "QNAME-VALUE" "IS-QNAME-VALUE" "*CLASS.QNAME-VALUE*" "MAKE-QNAME-VALUE"
   "RECUR-DUR-ATTR-NODE" "IS-RECUR-DUR-ATTR-NODE" "*CLASS.RECUR-DUR-ATTR-NODE*" "MAKE-RECUR-DUR-ATTR-NODE"
   "RECUR-DUR-VALUE" "IS-RECUR-DUR-VALUE" "*CLASS.RECUR-DUR-VALUE*" "MAKE-RECUR-DUR-VALUE"
   "REF-CHARACTER-ENTITY" "IS-REF-CHARACTER-ENTITY" "*CLASS.REF-CHARACTER-ENTITY*" "MAKE-REF-CHARACTER-ENTITY"
   "REF-ENTITY" "IS-REF-ENTITY" "*CLASS.REF-ENTITY*" "MAKE-REF-ENTITY"
   "REF-GENERAL-ENTITY" "IS-REF-GENERAL-ENTITY" "*CLASS.REF-GENERAL-ENTITY*" "MAKE-REF-GENERAL-ENTITY"
   "REF-NODE" "IS-REF-NODE" "*CLASS.REF-NODE*" "MAKE-REF-NODE"
   "REF-PARAMETER-ENTITY" "IS-REF-PARAMETER-ENTITY" "*CLASS.REF-PARAMETER-ENTITY*" "MAKE-REF-PARAMETER-ENTITY"
   "STRING-ATTR-NODE" "IS-STRING-ATTR-NODE" "*CLASS.STRING-ATTR-NODE*" "MAKE-STRING-ATTR-NODE"
   "STRING-VALUE" "IS-STRING-VALUE" "*CLASS.STRING-VALUE*" "MAKE-STRING-VALUE"
   "TIME-ATTR-NODE" "IS-TIME-ATTR-NODE" "*CLASS.TIME-ATTR-NODE*" "MAKE-TIME-ATTR-NODE"
   "TIME-DUR-VALUE" "IS-TIME-DUR-VALUE" "*CLASS.TIME-DUR-VALUE*" "MAKE-TIME-DUR-VALUE"
   "URI-REF-ATTR-NODE" "IS-URI-REF-ATTR-NODE" "*CLASS.URI-REF-ATTR-NODE*" "MAKE-URI-REF-ATTR-NODE"
   "URI-REF-VALUE" "IS-URI-REF-VALUE" "*CLASS.URI-REF-VALUE*" "MAKE-URI-REF-VALUE"
   "VALUE-NODE" "IS-VALUE-NODE" "*CLASS.VALUE-NODE*" "MAKE-VALUE-NODE"   
   ;; accessors
   "URI"
   "CHILDREN"
   "ROOT"
   "VALIDATE?"
   "PARENT"
   "DEF"
   "DOCUMENT"
   "NAMESPACES"
   "ATTRIBUTES"
   "PROPERTIES"
   "NOTATION"
   "ORDINALITY"
   "MODEL"
   "NODE-CLASS"
   "NODE-VALIDATOR"
   "VALUE"
   "ENCODING"
   "NODES"
   "PREFIX"
   "TARGET"
   "DEREF"
   "IS-FIXED"
   "IS-REQUIRED"
   "IS-IMPLIED"
   "PROTOTYPE"
   "STIPULATION"
   "PROPS-DEFAULTED"
   "PROPS-REQUIRED"
   
   "VERSION"
   "STANDALONE"
   "SYSTEM-ID"
   "PUBLIC-ID"
   "NAMESPACE-NAME"
   "LOCAL-NAME"
   
   ;; additional accessors and abstract nodes which are not in the model
   "ENTITIES"
   "NOTATIONS"
   "TYPES"
   "ATTRIBUTES"
   "PRECEDING-SIBLINGS"
   "FOLLOWING-SIBLINGS"
   "GENERAL-ENTITIES"
   "PARAMETER-ENTITIES"
   "NAMED-VALUE-NODE"
   "ELEM-PROPERTY-NODE"
   "ELEM-CHILD-NODE"
   "DOC-CHILD-NODE"
   "FUNCTION-VALUE"
   "IS-FUNCTION-VALUE"
   "EXPRESSION"
   "CHARACTER-DATA-NODE"
   "PI-NODES"
   "COMMENT-NODES"
   "CONTENT"
   "ENTITY-INFO"
   "REF-ELEM-NODE"
   "REF-ELEM-PROPERTY-NODE"
   
   "CLONE-NODE"
   "LOCAL-PART"
   "CHECK-CONSTRAINT"
   "BIND-DEFINITION"
   "COLLECT-MODEL-NAMES"
   "FIRST-MODEL-NAME"
   "ASSIGN-UNIVERSAL-NAMES"
   "VALIDATE-CONTENT"
   
   ;; serialization interface
   "WRITE-NODE"
   "*NODE-LEVEL*"
   "*VERBOSE-QNAMES*"
   
   "ELEMENT-APPEND"
   "ELEMENT-GET"
   "ELEMENT-SET"
   "EXPORT-NAMES"
   "FIND-ATTRIBUTE"
   "FIND-ELEMENT"
   "FIND-ELEMENT-BY-ID"
   "FIND-NAME"
   "FIND-NAMESPACE"
   "FIND-PREFIX"
   "INTERN-NAME"
   "INTERN-PREFIX"
   "INTERN-TYPE"
   "MAKE-NAME"
   "MAKE-QNAME"
   "NAME"
   "NAMESPACE"
   "CONTENT-NAME-TYPE-NAME"

   "*DEF-NULL-NAMESPACE-NODE*"
   "*DEFAULT-NAMESPACE-ATTRIBUTE-NAME*"
   "*DEFAULT-NAMESPACES*"
   "*DOCUMENT*"
   "*ELEMENT-COUNT*"
   "*EMPTY-NAME*"
   "*INPUT-SOURCE*"
   "*MIXED-NAME*"
   "*NAMESPACE-BINDINGS*"
   "*NAMESPACE-DICTIONARY*"
   "*NAMESPACE-MODE*"
   "*NAMESPACE*"
   "*NULL-NAME*"
   "*NULL-NAMESPACE*"
   "*NULL-NAMESPACE-NODE*"
   "*OUTPUT-DESTINATION*"
   "*XHTML-NAMESPACE*"
   "*XMLNS-NAMESPACE*"
   "*XML-NAMESPACE*"
   "*XML-PREFIX-NAMESTRING*"
   "*XMLNS-PREFIX-NAMESTRING*"
   "*WILD-NAMESPACE*"
   "*WILD-NAMESTRING*"
   "*WILD-PREFIX*"
   "*XML-NAMESPACE-ATTRIBUTE-NAME*"
   "*XML-NAMESPACE-NODE*"
   "*XMLNS-NAMESPACE-ATTRIBUTE-NAME*"
   "*XMLNS-NAMESPACE-NODE*"
   "PREFIX-VALUE"
   "NAMESPACE-PREFIX"

   ;; qualified name resolution
   "*QNAME-EXTENT*"
   "*DEF-TYPE-ID-QNAME-CONTEXTS*"
   "*DEF-TYPE-MODEL-QNAME-CONTEXTS*"
   "*DEF-ATTR-QNAME-CONTEXTS*"
   "NEW-QNAME-EXTENT"
   "QNAME-EXTENT"
   "QNAME-EXTENT-EQUAL"
   "*DISTINGUISH-QNAME-HOMOGRAPHS*"
   "*CONFLATE-QNAME-SYNONYMS*"
   "ACCUMULATE-QNAMES"
   "ABSTRACT-NAME"
   "UNAME"
   "QNAME"

   "VALUE-STRING"
   "VALUE-NUMBER"
   "VALUE-BOOLEAN"
   "FIND-DEF-PARAMETER-ENTITY"
   "FIND-DEF-GENERAL-ENTITY"
   "FIND-DEF-ELEM-TYPE"
   "FIND-DEF-NOTATION"
   
   "IS-NAMECHARDATA"
   "IS-NCNAME"
   
   ;; utility functions
   *SPECIALIZE-ELEM-NODE*
   *SPECIALIZE-ATTR-NODE*
   "*TOKEN-PACKAGE*"
   "*WILD-NAME*"
   "*WILD-UNAME*"
   "*LANG-NAME*"
   "!-reader"
   "WALK-NODE"
   "XML-ERROR"
   "XML-EOF-ERROR"
   "DOCUMENT-MODEL-ERROR"
   "INTERNAL-XML-ERROR"
   "VALIDITY-ERROR"
   "NAMESPACE-ERROR"
   "WELLFORMEDNESS-ERROR"
   "WELLFORMEDNESS-CERROR"
   "SIMPLE-XML-ERROR"
   "INCOMPLETE-PARSE"
   "PRINT-QNAME"
   "PRINT-NS-NODE"
   
   "COLLECT-NODE-BY-TYPE"
   "MAP-NODE-BY-TYPE"
   
   "COLLECT-ATTRIBUTE-DECLARATIONS"
   "COLLECT-ATTRIBUTES"
   "COLLECT-COMMENTS"
   "COLLECT-COMMENTS-AND-PIS"
   "COLLECT-DECLARATIONS"
   "COLLECT-ELEMENT-DECLARATIONS"
   "COLLECT-ELEMENT-PROPERTIES"
   "COLLECT-ELEMENTS"
   "COLLECT-GENERAL-ENTITIES"
   "COLLECT-NAMESPACES"
   "COLLECT-NOTATIONS"
   "COLLECT-PARAMETER-ENTITIES"
   "COLLECT-PIS"
   
   "UNAME-EQUAL"
   "QNAME-EQUAL"
   "NODE-EQUAL"
   "MAKE-DOCUMENT-NAMESPACE-BINDINGS"
   "content-model"
   "|-content"
   "?-content"
   "*-content"
   "bounded-content"
   "MIXED-content"
   "+-content"
   "content"
   ",-content"
   "content-name"
   "type-name" 
   "mixed-atn"
   "element-atn"
   
   ;; character classes
   "XML-CHAR?"
   "XML-SPACE?"
   "XML-IDEOGRAPHIC?"
   "XML-BASECHAR?"
   "XML-LETTER?"
   "XML-DIGIT?"
   "XML-COMBININGCHAR?"
   "XML-EXTENDER?"
   "XML-NAMECHAR?"
   "XML-INITIAL-NAMECHAR?"
   "XML-PUBIDCHAR?"
   "XML-MARKUPCHAR?"
   "XML-LATINALPHACHAR?"
   "XML-LATINCHAR?"
   "XML-LANGUAGEIDCHAR?"
   "XML-VERSIONNUMCHAR?"
   "XML-MODEL-OP-CHAR?"
   "XML-SUCCESSOR-EOLCHAR?"
   "XML-INITIAL-EOLCHAR?"

   ;; graphs
   "WRITE-NODE-GRAPH"
   "ENCODE-NODE-GRAPH"
   "NODE-GRAPH-PROPERTIES"
   "NODE-LINK-PROPERTIES"

   ))

(defPackage "XML-PARSER"
  (:nicknames "XMLP")
  (:use "BNFP" #+CCL "CCL" "COMMON-LISP" "XQDM" "XUTILS")
  #+CCL (:shadowing-import-from "XQDM" "TARGET")
  (:export
   "*CONSTRUCTION-CONTEXT*"
   "*SPECIALIZE-ELEM-NODE*"
   "*SPECIALIZE-ATTR-NODE*"
   "AttCharData-Constructor"
   "Attribute-Constructor"
   "CALL-WITH-NAME-PROPERTIES"
   "CharData-Constructor"
   "CDataCharData-Constructor"
   "Comment-Constructor"
   "CONSTRUCT-ATTRIBUTE-NAME"
   "CONSTRUCT-ATTRIBUTE-PLIST"
   "CONSTRUCT-CONSTRUCTION-CONTEXT"
   "CONSTRUCT-CONTENT-SEQUENCE"
   "CONSTRUCT-ELEM-PROPERTY-NODE"
   "CONSTRUCT-ELEMENT-NAME"
   "CONSTRUCT-ELEMENT-NODE"
   "CONSTRUCT-NS-NODE"
   "CONSTRUCT-STRING-ATTR-NODE"
   "Content-Constructor"
   "ContentSequence-Constructor"
   ;; the constructor method for attribute default values remains unexported
   ;; until specialization is implemented for the DTD as a whole...
   ;; "DefaultAttCharData-Constructor"
   "DEFPIFUNCTION"
   "Document-Constructor"
   "DOCUMENT-PARSER"
   "Element-Constructor"
   "ENCODE-CHAR"
   "ENCODE-NODE"
   "ENCODE-STRING"
   "ENCODE-NEWLINE"
   "ExtParsedEnt-Constructor"
   "Pi-Constructor"
   "PI-FUNCTION"
   "PiCharData-Constructor"
   ;; "MAKE-NCNAME"
   ;; "MAKE-UNAME"
   "PARSE-EXTERNAL-ENTITY-DATA"
   "PARSE-EXTERNAL-SOURCE"
   "PARSE-EXTERNAL-SUBSET"
   "PARSE-EXTERNAL-GENERAL-ENTITY"
   "READ-EXTERNAL-ENTITY-DATA"
   "STag-Constructor"
   "WRITE-NODE"
   "XML"
   "WITH-XML-WRITER")
  )

(defPackage "XML-PATH"
  (:nicknames "XP")
  (:use "BNFP" #+CCL "CCL" "COMMON-LISP" "XQDM" "XUTILS")
  ;; the term 'step' is central to the standard so it is shadowed rather
  ;; than using an alternative.
  (:shadow "STEP")
  #+CCL (:shadowing-import-from "XQDM" "TARGET")
  (:EXPORT
   "PATH" "STEP" "CONTEXT"
   "PATH-ELEMENT" "STEP-ELEMENT" "STEP-GENERATOR" "STEP-FILTER"
   "ENUMERATING-STEP-GENERATOR" "LIST-GENERATOR" "AXIS-GENERATOR"
   "MAP-NODES" "NAME-TEST" "NODE-SET" "NODE-TEST" "TYPE-TEST"
   "TERM" "IS-ABSOLUTE" "STEPS" "GENERATOR"
   "TEST" "PREDICATES" "SOURCE" "PREFIX" "LOCAL-PART"
   "STEP-GENERATOR-FUNCTION" "STEP-PREDICATE-FUNCTION"
   "LITERAL"
   "NODE" "LOCATION" "SIZE" "BINDINGS" "VARIABLES" "FUNCTIONS" "NAMESPACES"
   "EXPRESSION"
   
   "*CLASS.PATH*"
   "*CLASS.STEP*"
   "*CLASS.CONTEXT*"
   "*CLASS.CHILD*"
   "*DOCUMENTS*"
   )
  )

(defPackage "XML-QUERY"
  (:nicknames "XQ")
  (:use "BNFP" #+CCL "CCL" "COMMON-LISP" "XQDM" "XUTILS")
  #+CCL (:shadowing-import-from "XQDM" "TARGET")
  )


(defPackage "xml" (:use)
  (:nicknames "http://www.w3.org/XML/1998/namespace")
  (:export " " "!=" "!=" "!==" "\"" "#FIXED" "#IMPLIED" "#PCDATA" "#REQUIRED"
           "$" "%" "&" "&#" "&#x" "'" "(" "()" ")" ")*" "*" "*:" "+" ","
           "-" "-->" "->" "." ".." "/" "//" "/>" ":" ":=" "::" ":*" ";" "<" "<!" "<!--"
           "<!ATTLIST" "<!DOCTYPE" "<!ELEMENT" "<!ENTITY" "<!NOTATION"
           "<![" "<![CDATA[" "</" "<=" "<?" "<?xml" "=" "==" ">" ">=" "?" "?>"
           "@" "AFTER" "ANY" "ASCENDING" "BEFORE" "CDATA" "DESCENDING" "EMPTY"
           "ENTITIES" "ENTITY" "ID" "IDREF" "IDREFS" "IGNORE" "INCLUDE"
           "NDATA" "NMTOKEN" "NMTOKENS" "NOT" "NOTATION" "PUBLIC" "SYSTEM"
           "[" "]" "]]>" "^"
           "ancestor" "ancestor-or-self" "and" "attribute"
           "child" "comment"
           "descendant" "descendant-or-self" "div" "document"
           "encoding" "following" "following-sibling"
           "id" "key" "lang"
           "mixed" "mod" "namespace" "no" "node" "not" "or"
           "parent" "preceding" "preceding-sibling" "processing-instruction"
           "root" "self" "standalone" "text" "union" "version" "xml" "yes"
           "{" "|" "}" "�"))
;;
;;
;; packages for implementing xml data modeling.
;; types from the datatype package appear in expression in the two algrbras. they are
;; exported, but not used/imported, as the customary expression uses the prefix.
;; the case distinctions distinguish grammatic meta-symbols which participate in special
;; forms from the names for functions and types, which conserve case.

;; package for xml query types
(defPackage "XML-SCHEMA-DATATYPES" (:use) (:nicknames "XSD")
  (:export "TYPEP" "TYPEP-SPECIALIZED"
           "IS-anyComplexType" "IS-anySimpleType" "IS-anyTreeType" "IS-anyType"  "IS-anyURI"
           "IS-attribute" "IS-base64Binary" "IS-boolean" "IS-byte" "IS-comment" "IS-complex"
           "IS-date" "IS-dateTime"
           "IS-decimal" "IS-double" "IS-duration"
           "IS-element" "IS-ENTITY" "IS-ENTITIES" "IS-float"
           "IS-gDay" "IS-gMonth" "IS-gMonthDay" "IS-gYear"
           "IS-hexBinary" "IS-ID" "IS-IDREF" "IS-IDREFS"
           "IS-int" "IS-integer" "IS-language" "IS-long"
           "IS-Name" "IS-NCName" "IS-NMTOKEN" "IS-NMTOKENS"
           "IS-negativeInteger" "IS-nonNegativeInteger" "IS-nonPositiveInteger" "IS-normalizedString"
           "IS-NOTATION" "IS-pi" "IS-positiveInteger" "IS-scalar" "IS-short" "IS-simple"
           "IS-string" "IS-time" "IS-token" "IS-UName"
           "IS-unsignedByte" "IS-unsignedInt" "IS-unsignedLong" "IS-unsignedShort"
           
           "VALIDATE-STRING" "VALIDATE-ATTRIBUTE" "VALIDATE-NAME"))

;; package for xml path "algebra" operators
(defPackage "XML-PATH-ALGEBRA" (:use) (:nicknames "XPA")
  (:import-from "xml" "document")
  (:intern "APPLY-DESCENDANTS-PATH" "APPLY-CHILD-PATH" "APPLY-PATH"
           "APPLY-PREDICATE-PATH" "APPLY-STEP"
           "EVAL" "FUNCALL" "LANGUAGE-EQUAL" "NODES" "VARIABLE"
           "SYMBOL-FUNCTION" "GENSYM")
  (:export
   ;; path components
   "PATH" "STEP" "UNAME"
   "ID-STEP" "KEY-STEP" "PARENT-STEP" "ROOT-STEP" "SELF-STEP" "WILD-INFERIOR-STEP" 
   "AXIS-GENERATOR" "LIST-GENERATOR"
   "ANCESTOR" "ANCESTOR-OR-SELF" "ATTRIBUTE" "CHILD" "DESCENDANT"
   "DESCENDANT-OR-SELF" "FOLLOWING" "FOLLOWING-OR-SELF" "FOLLOWING-SIBLING"
   "ID" "KEY"
   "NAMESPACE" "PARENT" "PRECEDING" "PRECEDING-SIBLING" "ROOT" "SELF"
   "NAME-TEST" "@NAME-TEST" "TYPE-TEST" "TYPE-NAME-TEST"
   "PI-TEST" "COMMENT-TEST" "TEXT-TEST"
   "PREDICATE"
   ;; state variables
   "*CONTEXT-NODE*" "*POSITION*" "*COUNT*"
   ;; library functions
   "and"
   "boolean"
   "ceiling" "contains" "count"
   "document"
   "false" "floor"
   "id"
   "last" "local-name" "lang"
   "mod"
   "name" "namespace-uri" "normalize-space" "not"  "number"
   "or"
   "position"
   "round"
   "starts-with" "string" "substring"
   "substring-after" "substring-before"
   "string-length" "sum" 
   "translate" "true"
   "union"
   "+" "-" "*" "/" "<" "<=" ">" ">=" "=" "!="
   "NaN" "0+" "0-" "infinity+" "infinity-"
   ))

;; package for xml query algebra operators
(defPackage "XML-QUERY-ALGEBRA" (:use) (:nicknames "XQA")
  (:import-from "XPA"
                "and"
                "boolean"
                "ceiling" "contains" "count"
                "document"
                "false" "floor"
                "id"
                "last" "local-name" "lang"
                "mod"
                "name" "namespace-uri" "normalize-space" "not"  "number"
                "or"
                "position"
                "round"
                "starts-with" "string" "substring"
                "substring-after" "substring-before"
                "string-length" "sum" 
                "translate" "true"
                "union"
                ;; these are not imported "<" "<=" ">" ">=" "="
                ;; as the comparison differs
                "+" "-" "*" "/" "!="
                "NaN" "0+" "0-" "infinity+" "infinity-"
                "GENSYM")
  (:EXPORT  "IF" "LET" "ELSE" "FOR" "MATCH" "CASE" "WHERE"
            "TYPE" "FUN" "QUERY"
            "AND" "OR" "NOT" "DIV" "MOD" "SCHEMA"
            "+" "-" "*" "<" "<=" ">" ">=" "=" "==" "!=" "!=="
            "//" "/" "." "|"
            "DEFUN"
            "ATTRIBUTE" "ELEMENT"
            "MAKE-NCNAME" "MAKE-TNAME" "MAKE-UNAME"
            "sequence" "UNION" "DIFFERENCE" "INTERSECTION" "SORT"
            "ERROR" "INSTANCEOF" "BEFORE" "AFTER"
            "TYPEP" "TYPE" "SORT"
            "TYPE-REF" "ID-TEST" "TYPEP" "RANGE-TEST"
            ;; xpath algebra symbols
            "and"
            "boolean"
            "cdata" "ceiling" "contains" "count"
            "document"
            "false" "floor"
            "id"
            "last" "local-name" "lang"
            "mod"
            "name" "namespace-uri" "normalize-space" "not"  "number"
            "or"
            "position"
            "round"
            "starts-with" "string" "substring"
            "substring-after" "substring-before"
            "string-length" "sum" 
            "translate" "true"
            "union"
            "NaN" "0+" "0-" "infinity+" "infinity-"
            ;; xml query algebra specific
            "avg"
            "bagtolist"
            "data" "difference" "distinct_nodes" "distinct_value"
            "comment" "Comment" "deref" 
            "except"
            "index" "intersection"
            "listtobag" "localname"
            "max" "min"
            "namespace" "nodes"
            "parent" "processing_instruction"
            "ref"
            "sequence" "sort"
             "target"
             "value"


            "empty"
             "==" ))

(defPackage "$" (:use))

(defpackage "XML-QUERY-LANGUAGE" (:use) (:nicknames "XQL")
  (:import-from "XPA"
                "and"
                "boolean"
                "ceiling" "contains" "count"
                "document"
                "false" "floor"
                "id"
                "last" "local-name" "lang"
                "mod"
                "name" "namespace-uri" "normalize-space" "not"  "number"
                "or"
                "position"
                "round"
                "starts-with" "string" "substring"
                "substring-after" "substring-before"
                "string-length" "sum"  
                "translate" "true"
                "union"
                "+" "-" "*" "/" "!="
                "NaN" "0+" "0-" "infinity+" "infinity-")
  (:import-from "XQA"
                "<" "<=" ">" ">=" "=")
  (:export "ELEMENT" "ATTRIBUTE" "CAST" "TREAT" "INTERSECT" "EXCEPT"
           "INSTANCEOF" "SOME" "EVERY" "FUNCTION"
           "FUNCALL"  "NAMESPACE-DECL" "QNAME"  "SCHEMA-DECL"
           "ID-PATH" "ATTRIBUTE-PATH" "TYPE-PATH" "ELEMENT-PATH"
           "RANGE" "/" "//" "*" "STEP" "TYPE"
           ;; xpath algebra symbols
           "and"
           "boolean"
           "ceiling" "contains" "count"
           "document"
           "false" "floor"
           "id"
           "last" "local-name" "lang"
           "mod"
           "name" "namespace-uri" "normalize-space" "not"  "number"
           "or"
           "position"
           "round"
           "starts-with" "string" "substring"
           "substring-after" "substring-before"
           "string-length" "sum" 
           "translate" "true"
           "union"
           "+" "-" "*" "/" "<" "<=" ">" ">=" "=" "!="
           "NaN" "0+" "0-" "infinity+" "infinity-"
           ;; xquery language library 
           "comment" "date" "distinct"
           "empty" "equal" "filter" "last"
           "name" "number" "pi" "union"))


;; additions for cl-http tokenizer
#-CL-HTTP
(defpackage "WWW-UTILS"
  (:use common-lisp)
  (:intern "WITH-FAST-ARRAY-REFERENCES" "MAKE-LOCK" "WITH-LOCK-HELD"))

#-CL-HTTP
(defpackage tk1
  (:use common-lisp)
  (:import-from "WWW-UTILS" "WITH-FAST-ARRAY-REFERENCES" "MAKE-LOCK" "WITH-LOCK-HELD")
  (:export
   "*DEFAULT-TOKENIZER-SIZE*"
   "CLEAR-TOKENIZER"
   "CREATE-TOKENIZER"
   "DEFINE-TOKENIZER"
   "DESCRIBE-TOKENIZER"
   "FIND-TOKENIZER-NAMED"
   "GET-TOKEN"
   "INSERT-TOKEN"
   "MAP-TOKENS"
   "REHASH-TOKENIZER"
   "REMOVE-TOKEN"
   "TOKENIZE"
   "UNDEFINE-TOKENIZER"))

#-CL-HTTP
(defPackage "HTTP"
  (:export "*STANDARD-CHARACTER-TYPE*"))

:EOF



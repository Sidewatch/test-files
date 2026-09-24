;; CLIPS: a tiny diagnostic expert system.
(deftemplate symptom (slot name) (slot severity (type INTEGER) (default 1)))
(deftemplate diagnosis (slot condition) (slot confidence (type FLOAT)))

(deffacts initial-symptoms
  (symptom (name fever) (severity 3))
  (symptom (name cough) (severity 2)))

(defrule flu-suspected
  (symptom (name fever) (severity ?s&:(> ?s 2)))
  (symptom (name cough))
  =>
  (assert (diagnosis (condition flu) (confidence 0.75)))
  (printout t "Flu suspected (fever severity " ?s ")" crlf))

(defrule report
  (diagnosis (condition ?c) (confidence ?p))
  =>
  (printout t "Diagnosis: " ?c " at " (* ?p 100) "%" crlf))

(deffunction average (?a ?b)
  (/ (+ ?a ?b) 2))

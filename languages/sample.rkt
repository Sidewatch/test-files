#lang racket
;; Racket: structs, pattern matching and a small contract.

(require racket/contract)

(struct order (number total status) #:transparent)

(define/contract (revenue orders)
  (-> (listof order?) real?)
  (for/sum ([o orders] #:when (eq? (order-status o) 'paid))
    (order-total o)))

(define (describe o)
  (match o
    [(order n _ 'paid) (format "#~a paid" n)]
    [(order n _ 'pending) (format "#~a pending" n)]
    [(order n _ (list 'cancelled reason)) (format "#~a cancelled: ~a" n reason)]))

(define orders
  (list (order 1 120.5 'paid)
        (order 2 42 'pending)
        (order 3 0 '(cancelled "duplicate"))))

(for-each (compose displayln describe) orders)
(printf "revenue: ~a\n" (revenue orders))

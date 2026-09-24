;; Scheme (R7RS): a closure-based counter, a higher-order fold, and a macro.
(import (scheme base) (scheme write))

(define (make-counter step)
  (let ((count 0))
    (lambda ()
      (set! count (+ count step))
      count)))

(define (fold f init lst)
  (if (null? lst)
      init
      (fold f (f init (car lst)) (cdr lst))))

(define-syntax unless
  (syntax-rules ()
    ((_ test body ...) (if (not test) (begin body ...)))))

(define orders '((1 120.5 paid) (2 42 pending) (3 0 cancelled)))

(define (revenue orders)
  (fold (lambda (acc o) (if (eq? (caddr o) 'paid) (+ acc (cadr o)) acc)) 0 orders))

(define tick (make-counter 5))
(tick) (tick)
(unless (zero? (revenue orders))
  (display "revenue: ") (display (revenue orders)) (newline))
(display (string-append "ticks: " (number->string (tick)))) (newline)   ; 15

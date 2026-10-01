#lang racket
;; Racket 8.18 — syntax showcase
;; ── Comments ──
;; Racket showcase: warehouse inventory with structs, macros and contracts.
;; TODO: persist the catalogue. FIXME: reorder amounts ignore pack size.

#| A block comment
   #| with a nested block comment |#
   spanning lines. |#

#;(this whole datum is commented out with a datum comment)

(module+ main
  (displayln "main submodule"))

(module+ test
  (require rackunit)
  (check-equal? (+ 1 2) 3))

(module inner racket/base
  (provide helper)
  (define (helper) 'ok))

;; ── Requires and provides ──
(require racket/contract
         racket/list
         racket/match
         racket/string
         (prefix-in s: racket/set)
         (only-in racket/math pi sqr)
         (except-in racket/format ~a)
         (rename-in racket/vector [vector-map vmap])
         "helpers.rkt"
         (file "/tmp/local.rkt")
         (lib "racket/base")
         (planet example/inventory:1:0)
         (for-syntax racket/base))

(provide revenue
         (struct-out order)
         (contract-out [describe (-> order? string?)])
         (all-defined-out))

;; ── Literals ──
(define numbers
  (list 42 -7 +5 3.14 -2.5e3 1e-3 #xFF #b1010 #o755 #e1.5 #i3/4 1/2 -3/4
        +inf.0 -inf.0 +nan.0 1+2i 3.0-4.5i #d10 1e3 6.022e23))

(define chars (list #\a #\space #\newline #\tab #\nul #\x41 #λ #\U0001F4E6 #\( #\;))
(define bools (list #t #f #true #false))

(define strings
  (list "plain string"
        "escapes: \n \t \\ \" \a \b \e \f \r \v \101 \x41 λ \U0001F4E6 \
         continued"
        #<<HERE
here string, with "quotes" and \n unescaped
spanning lines
HERE
        #"byte string \x00\xff"
        #rx"^AC-[0-9]{4}$"
        #px"\\d+(?:\\.\\d+)?"
        #rx#"bytes regex"
        #px#"\\d+"))

(define symbols (list 'sym '|symbol with spaces| 'a.b 'λ '->arrow '<=? 'set! 'x->y))
(define keywords (list '#:keyword '#:another-kw))
(define quoted '(a b (c d) . e))
(define vec #(1 2 3))
(define vec2 #3(1 2))
(define hash1 #hash((a . 1) (b . 2)))
(define hash2 #hasheq((x . 1)))
(define hash3 #hashalw((k . v)))
(define box1 #&"boxed")
(define fl #fl(1.0 2.0))
(define quasi `(1 ,(+ 1 1) ,@(list 3 4)))
(define syntax-quoted #'(a b))
(define quasi-syntax #`(a #,(+ 1 2) #,@(list 3)))
(define prefab #s(point 1 2))
(define path-literal (build-path "a" 'up "b"))

;; ── Definitions ──
(define REORDER-POINT 25)
(define tax-rate 0.075)
(define-values (lo hi) (values 0 100))
(define ((curried a) b) (+ a b))

(define (add a b) (+ a b))
(define (optional a [b 2] #:scale [scale 1.0] #:flag flag . rest)
  (* scale (+ a b (length rest))))

(define square (λ (x) (* x x)))
(define cube (lambda (x) (* x x x)))
(define case-lam (case-lambda [(x) x] [(x y) (+ x y)] [args (apply + args)]))

(define/contract (revenue orders)
  (-> (listof order?) real?)
  (for/sum ([o orders] #:when (eq? (order-status o) 'paid))
    (order-total o)))

;; ── Structs ──
(struct order (number total status) #:transparent)
(struct point (x y) #:mutable #:prefab)
(struct 3d-point point (z) #:guard (λ (x y z name) (values x y z)))
(struct item (sku [qty #:auto]) #:auto-value 0 #:property prop:custom-write
  (λ (self port mode) (write-string "<item>" port)))

;; ── Control flow ──
(define (describe o)
  (match o
    [(order n _ 'paid) (format "#~a paid" n)]
    [(order n _ 'pending) (format "#~a pending" n)]
    [(order n _ (list 'cancelled reason)) (format "#~a cancelled: ~a" n reason)]
    [(? string? s) s]
    [(list a b ...) (apply + a b)]
    [(vector x y) (list x y)]
    [(cons h t) h]
    [(and x (not 0)) x]
    [(or 1 2) 'small]
    [_ "unknown"]))

(define (classify n)
  (cond
    [(< n 0) 'negative]
    [(= n 0) 'zero]
    [(and (> n 0) (< n 10)) 'small]
    [else 'large]))

(define (branches x)
  (if (zero? x) 'zero 'nonzero)
  (when (> x 0) (displayln "positive"))
  (unless (> x 0) (displayln "not positive"))
  (case x
    [(1 2 3) 'low]
    [(4 5 6) 'mid]
    [else 'high])
  (and #t x)
  (or #f x))

(define (loops lst)
  (for ([x lst]) (display x))
  (for/list ([x (in-range 10)] [y (in-naturals)] #:when (even? x)) (* x y))
  (for/vector ([x lst]) x)
  (for/hash ([k '(a b)] [v '(1 2)]) (values k v))
  (for/fold ([sum 0] [n 0]) ([x lst]) (values (+ sum x) (add1 n)))
  (for*/list ([x '(1 2)] [y '(a b)]) (cons x y))
  (for/and ([x lst]) (> x 0))
  (for/first ([x lst] #:when (> x 1)) x)
  (let loop ([i 0])
    (when (< i 3)
      (loop (add1 i)))))

;; ── Binding forms ──
(define (bindings)
  (let ([a 1] [b 2]) (+ a b))
  (let* ([a 1] [b (+ a 1)]) b)
  (letrec ([even? (λ (n) (if (zero? n) #t (odd? (sub1 n))))]
           [odd? (λ (n) (if (zero? n) #f (even? (sub1 n))))])
    (even? 10))
  (let-values ([(q r) (quotient/remainder 17 5)]) (list q r))
  (define-values (x y) (values 1 2))
  (set! x 10)
  (parameterize ([current-output-port (open-output-string)]) (display "hidden"))
  (with-handlers ([exn:fail? (λ (e) (exn-message e))]
                  [string? values])
    (raise "boom"))
  (dynamic-wind (λ () (void)) (λ () 'body) (λ () (void)))
  (call/cc (λ (k) (k 1)))
  (let/ec return (return 5)))

;; ── Macros ──
(define-syntax-rule (swap! a b)
  (let ([tmp a]) (set! a b) (set! b tmp)))

(define-syntax unless*
  (syntax-rules ()
    [(_ test body ...) (if (not test) (begin body ...) (void))]))

(define-syntax (my-if stx)
  (syntax-case stx ()
    [(_ c t e) #'(cond [c t] [else e])]))

(define-syntax (with-logging stx)
  (syntax-parse stx
    [(_ name:id body:expr ...)
     #:with msg (format "entering ~a" (syntax-e #'name))
     #'(begin (displayln msg) body ...)]))

(begin-for-syntax
  (define (helper-at-phase-1) 1))

;; ── Classes, units, generics ──
(define warehouse%
  (class object%
    (super-new)
    (init-field name)
    (field [bins 0])
    (define/public (capacity) (* bins 100))
    (define/private (secret) 1)
    (define/override (to-string) name)))

(define-generics printable (gen-print printable [port]))

(define w (new warehouse% [name "north"]))
(send w capacity)

;; ── Data ──
(define orders
  (list (order 1 120.5 'paid)
        (order 2 42 'pending)
        (order 3 0 '(cancelled "duplicate"))))

(define table (make-hash '((a . 1))))
(hash-set! table 'b 2)
(hash-ref table 'a #f)
(string-append "a" (number->string 42) (symbol->string 'sym))
(regexp-match #px"(\\d+)-(\\d+)" "10-20")
(apply + 1 2 '(3 4))
(map (curry + 1) '(1 2 3))
(sort '(3 1 2) <)
(vector-ref vec 0)
(printf "revenue: ~a\n" (revenue orders))
(fprintf (current-error-port) "~s ~v ~e\n" "s" 'v 1)

;; ── More literal forms ──
(define more-numbers
  (list #e1.2 #i1/3 #x-ff #b-101 #o-17 #d1.5 #e#x10 #x#e10 1@2 +i -i +inf.f -inf.f +nan.f 1.5f0 1.0t0 +inf.t
        1e3 1E3 1d3 1s3 1l3 1#.# 12## 1/2 -1/2 +1/2 1e-3 .5 5. -.5e1))

(define more-chars
  (list #\backspace #\delete #\rubout #\linefeed #\return #\vtab #\page #\null #A #\U1F4E6 #\101 #\x #\λ #\) #\"))

(define more-strings
  (list "multi
line"
        "λ \U0001F4E6 \x41 \101 \0 \a \b \t \n \v \f \r \e \" \' \\"
        #<<END-OF-DATA
here string with a custom terminator
  indentation is kept
END-OF-DATA
        #"bytes \377 \x7f \n"
        #rx"a|b" #px"(?i:abc)" #rx#"b" #px#"\\w+"))

(define more-symbols
  (list 'a\ b '|with|bar| '|a\|b| '|| 'a.b.c '1+ '- '... '_ '-> '->* '=> '<=> '!x '$y '%z '&w '*v* '/u '~t '^s 'λ→ '#%app '#%kernel
        (string->symbol "dyn") (string->uninterned-symbol "u") (gensym)))

(define more-data
  (list '() '(1 . 2) '(1 2 . 3) '[a b] '{c d} '#(1 #(2)) '#hash() '#hasheqv((1 . 2)) '#:kw '#"b" '#rx"x" '#&1 '#s(p 1)
        (quote x) (quasiquote (a (unquote b) (unquote-splicing c))) (syntax x) (quasisyntax (a (unsyntax b)))
        #'x #`(a #,b #,@c) '#true '#false #t #f #T #F
        (vector 1 2) (vector-immutable 1) (box 1) (make-hash) (make-weak-hash) (set 1 2) (mutable-set)))

;; ── Keywords, optional arguments, apply ──
(define (kw-fun a #:b b [c 3] #:d [d 4] . rest)
  (list a b c d rest))
(define kw-lam (lambda (a #:k [k 1]) (+ a k)))
(kw-fun 1 #:b 2 #:d 5 'x 'y)
(apply kw-fun '(1 2) '(#:b) '(2))
(keyword-apply kw-fun '(#:b) '(2) '(1))
(define kw-case (case-lambda [() 0] [(a) a] [(a . rest) (apply + a rest)]))
(define-values (q r) (quotient/remainder 7 2))
(define-syntax-rule (my-or a b) (let ([t a]) (if t t b)))

;; ── Match: every pattern kind ──
(define (match-demo v)
  (match v
    [(list 1 2 3) 'exact]
    [(list a b ...) b]
    [(list-rest a b rest) rest]
    [(list* a b rest) rest]
    [(cons a (cons b _)) a]
    [(vector a b ...) b]
    [(hash-table ('k val) _ ...) val]
    [(struct order (n t s)) n]
    [(order n _ _) #:when (> n 0) n]
    [(? number? n) (* n 2)]
    [(? string? (app string-length 3)) 'three]
    [(app car 1) 'starts-with-1]
    [(== 5) 'five]
    [(quote sym) 'symbol]
    [`(a ,b ,@c) b]
    [(regexp #rx"^a(.*)" (list _ rest)) rest]
    [(pregexp #px"\\d+") 'digits]
    [(and (? integer?) (not 0)) 'nonzero]
    [(or 'a 'b 'c) 'abc]
    [(box x) x]
    [(or (? symbol?) (? string?)) 'text]
    [(list (list a b) ...) a]
    [(list (? number? n) ...) n]
    [x #:when (void? x) 'void]
    [_ 'other]))

(match-define (list first-item second-item) '(1 2))
(match-let ([(list a b) '(1 2)]) (+ a b))
(match-let* ([(list a) '(1)] [b (+ a 1)]) b)
(match-letrec ([(list a) '(1)]) a)
(match* (1 2) [(1 2) 'ok] [(_ _) 'no])
(match-lambda [(list a b) (+ a b)])
(match-lambda** [(1 2) 'a] [(_ _) 'b])
(define/match (fact n) [(0) 1] [(n) (* n (fact (sub1 n)))])

;; ── Contracts: every combinator ──
(define/contract (contracted a b)
  (->* (integer?) (real? #:key string?) #:rest (listof any/c) (or/c number? #f))
  (+ a b))
(define dep-contract (->i ([n (and/c integer? (>=/c 0))] [m (n) (and/c integer? (>=/c n))]) [result (n m) (>=/c (+ n m))]))
(define struct-contract (struct/c order integer? number? symbol?))
(define other-contracts
  (list (listof integer?) (non-empty-listof string?) (vectorof number?) (hash/c symbol? any/c) (cons/c any/c any/c)
        (list/c integer? string?) (one-of/c 'a 'b) (symbols 'a 'b) (between/c 1 10) (integer-in 0 255) (real-in 0.0 1.0)
        (=/c 1) (</c 5) (>/c 0) (<=/c 5) (>=/c 0) (not/c null?) (flat-named-contract 'positive positive?) (recursive-contract any/c)
        (promise/c any/c) (parameter/c any/c) (box/c any/c) (set/c any/c) (maybe/c integer?) (-> integer? integer?) (->m integer? integer?)
        (case-> (-> integer? integer?) (-> integer? integer? integer?)) (new-∀/c) (syntax/c any/c) any/c none/c any))

;; ── Loops: all iteration forms and sequences ──
(define (loop-forms lst)
  (for/sum ([x (in-list lst)]) x)
  (for/product ([x (in-vector (vector 1 2))]) x)
  (for/last ([x (in-string "abc")]) x)
  (for/or ([x (in-hash (hash 'a 1))]) x)
  (for/set ([x (in-range 5)]) x)
  (for/hasheq ([(k v) (in-hash (hash 'a 1))]) (values k v))
  (for/mutable-hash ([x '(1 2)]) (values x x))
  (for/lists (as bs) ([x lst]) (values x x))
  (for/fold ([acc '()] #:result (reverse acc)) ([x lst]) (cons x acc))
  (for*/fold ([acc 0]) ([x lst] [y lst]) (+ acc x y))
  (for*/vector ([x lst] [y lst]) (* x y))
  (for*/sum ([x '(1 2)] [y '(3 4)]) (* x y))
  (for ([(k v) (in-hash (hash 'a 1))] [i (in-naturals 1)] #:break (> i 5) #:unless (zero? i)) (displayln k))
  (for ([x (in-range 0 10 2)] #:final (> x 6)) (displayln x))
  (for ([line (in-lines (open-input-string "a\nb"))]) (displayln line))
  (for ([c (in-port read-char (open-input-string "ab"))]) c)
  (for ([x (in-sequences '(1 2) '(3))] [y (in-cycle '(a b))]) (list x y))
  (for ([(i x) (in-indexed '(a b))]) i)
  (for ([x (stop-before (in-naturals) (λ (n) (> n 3)))]) x)
  (for ([x (in-producer read-line eof (open-input-string "z"))]) x)
  (do ([i 0 (add1 i)] [acc '() (cons i acc)]) ((= i 3) acc)))

;; ── Syntax: syntax-parse, syntax classes, macros that generate macros ──
(require (for-syntax racket/base syntax/parse racket/syntax))

(define-syntax-parse-rule (my-let1 [id:id val:expr] body:expr ...+)
  ((λ (id) body ...) val))

(begin-for-syntax
  (define-syntax-class binding
    #:description "binding pair"
    (pattern [name:id expr:expr]))
  (define-splicing-syntax-class opt-kw
    (pattern (~seq #:key k:expr))))

(define-syntax (my-let stx)
  (syntax-parse stx
    #:literals (else)
    [(_ (b:binding ...) body ...+)
     #:with (tmp ...) (generate-temporaries #'(b.name ...))
     #:fail-when (check-duplicate-identifier (syntax->list #'(b.name ...))) "duplicate"
     #'(let ([b.name b.expr] ...) body ...)]
    [(_ (~optional (~seq #:debug dbg:boolean)) (~or* x y) . rest) #'(void)]
    [(_ . _) (raise-syntax-error 'my-let "bad syntax" stx)]))

(define-syntax define-getter
  (syntax-rules ()
    [(_ name field) (define (name o) (hash-ref o 'field))]
    [(_ name field ...) (begin (define-getter name field) ...)]))

(define-syntax-rule (def-macro name)
  (define-syntax-rule (name x (... ...)) (list x (... ...))))

(define-for-syntax phase1-value 42)
(define-syntax (use-phase1 stx) (datum->syntax stx phase1-value))
(define-syntax-rule (with-ellipsis (a ...) ...) '((a ...) ...))
(let-syntax ([m (syntax-rules () [(_ x) x])]) (m 1))
(letrec-syntax ([m (syntax-rules () [(_) 1])]) (m))
(define-syntaxes (s1 s2) (values (syntax-rules () [(_) 1]) (syntax-rules () [(_) 2])))
(define-syntax-parameter current-thing #f)
(syntax-parameterize ([current-thing #'1]) (void))
(define-simple-macro (twice e) (begin e e))

;; ── Classes, mixins, interfaces, units, generics ──
(define shape<%> (interface () area name))
(define circle%
  (class* object% (shape<%> equal<%>)
    (super-new)
    (init radius [unit 'cm])
    (init-field [id 0] [label "c"])
    (field [r radius])
    (inherit-field id)
    (public area name)
    (define (area) (* pi r r))
    (define (name) 'circle)
    (define/public (scale k) (set! r (* r k)))
    (define/public-final (final-m) 1)
    (define/pubment (inner-m) (inner 0 inner-m))
    (define/augment (aug-m) 1)
    (define/override (to-string) "circle")
    (define/override-final (ov-final) 1)
    (define/augride (aug-ride) 1)
    (define/overment (over-m) 1)
    (abstract abs-m)
    (init-rest rest)
    (inspect #f)
    (public-field pf 1)
    (define/public (equal-to? other recur) #t)
    (define/public (equal-hash-code-of recur) 1)
    (define/public (equal-secondary-hash-code-of recur) 1)))

(define fancy-mixin (mixin (shape<%>) (shape<%>) (super-new) (define/override (name) 'fancy)))
(define fancy-circle% (fancy-mixin circle%))
(define c (new circle% [radius 2]))
(send c area)
(send* c (scale 2) (area))
(send/apply c scale '(2))
(get-field r c)
(set-field! r c 5)
(field-bound? r c)
(is-a? c shape<%>)
(make-object circle% 1)
(instantiate circle% (1) [id 5])
(define-member-name secret (member-name-key secret))
(with-method ([a (c area)]) (a))

(define-signature inventory^ (stock reorder))
(define-unit inventory@ (import) (export inventory^) (define (stock) 1) (define (reorder) 2))
(define-values/invoke-unit inventory@ (import) (export inventory^))

(struct animal (name) #:methods gen:custom-write [(define (write-proc a port mode) (write-string "<animal>" port))])
(struct dog animal () #:super struct:animal #:omit-define-syntaxes #:constructor-name make-dog #:extra-constructor-name dog* #:reflection-name 'dog #:authentic #:sealed)
(struct pt (x y) #:property prop:procedure (λ (self n) n) #:methods gen:equal+hash [(define (equal-proc a b rec) #t) (define (hash-proc a rec) 1) (define (hash2-proc a rec) 1)])

;; ── Concurrency, I/O, parameters ──
(define ch (make-channel))
(define th (thread (λ () (channel-put ch 'done))))
(channel-get ch)
(sync (alarm-evt (+ (current-inexact-milliseconds) 10)) (handle-evt ch values))
(thread-wait th)
(define sema (make-semaphore 1))
(call-with-semaphore sema (λ () 1))
(define pl (place pch (place-channel-put pch 1)))
(define fut (future (λ () 1)))
(touch fut)
(define p (make-parameter 1 (λ (v) v)))
(parameterize ([p 2] [current-output-port (current-error-port)]) (p))
(define-logger my-log)
(log-my-log-info "message ~a" 1)
(with-output-to-string (λ () (display "x")))
(call-with-output-string (λ (o) (write 'x o)))
(call-with-input-file "in.txt" (λ (in) (read-line in)))
(call-with-output-file "out.txt" #:exists 'truncate (λ (out) (displayln "x" out)))
(let ([in (open-input-file "in.txt")]) (begin0 (read in) (close-input-port in)))
(define-runtime-path here ".")
(require racket/runtime-path (for-label racket) (for-meta 1 racket/base) (for-template racket/base) (submod "." test) (submod ".." main))
(provide (rename-out [add plus]) (prefix-out my: add) (except-out (all-from-out racket/list) first) (for-syntax phase1-value) (matching-identifiers-out #rx"^x" (all-defined-out)))
(module* extra #f (displayln "module* with #f sees enclosing bindings"))
(module reader syntax/module-reader racket)
(begin0 1 2 3)
(let/cc k (k 1))
(with-continuation-mark 'key 'val (continuation-mark-set-first #f 'key))
(call-with-current-continuation (λ (k) (k 1)))
(call-with-escape-continuation (λ (k) (k 1)))
(prompt-tag? (make-continuation-prompt-tag))
(call-with-continuation-prompt (λ () (abort-current-continuation (default-continuation-prompt-tag) void)))
(delay 1) (force (delay 1)) (lazy 1) (promise? (delay 1))
(define-struct legacy (a b))
(time (void))
(error 'who "message ~a" 1)
(raise-argument-error 'f "integer?" 'x)
(raise-user-error "bad")
(assert (> 1 0))
(void? (void))
(exit 0)

(for-each (compose displayln describe) orders)
(module+ main (main))
(define (main) (void))

#lang parendown racket/base

; main.rkt
;
; Unit tests of the higher quasiquotation system, particularly the
; `-quasiquote` macro.

(require #/for-meta 1 racket/base)

(require rackunit)

(require lexmeta/single-phase/private/qq)

; (We provide nothing from this module.)


; This takes something that might or might not be syntax, and it
; "de-syntaxes" it recursively.
(define (destx x)
  (syntax->datum #/datum->syntax #'foo x))


(begin-for-syntax #/print-syntax-width 10000)


(check-equal? (destx #/-quasiquote 1) 1
  "Quasiquoting a self-quoting literal")
(check-equal? (destx #/-quasiquote a) 'a "Quasiquoting a symbol")
(check-equal? (destx #/-quasiquote (a b c)) '(a b c)
  "Quasiquoting a list")
(check-equal? (destx #/-quasiquote (a (b c) z)) '(a (b c) z)
  "Quasiquoting a nested list")
(check-equal?
  (destx #/-quasiquote (a (b (-unquote 1)) z))
  '(a (b 1) z)
  "Unquoting a self-quoting literal")
(check-equal?
  (destx #/-quasiquote (a (b (-unquote 'c)) z))
  '(a (b c) z)
  "Unquoting a quoted symbol")
(check-equal?
  (destx #/-quasiquote (a (b (-unquote list)) z))
  `(a (b ,list) z)
  "Unquoting a variable")
(check-equal?
  (destx #/-quasiquote (a (b (-unquote (+ 1 2 3))) z))
  '(a (b 6) z)
  "Unquoting an expression")
(check-equal?
  (destx
  #/-quasiquote
    (a (b (-unquote #/-quasiquote #/1 2 #/-unquote #/+ 1 2 3)) z))
  '(a (b (1 2 6)) z)
  "Unquoting another quasiquotation")
(check-equal?
  (destx
  #/-quasiquote
    (a (b (-quasiquote #/1 #/-unquote #/+ 2 #/-unquote #/+ 1 2 3)) z))
  '(a (b (-quasiquote #/1 #/-unquote #/+ 2 6)) z)
  "Nesting quasiquotations")


; This is a set of unit tests we used in a previous incarnation of
; this code.
(check-equal?
  (destx #/-quasiquote #/foo (bar baz) () qux)
  '(foo (bar baz) () qux)
  "Quasiquoting a nested list again")
(check-equal?
  (destx #/-quasiquote #/foo (bar baz) (-quasiquote ()) qux)
  '(foo (bar baz) (-quasiquote ()) qux)
  "Quasiquoting a nested list containing a quasiquoted empty list")
(check-equal?
  (destx #/-quasiquote #/foo (bar baz) (-unquote (* 1 123456)) qux)
  '(foo (bar baz) 123456 qux)
  "Unquoting an expression again")
(check-equal?
  (destx
  #/-quasiquote #/foo
  #/-quasiquote #/bar #/-unquote #/baz #/-unquote #/* 1 123456)
  '(foo #/-quasiquote #/bar #/-unquote #/baz 123456)
  "Nesting quasiquotations again")
#lang parendown racket/base

; expanders.rkt
;
; Syntax expanders for q-expression-building macros (aka bracros) as
; well as an implementation of bracroexpansion.

;   Copyright 2017-2018 The Lathe Authors
;
;   Licensed under the Apache License, Version 2.0 (the "License");
;   you may not use this file except in compliance with the License.
;   You may obtain a copy of the License at
;
;       http://www.apache.org/licenses/LICENSE-2.0
;
;   Unless required by applicable law or agreed to in writing,
;   software distributed under the License is distributed on an
;   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
;   either express or implied. See the License for the specific
;   language governing permissions and limitations under the License.


(require #/for-meta -1 racket/base)
(require racket/match)

(require #/only-in lathe-comforts dissect expect fn w-)
(require #/only-in lathe-comforts/maybe just nothing)

(require "trees.rkt")

(provide #/all-defined-out)




; This struct property indicates a syntax's behavior as a
; q-expression-building macro (aka a bracro).
(define-values (prop:q-expr-syntax q-expr-syntax? q-expr-syntax-ref)
  (make-struct-type-property 'q-expr-syntax))

(define (q-expr-syntax-maybe x)
  (if (q-expr-syntax? x)
    (list #/q-expr-syntax-ref x)
    (list)))

(struct bracket-syntax (impl)
  #:property prop:q-expr-syntax
  (lambda (this stx)
    (expect this (bracket-syntax impl)
      (error "Expected this to be a bracket-syntax")
    #/impl stx)))

; TODO: See if we'll use this.
(struct initiate-bracket-syntax (impl)
  
  ; Calling an `initiate-bracket-syntax` as a q-expression-building
  ; macro (aka a bracro) makes it call its implementation function
  ; directly.
  #:property prop:q-expr-syntax
  (lambda (this stx)
    (expect this (initiate-bracket-syntax impl)
      (error "Expected this to be an initiate-bracket-syntax")
    #/impl stx))
  
  ; Calling an `initiate-bracket-syntax` as a Racket macro makes it
  ; call its implementation function and then instantiate the
  ; resulting hole-free `hoqq-closing-hatch` to create a Racket
  ; syntax value. If the `hoqq-closing-hatch` has any holes or
  ; unmatched closing brackets, there's an error.
  #:property prop:procedure
  (lambda (this stx)
    (expect this (initiate-bracket-syntax impl)
      (error "Expected this to be an initiate-bracket-syntax")
    #/expect (impl stx)
      (hoqq-closing-hatch
        lower-spansig closing-brackets partial-span-step)
      (error "Expected an initiate-bracket-syntax result that was a hoqq-closing-hatch")
    #/if (hoqq-tower-has-any? lower-spansig)
      (error "Expected an initiate-bracket-syntax result with no holes")
    #/if (hoqq-tower-has-any? closing-brackets)
      (error "Expected an initiate-bracket-syntax result with no unmatched closing brackets")
    #/expect (hoqq-span-step-instantiate partial-span-step)
      (escapable-expression literal expr)
      (error "Expected an initiate-bracket-syntax result to be a span step that instantiated to an escapable-expression")
      expr))
)

(struct syntax-and-bracket-syntax (syntax-impl bracket-syntax-impl)
  
  #:property prop:procedure
  (lambda (this stx)
    (expect this
      (syntax-and-bracket-syntax syntax-impl bracket-syntax-impl)
      (error "Expected this to be a syntax-and-bracket-syntax")
    #/syntax-impl stx))
  
  #:property prop:q-expr-syntax
  (lambda (this stx)
    (expect this
      (syntax-and-bracket-syntax syntax-impl bracket-syntax-impl)
      (error "Expected this to be a syntax-and-bracket-syntax")
    #/bracket-syntax-impl stx))
)



(define (bracroexpand-list stx lst)
  (if (syntax? lst)
    (bracroexpand-list lst #/syntax-e lst)
  #/match lst
    [(cons first rest)
    ; TODO: Support splicing.
    #/expect (bracroexpand first)
      (hoqq-closing-hatch first-lower-spansig first-closing-brackets
      #/hoqq-span-step first-sig first-func)
      (error "Expected a bracroexpansion result that was a hoqq-closing-hatch")
    #/dissect (bracroexpand-list stx rest)
      (hoqq-closing-hatch rest-lower-spansig rest-closing-brackets
      #/hoqq-span-step rest-sig rest-func)
    #/dissect (hoqq-tower-pair-ab first-sig rest-sig)
      (list sig de-pair)
    #/careful-hoqq-closing-hatch
      (hoqq-tower-merge-ab first-lower-spansig rest-lower-spansig)
      (hoqq-tower-merge-ab
        first-closing-brackets rest-closing-brackets)
    #/careful-hoqq-span-step sig #/lambda (span-steps)
      (dissect (de-pair span-steps)
        (list first-span-steps rest-span-steps)
      #/expect (first-func first-span-steps)
        (escapable-expression first-literal first-expr)
        (error "Expected the hoqq-span-step result to be an escapable-expression")
      #/expect (rest-func rest-span-steps)
        (escapable-expression rest-literal rest-expr)
        (error "Expected the hoqq-span-step result to be an escapable-expression")
      #/escapable-expression
        #`#`(#,#,first-literal . #,#,rest-literal)
      #/datum->syntax stx #/cons first-expr rest-expr)]
    [(list) #/hoqq-closing-hatch-simple #/datum->syntax stx lst]
    [_ #/error "Expected a list"]))

(define (syntax-local-maybe identifier)
  (if (identifier? identifier)
    (w- dummy (list #/list)
    #/w- local (syntax-local-value identifier #/fn dummy)
    #/if (eq? local dummy)
      (nothing)
      (just local))
    (nothing)))

(define (bracroexpand stx)
  (match (syntax-e stx)
    [(cons first rest)
    #/expect (syntax-local-maybe first) (just local)
      (bracroexpand-list stx stx)
    #/expect (q-expr-syntax-maybe local) (list q-expr-syntax)
      (bracroexpand-list stx stx)
    
    ; TODO: See if we can call this more like a Racket syntax
    ; transformer. We'll need to do at least this:
    ;
    ;   - Disarm `stx`. The caller may not have permission to do this,
    ;     in which case we may need to devise a way to trampoline to
    ;     the Racket macroexpander by first having the caller expand
    ;     to a syntax that calls this code on a second pass.
    ;
    ;   - Remove any `'taint-mode` and `'certify-mode` syntax
    ;     properties from `stx`.
    ;
    ;   - Rearm the result, and apply syntax properties to the result
    ;     that correspond to the syntax properties of `stx`. Since the
    ;     result is a `hoqq-closing-bracket`, these steps would be
    ;     performed by post-composing an operation onto the end of the
    ;     `func` of the `partial-span-step`.
    ;
    #/q-expr-syntax local stx]
    ; TODO: We support lists, but let's also support vectors and
    ; prefabricated structs, like Racket's `quasiquote` and
    ; `quasisyntax` do.
    [_ #/hoqq-closing-hatch-simple stx]))

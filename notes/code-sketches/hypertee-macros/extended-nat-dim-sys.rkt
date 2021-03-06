#lang parendown racket/base

; extended-nat-dim-sys.rkt
;
; A dimension system where the dimension numbers are the naturals and
; a special `omega` value that's greater than all the others.

;   Copyright 2019-2021 The Lathe Authors
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


(require #/only-in racket/contract/base -> any/c contract-out or/c)
(require #/only-in racket/math natural?)

(require #/only-in lathe-comforts expect fn mat w-loop)
(require #/only-in lathe-comforts/struct
  auto-equal auto-write define-imitation-simple-struct)
(require #/only-in lathe-morphisms/in-fp/mediary/set
  make-atomic-set-element-sys-impl-from-contract
  prop:atomic-set-element-sys)

(require #/only-in punctaffy/hypersnippet/dim
  make-dim-sys-impl-from-max-of-two prop:dim-sys)

(provide
  omega)
(provide #/contract-out
  [omega? (-> any/c boolean?)])
(provide
  extended-nat-dim-sys)
(provide #/contract-out
  [extended-nat-dim-sys? (-> any/c boolean?)])


(define-imitation-simple-struct (omega?) omega
  'omega (current-inspector) (auto-write) (auto-equal))

(define-imitation-simple-struct (extended-nat-dim-sys?)
  extended-nat-dim-sys
  'extended-nat-dim-sys (current-inspector) (auto-write) (auto-equal)
  (#:prop prop:atomic-set-element-sys
    (make-atomic-set-element-sys-impl-from-contract
      ; atomic-set-element-sys-accepts/c
      (fn es extended-nat-dim-sys?)))
  (#:prop prop:dim-sys #/make-dim-sys-impl-from-max-of-two
    ; dim-sys-dim/c
    (fn ds #/or/c natural? omega?)
    ; dim-sys-dim=?
    (fn ds a b #/equal? a b)
    ; dim-sys-dim-zero
    (fn ds 0)
    ; dim-sys-dim-max-of-two
    (fn ds a b
      (mat a (omega) (omega)
      #/mat b (omega) (omega)
      #/max a b))))

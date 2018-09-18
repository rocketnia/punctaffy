#lang parendown racket/base

; hyprid.rkt
;
; A data structure which encodes higher-dimensional
; hypersnippet-shaped data using "stripes" of low-dimensional
; hypertees.

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


(require #/only-in racket/contract/base -> any any/c)
(require #/only-in racket/contract/region define/contract)
(require #/only-in racket/math natural?)

(require #/only-in lathe-comforts
  dissect dissectfn expect fn mat w- w-loop)
(require #/only-in lathe-comforts/list list-each list-map nat->maybe)
(require #/only-in lathe-comforts/maybe just nothing)
(require #/only-in lathe-comforts/struct struct-easy)
(require #/only-in lathe-comforts/trivial trivial)
(require #/only-in lathe-ordinals/olist olist-build)

(require #/only-in punctaffy/hypersnippet/hyperstack
  make-poppable-hyperstack make-poppable-hyperstack-n
  poppable-hyperstack-dimension poppable-hyperstack-pop
  poppable-hyperstack-pop-n)
(require #/only-in punctaffy/hypersnippet/hypertee
  hypertee? hypertee-bind-pred-degree hypertee-contour hypertee-degree
  hypertee-each-all-degrees hypertee-map-highest-degree
  hypertee-promote hypertee-pure)
(require #/only-in
  (submod punctaffy/hypersnippet/hypertee private/unsafe)
  hypertee hypertee-closing-bracket-degree)

(provide
  ; TODO: See if there's anything more abstract we can export in place
  ; of these structure types.
  (struct-out hyprid)
  (struct-out island-cane)
  (struct-out lake-cane)
  (struct-out non-lake-cane)
  hyprid-destripe-once hyprid-fully-destripe
  hyprid-stripe-once)


; ===== Hyprids ======================================================

; A hyprid is a hypertee that *also* contains hypersnippet data.
;
; TODO: Come up with a better name than "hyprid."
;
(struct-easy
  (hyprid unstriped-degrees striped-degrees striped-hypertee)
  #:equal
  (#:guard-easy
    (unless (exact-positive-integer? unstriped-degrees)
      (error "Expected unstriped-degrees to be an exact positive integer"))
    (unless (natural? striped-degrees)
      (error "Expected striped-degrees to be a natural number"))
    (expect (nat->maybe striped-degrees) (just pred-striped-degrees)
      (expect striped-hypertee (hypertee degree closing-brackets)
        (error "Expected striped-hypertee to be a hypertee since striped-degrees was zero")
      #/unless (= unstriped-degrees degree)
        (error "Expected striped-hypertee to be a hypertee of degree unstriped-degrees"))
      (expect striped-hypertee
        (island-cane data
        #/hyprid
          unstriped-degrees-2 striped-degrees-2 striped-hypertee-2)
        (error "Expected striped-hypertee to be an island-cane since striped-degrees was nonzero")
      #/expect (= unstriped-degrees unstriped-degrees-2) #t
        (error "Expected striped-hypertee to be an island-cane of the same unstriped-degrees")
      #/unless (= pred-striped-degrees striped-degrees-2)
        (error "Expected striped-hypertee to be an island-cane of striped-degrees one less")))))

(define/contract (hyprid-degree h)
  (-> hyprid? natural?)
  (dissect h
    (hyprid unstriped-degrees striped-degrees striped-hypertee)
  #/+ unstriped-degrees striped-degrees))

(struct-easy (island-cane data rest)
  #:equal
  (#:guard-easy
    (unless (hyprid? rest)
      (error "Expected rest to be a hyprid"))
    (w- d (hyprid-degree rest)
    #/hyprid-each-lake-all-degrees rest #/fn hole-hypertee data
      (when (= d #/add1 #/hypertee-degree hole-hypertee)
        (mat data (lake-cane data rest)
          (unless (= d #/hypertee-degree rest)
            (error "Expected data to be of the same degree as the island-cane if it was a lake-cane"))
        #/mat data (non-lake-cane data)
          (void)
        #/error "Expected data to be a lake-cane or a non-lake-cane")))))

(struct-easy (lake-cane data rest)
  #:equal
  (#:guard-easy
    (unless (hypertee? rest)
      (error "Expected rest to be a hypertee"))
    (w- d (hypertee-degree rest)
    #/hypertee-each-all-degrees rest #/fn hole data
      (if (= d #/add1 #/hypertee-degree hole)
        (expect data (island-cane data rest)
          (error "Expected data to be an island-cane")
        #/unless (= d #/hyprid-degree rest)
          (error "Expected data to be an island-cane of the same degree")
        #/hyprid-each-lake-all-degrees rest
        #/fn hole-hypertee data
          (unless (= d #/add1 #/hypertee-degree hole-hypertee)
          
          ; A root island is allowed to contain arbitrary values in
          ; its low-degree holes, but the low-degree holes of an
          ; island beyond a lake just represent boundaries that
          ; transition back to the lake, so we require them to be
          ; `trivial` values.
          ;
          ; Note that this does not prohibit nontrivial data in holes
          ; of the highest degree an island can have (which are the
          ; same as the holes we wrap in `non-lake-cane`), since those
          ; holes don't represent transitions back to the lake.
          
          #/expect data (trivial)
            (error "Expected data to be an island-cane where the low-degree holes contained trivial values")
          #/void))
        (expect data (trivial)
          (error "Expected data to be a trivial value")
        #/void)))))

(struct-easy (non-lake-cane data) #:equal)

(define/contract (hyprid-map-lakes-highest-degree h func)
  (-> hyprid? (-> hypertee? any/c any/c) hyprid?)
  (dissect h
    (hyprid unstriped-degrees striped-degrees striped-hypertee)
  #/hyprid unstriped-degrees striped-degrees
  #/expect (nat->maybe striped-degrees) (just pred-striped-degrees)
    (hypertee-map-highest-degree striped-hypertee func)
  #/dissect striped-hypertee (island-cane data rest)
  #/island-cane data
  #/hyprid-map-lakes-highest-degree rest #/fn hole-hypertee rest
    (mat rest (lake-cane data rest)
      (lake-cane
        (func
          (hypertee-map-highest-degree rest #/fn hole rest
            (trivial))
          data)
      #/hypertee-map-highest-degree rest #/fn hole rest
        (dissect
          (hyprid-map-lakes-highest-degree
            (hyprid unstriped-degrees striped-degrees rest)
            func)
          (hyprid unstriped-degrees-2 striped-degrees-2 rest)
          rest))
    #/mat rest (non-lake-cane data) (non-lake-cane data)
    #/error "Internal error")))

(define/contract (hyprid-destripe-once h)
  (-> hyprid? hyprid?)
  (dissect h
    (hyprid unstriped-degrees striped-degrees striped-hypertee)
  #/w- succ-unstriped-degrees (add1 unstriped-degrees)
  #/expect (nat->maybe striped-degrees) (just pred-striped-degrees)
    (error "Expected h to be a hyprid with at least one degree of striping")
  #/hyprid succ-unstriped-degrees pred-striped-degrees
  #/dissect striped-hypertee
    (island-cane data
    #/hyprid unstriped-degrees-2 pred-striped-degrees-2 rest)
  #/expect (nat->maybe pred-striped-degrees)
    (just pred-pred-striped-degrees)
    (hypertee-bind-pred-degree
      (hypertee-promote succ-unstriped-degrees rest)
      unstriped-degrees
    #/fn hole rest
      (mat rest (lake-cane data rest)
        (hypertee-bind-pred-degree (hypertee-contour data rest)
          unstriped-degrees
        #/fn hole rest
          (dissect
            (hyprid-destripe-once
            #/hyprid unstriped-degrees striped-degrees rest)
            (hyprid succ-unstriped-degrees pred-striped-degrees
              destriped-rest)
            destriped-rest))
      #/mat rest (non-lake-cane data)
        (hypertee-pure succ-unstriped-degrees data hole)
      #/error "Internal error"))
  #/island-cane data
  #/w- destriped-rest (hyprid-destripe-once rest)
  #/hyprid-map-lakes-highest-degree destriped-rest
  #/fn hole-hypertee rest
    (mat rest (lake-cane data rest)
      (lake-cane data
      #/hypertee-map-highest-degree rest #/fn hole rest
        (dissect
          (hyprid-destripe-once
          #/hyprid unstriped-degrees striped-degrees rest)
          (hyprid succ-unstriped-degrees pred-striped-degrees
            destriped-rest)
          destriped-rest))
    #/mat rest (non-lake-cane data) (non-lake-cane data)
    #/error "Internal error")))

(define/contract (hyprid-fully-destripe h)
  (-> hyprid? hypertee?)
  (dissect h
    (hyprid unstriped-degrees striped-degrees striped-hypertee)
  #/mat striped-degrees 0 striped-hypertee
  #/hyprid-fully-destripe #/hyprid-destripe-once h))

(define/contract (hyprid-each-lake-all-degrees h body)
  (-> hyprid? (-> hypertee? any/c any) void?)
  (hypertee-each-all-degrees (hyprid-fully-destripe h) body))

; This is the inverse of `hyprid-destripe-once`, taking a hyprid and
; returning a hyprid with one more striped degree and one fewer
; unstriped degree. The new stripe's data values are trivial values,
; as implemented at the comment labeled "TRIVIAL VALUE NOTE".
;
; The last degree can't be striped, so the number of unstriped degrees
; in the input must be greater than one.
;
; TODO: Test this.
;
(define/contract (hyprid-stripe-once h)
  (-> hyprid? hyprid?)
  
  (define (location-needs-state? location)
    (not #/memq location #/list 'non-lake 'hole))
  (define (location-is-island? location)
    (not #/not #/memq location #/list 'root-island 'inner-island))
  ; NOTE: The only reason we have a `location` slot here at all (and
  ; the makeshift enum that goes in it) is for sanity checks.
  (struct-easy (history-info location maybe-state)
    (#:guard-easy
      (unless
        (memq location
        #/list 'root-island 'non-lake 'lake 'inner-island 'hole)
        (error "Internal error"))
      (if (location-needs-state? location)
        (expect maybe-state (just state)
          (error "Internal error")
        #/void)
        (expect maybe-state (nothing)
          (error "Internal error")
        #/void))))
  (struct-easy (unfinished-lake-cane data rest-state))
  (struct-easy (stripe-state rev-brackets hist))
  
  (dissect h
    (hyprid unstriped-degrees striped-degrees striped-hypertee)
  #/dissect (nat->maybe unstriped-degrees)
    (just pred-unstriped-degrees)
  #/expect (nat->maybe pred-unstriped-degrees)
    (just pred-pred-unstriped-degrees)
    (error "Expected h to be a hyprid with at least two unstriped degrees")
  #/w- succ-striped-degrees (add1 striped-degrees)
  #/hyprid pred-unstriped-degrees succ-striped-degrees
  #/expect striped-degrees 0
    (dissect striped-hypertee (island-cane data rest)
    #/w- striped-rest (hyprid-stripe-once rest)
    #/island-cane data
    #/hyprid-map-lakes-highest-degree striped-rest
    #/fn hole-hypertee rest
      (mat rest (lake-cane data rest)
        (lake-cane data
        #/hypertee-map-highest-degree rest #/fn hole rest
          (dissect
            (hyprid-stripe-once
            #/hyprid unstriped-degrees striped-degrees rest)
            (hyprid pred-unstriped-degrees succ-striped-degrees
              striped-rest)
            striped-rest))
      #/mat rest (non-lake-cane data) (non-lake-cane data)
      #/error "Internal error"))
  #/dissect striped-hypertee (hypertee d closing-brackets)
  #/expect (= d unstriped-degrees) #t
    (error "Internal error")
  ; We begin a mutable state to place the root island's brackets in
  ; and a mutable state for the overall history.
  #/w- stripe-starting-state
    (w- rev-brackets (list)
    #/stripe-state rev-brackets
    #/make-poppable-hyperstack-n pred-unstriped-degrees)
  #/w- root-island-state (box stripe-starting-state)
  #/w- hist
    (list (history-info 'root-island #/just root-island-state)
    #/make-poppable-hyperstack #/olist-build d #/dissectfn _
      (history-info 'hole #/nothing))
  #/begin
    (list-each closing-brackets #/fn closing-bracket
      
      ; As we encounter lakes, we build mutable states to keep their
      ; histories in, and so on for every island and lake at every
      ; depth.
      
      (dissect hist
        (list (history-info location-before maybe-state-before)
          histories-before)
      #/w- d (hypertee-closing-bracket-degree closing-bracket)
      #/expect (< d #/poppable-hyperstack-dimension histories-before)
        #t
        (error "Internal error")
      #/dissect
        (poppable-hyperstack-pop histories-before
        #/olist-build d #/dissectfn _
          (history-info location-before maybe-state-before))
        (list (history-info location-after maybe-state-after)
          histories-after)
      #/if (= d pred-unstriped-degrees)
        
        ; If we've encountered a closing bracket of the highest degree
        ; the original hypertee can support, we're definitely starting
        ; a lake.
        (expect (location-is-island? location-before) #t
          (error "Internal error")
        #/expect (eq? 'hole location-after) #t
          (error "Internal error")
        #/expect closing-bracket (list d data)
          (error "Internal error")
        #/w- rest-state (box stripe-starting-state)
        #/begin
          (set! hist
            (list (history-info 'lake #/just rest-state)
              histories-after))
        #/dissect maybe-state-before (just state)
        #/dissect (unbox state) (stripe-state rev-brackets hist)
        #/set-box! state
          (stripe-state
            (cons
              (list pred-pred-unstriped-degrees
              #/unfinished-lake-cane data rest-state)
              rev-brackets)
            (poppable-hyperstack-pop-n
              hist pred-pred-unstriped-degrees)))
      
      #/if (= d pred-pred-unstriped-degrees)
        
        ; If we've encountered a closing bracket of the highest degree
        ; that a stripe in the result can support, we may be starting
        ; an island or a non-lake.
        (mat closing-bracket (list d data)
          
          ; This bracket is closing the original hypertee, so it must
          ; be closing an island, so we're starting a non-lake.
          (expect (location-is-island? location-before) #t
            (error "Internal error")
          #/expect (eq? 'hole location-after) #t
            (error "Internal error")
          #/begin
            (set! hist
              (list (history-info 'non-lake #/nothing)
                histories-after))
          #/dissect maybe-state-before (just state)
          #/dissect (unbox state) (stripe-state rev-brackets hist)
          #/set-box! state
            (stripe-state
              (cons (list d #/non-lake-cane data) rev-brackets)
              (poppable-hyperstack-pop-n hist d)))
          
          ; This bracket is closing an even higher-degree bracket,
          ; which must have started a lake, so we're starting an
          ; island.
          (expect (eq? 'lake location-before) #t
            (error "Internal error")
          #/expect (eq? 'root-island location-after) #t
            (error "Internal error")
          #/w- new-state (box stripe-starting-state)
          #/begin
            (set! hist
              (list (history-info 'inner-island #/just new-state)
                histories-after))
          #/dissect maybe-state-before (just state)
          #/dissect (unbox state) (stripe-state rev-brackets hist)
          #/set-box! state
            (stripe-state
              (cons (list d new-state) rev-brackets)
              (poppable-hyperstack-pop-n hist d))))
      
      ; If we've encountered a closing bracket of low degree, we pass
      ; it through to whatever island or lake we're departing from
      ; (including any associated data in the bracket) and whatever
      ; island or lake we're arriving at (excluding the data, since
      ; this bracket must be closing some hole which was started there
      ; earlier). In some circumstances, we need to associate a
      ; trivial value with the bracket we record to the departure
      ; island or lake, even if this bracket is not a hole-opener as
      ; far as the original hypertee is concerned.
      #/begin
        (set! hist
          (list (history-info location-after maybe-state-after)
            histories-after))
        (expect maybe-state-before (just state) (void)
        #/dissect (unbox state) (stripe-state rev-brackets hist)
        #/w- hist (poppable-hyperstack-pop-n hist d)
        #/set-box! state
          (stripe-state
            (cons
              (mat closing-bracket (list d data) closing-bracket
              #/if (= d #/poppable-hyperstack-dimension hist)
                (list d #/trivial)
                d)
              rev-brackets)
            hist))
        (expect maybe-state-after (just state) (void)
        #/dissect (unbox state) (stripe-state rev-brackets hist)
        #/set-box! state
          (stripe-state
            (cons d rev-brackets)
            (poppable-hyperstack-pop-n hist d)))))
  ; In the end, we build the root island by accessing its state to get
  ; the brackets, arranging the brackets in the correct order, and
  ; recursively assembling lakes and islands using their states the
  ; same way.
  #/w-loop assemble-island-from-state state root-island-state
    (dissect (unbox state) (stripe-state rev-brackets hist)
    #/dissect (poppable-hyperstack-dimension hist) 0
    
    ; TRIVIAL VALUE NOTE: This is where we put a trivial value into
    ; the new layer of stripe data.
    #/island-cane (trivial)
    
    #/hyprid pred-unstriped-degrees 0
    #/hypertee pred-unstriped-degrees
    #/list-map (reverse rev-brackets) #/fn closing-bracket
      (expect closing-bracket (list d data) closing-bracket
      #/expect (= d pred-pred-unstriped-degrees) #t closing-bracket
      #/mat data (non-lake-cane data) closing-bracket
      #/mat data (unfinished-lake-cane data rest-state)
        (dissect (unbox rest-state) (stripe-state rev-brackets hist)
        #/dissect (poppable-hyperstack-dimension hist) 0
        #/list d #/lake-cane data #/hypertee pred-unstriped-degrees
        #/list-map (reverse rev-brackets) #/fn closing-bracket
          (expect closing-bracket (list d data) closing-bracket
          #/expect (= d pred-pred-unstriped-degrees) #t
            closing-bracket
          #/list d #/assemble-island-from-state data))
      #/error "Internal error"))))
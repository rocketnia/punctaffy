#lang parendown racket/base

; multi-phase.rkt
;
; Unit tests of the multi-phase higher quasiquotation macro system.

(require rackunit)

(require punctaffy/multi-phase/private/trees2)

; (We provide nothing from this module.)


(assert-valid-hypertee-brackets 0 #/list)
(assert-valid-hypertee-brackets 1 #/list (list 0 'a))
(assert-valid-hypertee-brackets 2 #/list (list 1 'a) 0 (list 0 'a))
(assert-valid-hypertee-brackets 3 #/list
  (list 2 'a)
  1 (list 1 'a) 0 0 0 (list 0 'a))
(assert-valid-hypertee-brackets 4 #/list
  (list 3 'a)
  2 (list 2 'a) 1 1 1 (list 1 'a) 0 0 0 0 0 0 0 (list 0 'a))
(assert-valid-hypertee-brackets 5 #/list
  (list 4 'a)
  3 (list 3 'a) 2 2 2 (list 2 'a) 1 1 1 1 1 1 1 (list 1 'a)
  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 (list 0 'a))


(check-equal?
  (hypertee-join-all-degrees #/hypertee 2 #/list
    (list 1 #/hypertee 2 #/list
      (list 0 #/list))
    0
    (list 1 #/hypertee 2 #/list
      (list 0 #/list))
    0
    (list 0 #/hypertee-pure 2 'a #/hypertee 0 #/list))
  (hypertee 2 #/list
    (list 0 'a))
  "Joining hypertees to cancel out simple degree-1 holes")

(check-equal?
  (hypertee-join-all-degrees #/hypertee 2 #/list
    (list 1 #/hypertee 2 #/list
      (list 1 'a)
      0
      (list 1 'a)
      0
      (list 0 #/list))
    0
    (list 1 #/hypertee 2 #/list
      (list 1 'a)
      0
      (list 1 'a)
      0
      (list 0 #/list))
    0
    (list 0 #/hypertee-pure 2 'a #/hypertee 0 #/list))
  (hypertee 2 #/list
    (list 1 'a)
    0
    (list 1 'a)
    0
    (list 1 'a)
    0
    (list 1 'a)
    0
    (list 0 'a))
  "Joining hypertees to make a hypertee with more holes than any of the parts on its own")

(check-equal?
  (hypertee-join-all-degrees #/hypertee 2 #/list
    (list 1 #/hypertee-pure 2 'a #/hypertee 1 #/list
      (list 0 #/list))
    0
    (list 1 #/hypertee 2 #/list
      (list 1 'a)
      0
      (list 0 #/list))
    0
    (list 1 #/hypertee 2 #/list
      (list 1 'a)
      0
      (list 0 #/list))
    0
    (list 0 #/hypertee-pure 2 'a #/hypertee 0 #/list))
  (hypertee 2 #/list
    (list 1 'a)
    0
    (list 1 'a)
    0
    (list 1 'a)
    0
    (list 0 'a))
  "Joining hypertees where one of the nonzero-degree holes in the root is just a hole rather than an interpolation")

(check-equal?
  (hypertee-join-all-degrees #/hypertee 3 #/list
    
    ; This is propagated to the result.
    (list 1 #/hypertee-pure 3 'a #/hypertee 1 #/list
      (list 0 #/list))
    0
    
    (list 2 #/hypertee 3 #/list
      
      ; This is propagated to the result.
      (list 2 'a)
      0
      
      ; This is matched up with one of the root's degree-1 sections
      ; and cancelled out.
      (list 1 #/list)
      0
      
      ; This is propagated to the result.
      (list 2 'a)
      0
      
      (list 0 #/list))
    
    ; This is matched up with the interpolation's corresponding
    ; degree-1 section and cancelled out.
    1
    0
    
    0
    
    ; This is propagated to the result.
    (list 1 #/hypertee-pure 3 'a #/hypertee 1 #/list
      (list 0 #/list))
    0
    
    (list 0 #/hypertee-pure 3 'a #/hypertee 0 #/list))
  (hypertee 3 #/list
    (list 1 'a)
    0
    (list 2 'a)
    0
    (list 2 'a)
    0
    (list 1 'a)
    0
    (list 0 'a))
  "Joining hypertees where one of the interpolations is degree 2 with its own degree-1 hole")


(check-equal?
  (hyprid-destripe-maybe
    (hyprid 1 1
    #/island-cane "Hello." #/hyprid 0 1 #/hypertee 1 #/list #/list 0
    #/non-lake-cane #/list))
  (list #/hyprid 0 2 #/hypertee 2 #/list
    (list 0 #/list))
  "Destriping a hyprid-encoded interpolated string with no interpolations gives a degree-2 hyprid with no nonzero-degree holes")

(check-equal?
  (hyprid-fully-destripe
    (hyprid 1 1
    #/island-cane "Hello, " #/hyprid 0 1 #/hypertee 1 #/list #/list 0
    #/lake-cane 'name #/hypertee 1 #/list #/list 0
    #/island-cane "! It's " #/hyprid 0 1 #/hypertee 1 #/list #/list 0
    #/lake-cane 'weather #/hypertee 1 #/list #/list 0
    #/island-cane " today." #/hyprid 0 1 #/hypertee 1 #/list #/list 0
    #/non-lake-cane #/list))
  (hypertee 2 #/list
    (list 1 'name)
    0
    (list 1 'weather)
    0
    (list 0 #/list))
  "Fully destriping a hyprid-encoded interpolated string with two interpolations gives a degree-2 hypertee with two degree-1 holes containing the interpolated values")

(check-equal?
  (hyprid-stripe-maybe
  #/hyprid 0 3 #/hypertee 3 #/list
    (list 2 'a)
    1
    (list 1 'a)
    0
    0
    0
    (list 0 'a))
  (list
  #/hyprid 1 2 #/island-cane (list) #/hyprid 0 2 #/hypertee 2 #/list
    (list 1 #/lake-cane 'a #/hypertee 2 #/list
      (list 1 #/island-cane (list) #/hyprid 0 2 #/hypertee 2 #/list
        (list 1 #/non-lake-cane 'a)
        0
        (list 0 #/list))
      0
      (list 0 #/list))
    0
    (list 0 'a))
  "Striping a hyprid")

(check-equal?
  
  (car #/hyprid-stripe-maybe
  #/car #/hyprid-stripe-maybe
  #/hyprid 0 3 #/hypertee 3 #/list
    (list 2 'a)
    1
    (list 1 'a)
    0
    0
    0
    (list 0 'a))
  
  ; NOTE: The only reason I was able to write this out was because I
  ; printed the result first and transcribed it.
  (hyprid 2 1
  #/island-cane (list) #/hyprid 1 1
  #/island-cane (list) #/hyprid 0 1
  #/hypertee 1 #/list #/list 0 #/lake-cane
    (lake-cane 'a #/hypertee 2 #/list
      (list 1
      #/island-cane (list) #/hyprid 1 1
      #/island-cane (list) #/hyprid 0 1
      #/hypertee 1 #/list #/list 0 #/lake-cane
        (non-lake-cane 'a)
      #/hypertee 1 #/list #/list 0
      #/island-cane (list) #/hyprid 0 1
      #/hypertee 1 #/list #/list 0 #/non-lake-cane #/list)
      0
      (list 0 #/list))
  #/hypertee 1 #/list #/list 0
  #/island-cane (list) #/hyprid 0 1
  #/hypertee 1 #/list #/list 0 #/non-lake-cane 'a)
  
  "Striping a hyprid twice")

(check-equal?
  (hyprid-stripe-maybe
  #/car #/hyprid-stripe-maybe
  #/car #/hyprid-stripe-maybe
  #/hyprid 0 3 #/hypertee 3 #/list
    (list 2 'a)
    1
    (list 1 'a)
    0
    0
    0
    (list 0 'a))
  (list)
  "Trying to stripe a hybrid more than it can be striped")
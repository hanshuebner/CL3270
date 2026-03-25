;;;; -*- Mode: Lisp; Coding: utf-8 -*-

;;;; cp310.lisp
;;;;
;;;; Special provisions for the "graphic escape" Codepage CP 310.
;;;; 
;;;; See the COPYING file in the main folder for licensing and
;;;; copyright information.

(in-package "CL3270")


;;; Certain characters are supported in the "graphic escape" CP310. These are
;;; arbitrary Unicode code points, so we will look them up via a map. For
;;; simplicity of our mapping implementation, we will not support the italic
;;; underlined A-Z characters that require combining characters.
;;;
;;; We will share this map among all of the codepages that we provide
;;; implementations for.
;;;
;;; https://public.dhe.ibm.com/software/globalization/gcoc/attachments/CP00310.pdf


(defparameter *unicode-to-cp310*
  (make-dict :initial-map
             '((#\◊ #x70) (#\⋄ #x70) (#\◆ #x70) (#\∧ #x71) (#\⋀ #x71) (#\¨ #x72)
               (#\⌻ #x73) (#\⍸ #x74) (#\⍷ #x75) (#\⊢ #x76) (#\⊣ #x77) (#\∨ #x78)
               (#\∼ #x80) (#\║ #x81) (#\═ #x82) (#\⎸ #x83) (#\⎹ #x84) (#\│ #x85)
               (#\⎥ #x85) (#\↑ #x8A) (#\↓ #x8B) (#\≤ #x8C) (#\⌈ #x8D) (#\⌊ #x8E)
               (#\→ #x8F) (#\⎕ #x90) (#\▌ #x91) (#\▐ #x92) (#\▀ #x93) (#\▄ #x94)
               (#\█ #x95) (#\⊃ #x9A) (#\⊂ #x9B) (#\⌑ #x9C) (#\¤ #x9C) (#\○ #x9D)
               (#\± #x9E) (#\← #x9F) (#\¯ #xA0) (#\‾ #xA0) (#\° #xA1) (#\─ #xA2)
               (#\∙ #xA3) (#\• #xA3) (#\ₙ #xA4) (#\∩ #xAA) (#\⋂ #xAA) (#\∪ #xAB)
               (#\⋃ #xAB) (#\⊥ #xAC) (#\≥ #xAE) (#\∘ #xAF) (#\⍺ #xB0) (#\α #xB0)
               (#\∊ #xB1) (#\∈ #xB1) (#\ε #xB1) (#\⍳ #xB2) (#\ι #xB2) (#\⍴ #xB3)
               (#\ρ #xB3) (#\⍵ #xB4) (#\ω #xB4) (#\× #xB6) (#\∖ #xB7) (#\÷ #xB8)
               (#\∇ #xBA) (#\∆ #xBB) (#\⊤ #xBC) (#\≠ #xBE) (#\∣ #xBF) (#\⁽ #xC1)
               (#\⁺ #xC2) (#\■ #xC3) (#\∎ #xC3) (#\└ #xC4) (#\┌ #xC5) (#\├ #xC6)
               (#\┴ #xC7) (#\⍲ #xCA) (#\⍱ #xCB) (#\⌷ #xCC) (#\⌽ #xCD) (#\⍂ #xCE)
               (#\⍉ #xCF) (#\⁾ #xD1) (#\⁻ #xD2) (#\┼ #xD3) (#\┘ #xD4) (#\┐ #xD5)
               (#\┤ #xD6) (#\┬ #xD7) (#\¶ #xD8) (#\⌶ #xDA) (#\ǃ #xDB) (#\⍒ #xDC)
               (#\⍋ #xDD) (#\⍞ #xDE) (#\⍝ #xDF) (#\≡ #xE0) (#\₁ #xE1) (#\₂ #xE2)
               (#\₃ #xE3) (#\⍤ #xE4) (#\⍥ #xE5) (#\⍪ #xE6) (#\€ #xE7) (#\⌿ #xEA)
               (#\⍀ #xEB) (#\∵ #xEC) (#\⊖ #xED) (#\⌹ #xEE) (#\⍕ #xEF) (#\⁰ #xF0)
               (#\¹ #xF1) (#\² #xF2) (#\³ #xF3) (#\⁴ #xF4) (#\⁵ #xF5) (#\⁶ #xF6)
               (#\⁷ #xF7) (#\⁸ #xF8) (#\⁹ #xF9) (#\⍫ #xFB) (#\⍙ #xFC) (#\⍟ #xFD)
               (#\⍎ #xFE)
               )))


(defparameter *cp310-to-unicode*
  (make-array
   256
   :element-type 'character
   :initial-contents
   '(
     #|            x0      x1      x2      x3      x4      x5      x6      x7      x8      x9      xA      xB      xC      xD      xE      xF |#
     #| 0x |# #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd
     #| 1x |# #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd
     #| 2x |# #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd
     #| 3x |# #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd
     #| 4x |# #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd
     #| 5x |# #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd
     #| 6x |# #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd
     #| 7x |# #\◊     #\∧     #\¨     #\⌻     #\⍸    #\⍷     #\⊢     #\⊣    #\∨     #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd #\ufffd
     #| 8x |# #\∼     #\║     #\═     #\⎸      #\⎹     #\⎥     #\ufffd #\ufffd #\ufffd  #\ufffd #\↑     #\↓     #\≤     #\⌈     #\⌊    #\→
     #| 9x |# #\⎕     #\▌     #\▐     #\▀     #\▄    #\█      #\ufffd #\ufffd #\ufffd #\ufffd #\⊃     #\⊂     #\⌑    #\○      #\±    #\←
     #| Ax |# #\‾     #\°     #\─     #\•     #\ₙ    #\ufffd  #\ufffd #\ufffd #\ufffd #\ufffd #\∩     #\⋃     #\⊥     #\ufffd #\≥    #\∘
     #| Bx |# #\⍺     #\∈     #\⍳     #\⍴    #\ω    #\ufffd  #\×     #\∖     #\÷     #\ufffd #\∇     #\∆     #\⊤     #\ufffd #\≠    #\∣
     #| Cx |# #\ufffd #\⁽     #\⁺     #\■    #\└    #\┌      #\├     #\┴     #\ufffd #\ufffd  #\⍲      #\⍱      #\⌷     #\⌽     #\⍂    #\⍉
     #| Dx |# #\ufffd #\⁾     #\⁻     #\┼     #\┘    #\┐     #\┤     #\┬     #\¶      #\ufffd #\⌶      #\ǃ     #\⍒     #\⍋     #\⍞    #\⍝
     #| Ex |# #\≡     #\₁     #\₂     #\₃     #\⍤    #\⍥     #\⍪      #\€     #\ufffd  #\ufffd #\⌿      #\⍀      #\∵     #\⊖     #\⌹    #\⍕
     #| Fx |# #\⁰     #\¹     #\²     #\³ #\⁴     #\⁵    #\⁶     #\⁷     #\⁸     #\⁹      #\ufffd #\⍫     #\⍙     #\⍟     #\⍎      #\ufffd
     )
   ))


;;;; Epilogue.

(declaim (type dict *unicode-to-cp310*)
         (type (vector character 256) *cp310-to-unicode*))

;;;; cp310.lisp ends here.

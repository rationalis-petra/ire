(module layout
  (import
    (core :all)
    (extra :all)
    (meta.gen :all)
    (num :all)

    (data.string :all)
    (data.list :all)
    (abs.numeric :all)
    (ui.element :all))

  (export
    DrawCommand))


(def DrawCommand Enum
  [:rect U32 U32 Colour])

;; Rendering happens in several stages:
;; 
;;  - Setup State (?)
;;  - Fit Width
;;  - Grow/Shrink Width
;;  - Wrap Text
;;  - Fit Height
;;  - Grow/shrink height
;;  - Position
;; 
;;  - Draw


;; (def layout macro proc [in-terms] seq
;;   ;; layout: (layout e1 ...) => (bind [layout (mk-list 100)] ... (use layout))
;;   ;; Therefore 
  
;;   [let! num-terms (+ in-terms.len 3)]

;;   ;; (bind *[layout (mk-list 100)]* ... (use layout))
;;   [let! bind-var list
;;     (:atom (range 0 0) (:symbol (capture layout)))
;;     (:node (range 0 0) :expr
;;       (list
;;         (:atom (:symbol (capture mk-list)))
;;         (:atom (:integral 100))))]
;;   ;; (bind [layout (mk-list 100)] ... *(use layout)*)
;;   [let! use-layout-terms list
;;     (capture use) (capture layout)]

;;   [let! bind-terms (mk-list num-terms num-terms)]

;;   ;; (bind [layout (mk-list 100)] ... (use layout))
;;   (eset 0 (:atom (range 0 0) (:symbol (capture bind))) bind-terms)
;;   (eset 1 (:node (range 0 0) :special bind-var) bind-terms)
;;   (loop [for i from 0 below in-terms.len]
;;     (eset (+ i 2) (elt i in-terms) bind-terms))

;;   (eset (- num-terms 1)
;;         (:node (range 0 0) :expr (list (:atom (range 0 0) (:symbol (capture use)))
;;                                        (:atom (range 0 0) (:symbol (capture layout)))))
;;         bind-terms)

;;   (:node (range 0 0) :expr bind-terms))



;; (ann begin-layout Proc [Layout] (List DrawCommand))
;; (def begin-layout proc [layout] (list))

(module render
  (import
    (core :all)
    (extra :all)

    (data.string :all)
    (data.list :all)
    (platform.hedron :all)

    (ui.element :all))
  (export :all))

;; DrawData 
(def DrawData Struct
  [.num-indices U32]
  [.index-buffer Buffer]
  [.vertex-buffer Buffer]
  [.pipeline Pipeline])


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

(def DrawCommand Enum
  [:rect U32 U32 Colour])

(ann render Proc [(List DrawCommand) DrawData] Unit)
(def render proc [commands data] seq
  :unit
 )

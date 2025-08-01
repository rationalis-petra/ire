;; ---------------------------------------------------
;; 
;;          Interactive Relic Editor (IRE)
;; 
;; ---------------------------------------------------

(open platform)
(open data)
(open data.list)

(def max-frame-in-flight 2)

(def SyncAcquire Struct
  [.command-buffer hedron.CommandBuffer]
  [.image-available hedron.Semaphore]
  [.in-flight hedron.Fence])

(def SyncSubmit Struct
  [.render-finished hedron.Semaphore])

(def create-sync-acquire proc [pool] struct
  [.command-buffer (hedron.create-command-buffer pool)]
  [.image-available (hedron.create-semaphore)]
  [.in-flight (hedron.create-fence)])

(def destroy-sync-acquire proc [(fdata SyncAcquire)] seq
  (hedron.destroy-semaphore fdata.image-available)
  (hedron.destroy-fence fdata.in-flight))

(def create-acquire-objects proc [pool] 
  (list (create-sync-acquire pool) (create-sync-acquire pool)))

(def destroy-sync-submit proc [(sync SyncSubmit)] seq
  (hedron.destroy-semaphore sync.render-finished))

(def create-sync-submit proc [] struct
  [.render-finished (hedron.create-semaphore)])

(def create-sync-submit-objects proc [(number-elements U64)] seq
  [let! sync-objects (mk-list number-elements number-elements)]
  (loop [for i from 0 below number-elements]
    (eset i (create-sync-submit) sync-objects))
  sync-objects)

(def load-shader proc [filename] seq
  [let! file (filesystem.open-file filename :read)
        chunk (filesystem.read-chunk file :none)
        module (hedron.create-shader-module chunk)]
   (free-list chunk)
   (filesystem.close-file file)
   module)

(def Vec2 Struct [.x F32] [.y F32])
(def Vec3 Struct [.x F32] [.y F32] [.z F32])
(def Vertex Struct
  [.pos    Vec2]
  [.colour Vec3])

(def DrawData Struct
  [.num-indices U32]
  [.index-buffer hedron.Buffer]
  [.vertex-buffer hedron.Buffer]
  [.pipeline hedron.Pipeline])

;; -------------------------------------------------------------------
;;
;;             Drawing and related utility functions
;; 
;; -------------------------------------------------------------------

(def fdesc proc [enm] match enm [:float-1 "float-1"] [:float-2 "float-2"] [:float-3 "float-3"])

(def create-graphics-pipeline proc [surface] seq
  [let! ;; shaders 
        shaders (list (load-shader "resources/shaders/vert.spv") (load-shader "resources/shaders/frag.spv"))

        vertex-binding-descriptions (list
          (struct hedron.BindingDescription
            [.binding 0]
            [.stride narrow (size-of Vertex) U32]
            [.input-rate :vertex]))

        vertex-attribute-descriptions (list
          (struct hedron.AttributeDescription
            [.binding 0]
            [.location 0]
            [.format :float-2]
            [.offset narrow (offset-of pos Vertex) U32])
          (struct hedron.AttributeDescription
            [.binding 0]
            [.location 1]
            [.format :float-3]
            [.offset narrow (offset-of colour Vertex) U32]))]

  [let! pipeline
    (hedron.create-pipeline
      vertex-binding-descriptions
      vertex-attribute-descriptions
      shaders
      surface)]

  (each hedron.destroy-shader-module shaders)
  (free vertex-binding-descriptions.data)
  (free vertex-attribute-descriptions.data)
  (free shaders.data)
  pipeline)

(def record-command proc [command-buffer (dd DrawData) surface next-image] seq
  (hedron.command-begin command-buffer)
  (hedron.command-begin-renderpass command-buffer surface next-image)
  (hedron.command-bind-pipeline command-buffer dd.pipeline)
  (hedron.command-set-surface command-buffer surface)
  (hedron.command-bind-vertex-buffer command-buffer dd.vertex-buffer)
  (hedron.command-bind-index-buffer command-buffer dd.index-buffer :u16)
  (hedron.command-draw-indexed command-buffer dd.num-indices 1 0 0 0)
  (hedron.command-end-renderpass command-buffer)
  (hedron.command-end command-buffer))

(def draw-frame proc [(acquire SyncAcquire) (submit (List SyncSubmit))
                      (draw-data DrawData) surface
                      (resize (Maybe (Pair U32 U32)))] seq
  (hedron.wait-for-fence acquire.in-flight)

  (match resize
    [[:some extent] seq
      (hedron.resize-window-surface surface extent)]
    [:none seq
      [let! imres (hedron.acquire-next-image surface acquire.image-available)]

      (match imres
        [[:image next-image] seq
          [let! syn (elt (widen next-image U64) submit)] ;; bug here??
          
          (hedron.reset-fence acquire.in-flight)
          (hedron.reset-command-buffer acquire.command-buffer)
            
          ;; The actual drawing
          (record-command acquire.command-buffer draw-data surface next-image)
            
          (hedron.queue-submit acquire.command-buffer acquire.in-flight acquire.image-available syn.render-finished)
          (hedron.queue-present surface syn.render-finished next-image)]
        [:resized :unit])]))


(def new-winsize proc [(messages (List window.Message))] seq
  (if (u64.= 0 messages.len)
      (Maybe (Pair U32 U32)):none
      (match (elt (u64.- messages.len 1) messages)
        [[:resize x y]
            (Maybe (Pair U32 U32)):some (struct (Pair U32 U32) [._1 x] [._2 y])])))

(def main proc [] seq
  [let! ;; windowing !
        win (window.create-window "My Window" 1080 720)
        surface (hedron.create-window-surface win)

        pipeline (create-graphics-pipeline surface)
        command-pool (hedron.create-command-pool)
        acquire-objects (create-acquire-objects command-pool) 
        num-images (widen (hedron.num-swapchain-images surface) U64)
        submit-objects (create-sync-submit-objects num-images)

        vertices (list
          (struct Vertex [.pos (struct Vec2 [.x -0.5]  [.y -0.5])]
                         [.colour (struct Vec3 [.x 1.0] [.y 0.0] [.z 0.0])])
          (struct Vertex [.pos (struct Vec2 [.x 0.5]  [.y -0.5])]
                         [.colour (struct Vec3 [.x 0.0] [.y 1.0] [.z 0.0])])
          (struct Vertex [.pos (struct Vec2 [.x 0.5] [.y 0.5])]
                         [.colour (struct Vec3 [.x 0.0] [.y 0.0] [.z 1.0])])
          (struct Vertex [.pos (struct Vec2 [.x -0.5] [.y 0.5])]
                         [.colour (struct Vec3 [.x 0.0] [.y 0.0] [.z 1.0])]))

        indices (is (list 0 1 2 2 3 0) (List U16))
   
        vertex-buffer (hedron.create-buffer :vertex (* (size-of Vertex) vertices.len))
        index-buffer (hedron.create-buffer :index (* (size-of U16) indices.len))

        draw-data (struct DrawData
                     [.num-indices (narrow indices.len U32)]
                     [.index-buffer index-buffer]
                     [.vertex-buffer vertex-buffer]
                     [.pipeline pipeline])]

  (hedron.set-buffer-data vertex-buffer vertices.data)
  (free vertices.data)

  (hedron.set-buffer-data index-buffer indices.data)
  (free indices.data)

  (loop [while (bool.not (window.should-close win))]
        [for fence-frame = 0 then (u64.mod (u64.+ fence-frame 1) 2)]

    (seq 
      [let! events (window.poll-events win)
            winsize (new-winsize events)]

      (draw-frame (elt fence-frame acquire-objects) submit-objects draw-data surface winsize)
      (free-list events)))

  (hedron.wait-for-device)

  (each destroy-sync-acquire acquire-objects)
  (free acquire-objects.data)
  (each destroy-sync-submit submit-objects)
  (free submit-objects.data)
  (hedron.destroy-buffer vertex-buffer)
  (hedron.destroy-buffer index-buffer)
  (hedron.destroy-command-pool command-pool)
  (hedron.destroy-pipeline pipeline)
  (hedron.destroy-window-surface surface)
  (window.destroy-window win))

(main)

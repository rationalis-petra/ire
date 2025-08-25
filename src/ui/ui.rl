(module ui
  (import
    meta
    (core :all)
    (extra :all)
    (data.string :all))

  (export :all))

(meta.refl.load-module "src/ui/element.rl" (:some (use meta.refl.current-module)))
(meta.refl.load-module "src/ui/layout.rl" (:some (use meta.refl.current-module)))
(meta.refl.load-module "src/ui/render.rl" (:some (use meta.refl.current-module)))

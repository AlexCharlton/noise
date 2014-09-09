;;;; 3d-cell.scm

;;;; NOTE:
;;;; This uses glls-render, so if this file is compiled it must be linked with OpenGL
;;;; E.g.:
;;;; csc -lGL 3d-cell.scm

(import chicken scheme)
(use glls-render (prefix glfw3 glfw:) (prefix opengl-glew gl:) gl-math gl-utils
     noise)

;;; VAO data
(define cube (make-mesh vertices: '(attributes: ((position #:float 3))
                                    initial-elements: ((position . (0 0 0
                                                                    1 0 0
                                                                    1 1 0
                                                                    0 1 0
                                                                    0 0 1
                                                                    1 0 1
                                                                    1 1 1
                                                                    0 1 1))))
                        indices: '(type: #:ushort
                                   initial-elements: (0 1 2
                                                      2 3 0
                                                      7 6 5
                                                      5 4 7
                                                      0 4 5
                                                      5 1 0
                                                      1 5 6
                                                      6 2 1
                                                      2 6 7
                                                      7 3 2
                                                      3 7 4
                                                      3 4 0))))
;;; Matrices
(define projection-matrix
  (perspective 480 480 0.1 100 70))

(define view-matrix
  (look-at (make-point 1.5 2 2)
           (make-point 0.5 0.5 0.5)
           (make-point 0 1 0)))

(define model-matrix (mat4-identity))

(define mvp (m* projection-matrix
                (m* view-matrix model-matrix)
                #t ; Matrix should be in a non-GC'd area
                ))

(define-pipeline simple-shader
  ((#:vertex input: ((position #:vec3))
             uniform: ((mvp #:mat4))
             output: ((pos #:vec3))) 
   (define (main) #:void
     (set! gl:position (* mvp (vec4 position 1.0)))
     (set! pos position)))
  ((#:fragment input: ((pos #:vec3))
               output: ((frag-color #:vec4))
               use: (cell-noise-3d))
   (define (main) #:void
     (set! jitter 0.7)
     (let ((n #:float (- 1 (* (cell-noise (* pos 16))
                              1))))
       (set! frag-color (vec4 n n n 1.0))))))

(glfw:key-callback
 (lambda (window key scancode action mods)
   (if (eq? key glfw:+key-escape+)
    (glfw:set-window-should-close window 1))))

;;; Initialization and main loop
(glfw:with-window (480 480 "Example" resizable: #f)
  (gl:init)
  (gl:enable gl:+depth-test+)
  (gl:depth-func gl:+less+)
  (compile-pipelines)
  (mesh-attribute-locations-set! cube (pipeline-mesh-attributes simple-shader))
  (mesh-make-vao cube)
  (let* ((renderable (make-simple-shader-renderable mesh: cube
                                                    mvp: mvp)))
    (let loop ()
      (glfw:swap-buffers (glfw:window))
      (gl:clear (bitwise-ior gl:+color-buffer-bit+ gl:+depth-buffer-bit+))
      (render-simple-shader renderable)
      (check-error)
      (glfw:poll-events)
      (unless (glfw:window-should-close (glfw:window))
        (loop)))))

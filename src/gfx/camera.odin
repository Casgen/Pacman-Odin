package gfx

import "core:math/linalg"

Camera :: struct {
    view:       linalg.Matrix4x4f32,
    projection: linalg.Matrix4x4f32,
    position:   linalg.Vector3f32,
    up_vec:     linalg.Vector3f32,
    fwd_vec:    linalg.Vector3f32,
    side_vec:   linalg.Vector3f32
}

@export
create_camera :: proc() -> Camera {
    camera: Camera

    camera.position = {0.0, 0.0, 0.0}
    camera.projection = linalg.matrix_ortho3d_f32(-1, 1, -1, 1, 0, 1)
    camera.up_vec = {0.0, 1.0, 0.0}
    camera.fwd_vec = {0.0, 0.0, 1.0}
    camera.side_vec = linalg.cross(camera.up_vec, camera.side_vec)

    return camera
}

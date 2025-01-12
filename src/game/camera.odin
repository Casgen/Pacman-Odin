package game

import "core:math/linalg"
import "../gfx"

ZOOM_INCREMENT : f32 : 0.1

CameraMovementDirection :: enum {Up, Down, Left, Right}

Camera :: struct {
    proj: linalg.Matrix4f32,
    view:       linalg.Matrix4f32,
    position:   linalg.Vector3f32,
    up_vec:     linalg.Vector3f32,
    fwd_vec:    linalg.Vector3f32,
    side_vec:   linalg.Vector3f32,

	current_dir: bit_set[CameraMovementDirection],
	speed: f32,
	aspect_ratio: f32,
	ubo: gfx.UBO
}

camera_create :: proc(game_memory: ^GameMemory, width, height: i32) -> ^Camera {
	camera, ok := arena_push_struct(&game_memory.transient_storage, Camera)
	assert(ok)

	aspect_ratio := f32(width) / f32(height)

    camera.position = {0.0, 0.0, 0.0}
	camera.aspect_ratio = aspect_ratio
    camera.proj = linalg.matrix_ortho3d_f32(-1, 1 , -1, 1, 0, 1)
    camera.up_vec = {0.0, -1.0, 0.0}
    camera.fwd_vec = {0.0, 0.0, 1.0}
    camera.side_vec = linalg.cross(camera.up_vec, camera.side_vec)
	camera.view = linalg.matrix4_look_at_f32(camera.position, camera.fwd_vec, camera.up_vec)

	// Initialize a Uniform Buffer Object

	camera.ubo = gfx.ubo_create(128)

	gfx.ubo_add_uniform(&camera.ubo, "proj", linalg.Matrix4f32)
	gfx.ubo_add_uniform(&camera.ubo, "view", linalg.Matrix4f32)

	gfx.ubo_set_uniform_by_ptr(&camera.ubo, "proj", &camera.proj)
	gfx.ubo_set_uniform_by_ptr(&camera.ubo, "view", &camera.view)

    return camera
}

camera_update_resolution :: proc(cam: ^Camera, width: i32, height: i32) {
	cam.aspect_ratio = f32(width) / f32(height)
}

@private
camera_update_props :: proc(cam: ^Camera) {
    cam.proj = linalg.matrix_ortho3d_f32(-1, 1, -1, 1, 0, 1)
	cam.view = linalg.matrix4_look_at_f32(cam.position, cam.fwd_vec, cam.up_vec)
}

camera_zoom_in :: proc(cam: ^Camera) {
	cam.position.z += ZOOM_INCREMENT
	camera_update_props(cam)
}

camera_zoom_out :: proc(cam: ^Camera) {
	cam.position.z -= ZOOM_INCREMENT
	camera_update_props(cam)
}

camera_add_mov_direction :: proc(cam: ^Camera, direction: CameraMovementDirection) {
	cam.current_dir = cam.current_dir + {direction}
}

camera_update :: proc(cam: ^Camera) {
	
	if (card(cam.current_dir) == 0) {
		return;
	}

	direction := linalg.Vector3f32{0.0, 0.0, 0.0};

	direction += f32(int(CameraMovementDirection.Up in cam.current_dir)) * cam.speed * linalg.Vector3f32{0.0, 1.0, 0.0}
	direction += f32(int(CameraMovementDirection.Down in cam.current_dir)) * cam.speed * linalg.Vector3f32{0.0, -1.0, 0.0}

	direction += f32(int(CameraMovementDirection.Left in cam.current_dir)) * cam.speed * linalg.Vector3f32{1.0, 0.0, 0.0}
	direction += f32(int(CameraMovementDirection.Right in cam.current_dir)) * cam.speed * linalg.Vector3f32{-1.0, 0.0, 0.0}

	cam.position += direction

	camera_update_props(cam)
}









	

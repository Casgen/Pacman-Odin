package entities

import "core:fmt"
import "core:math/linalg"
import SDL "vendor:sdl2"


Pacman :: struct {
	position:     linalg.Vector2f32,
	velocity:     linalg.Vector2f32,
	direction:    Direction,
	speed:        f32,
	current_node: ^Node,
}

update_control :: proc(pacman: ^Pacman) {
	numkeys: i32 = 0
	kb_array: [^]u8 = SDL.GetKeyboardState(&numkeys)

    // Retrieves a bit field for the Direction keypad 0b0000 -> RIGHT, LEFT, UP, DOWN
    kb_slice: []u8 = kb_array[SDL.SCANCODE_RIGHT:][:4]

    switch {
        case bool(kb_slice[0]): pacman.velocity = linalg.Vector2f32{1.0, 0.0}   // Right
        case bool(kb_slice[1]): pacman.velocity = linalg.Vector2f32{-1.0, 0.0}  // Left
        case bool(kb_slice[2]): pacman.velocity = linalg.Vector2f32{0.0, -1.0}  // Up
        case bool(kb_slice[3]): pacman.velocity = linalg.Vector2f32{0.0, 1.0}   // Down
    }
    
    fmt.println(kb_slice)
}


update_pos :: proc(pacman: ^Pacman, dt: f32) {
	pacman.position += dt * pacman.velocity * pacman.speed
}

init_pacman :: proc(pos_x, pos_y: f32) -> Pacman {
	pacman: Pacman

	pacman.position = {pos_x, pos_y}
	pacman.direction = nil
	pacman.speed = 0.1
	pacman.current_node = nil
	pacman.velocity = {0, 0}

	return pacman
}

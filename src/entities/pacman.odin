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
	next_node:    ^Node,
}

update_control :: proc(pacman: ^Pacman) {

	assert(pacman.current_node != nil)

	numkeys: i32 = 0
	kb_array: [^]u8 = SDL.GetKeyboardState(&numkeys)

    if linalg.vector_length2(pacman.velocity) > 0  { return }

	// Retrieves a bools for the Direction keypad 0b0000 -> RIGHT, LEFT, DOWN, UP
	kb_slice: []u8 = kb_array[SDL.SCANCODE_RIGHT:][:4]


	switch {
	case bool(kb_slice[0]):
		pacman.velocity = linalg.Vector2f32{1.0, 0.0} // Right
		pacman.next_node = pacman.current_node.neighbors[Direction.Right]
	case bool(kb_slice[1]):
		pacman.velocity = linalg.Vector2f32{-1.0, 0.0} // Left
		pacman.next_node = pacman.current_node.neighbors[Direction.Left]
	case bool(kb_slice[2]):
		pacman.velocity = linalg.Vector2f32{0.0, 1.0} // Down
		pacman.next_node = pacman.current_node.neighbors[Direction.Down]
	case bool(kb_slice[3]):
		pacman.velocity = linalg.Vector2f32{0.0, -1.0} // Up
		pacman.next_node = pacman.current_node.neighbors[Direction.Up]
	}

	fmt.println(kb_slice)
}


update_pos :: proc(pacman: ^Pacman, dt: f32) {

	if pacman.next_node != nil {

		pacman.position += dt * pacman.velocity * pacman.speed

		distance := linalg.vector_length2(linalg.abs(pacman.position - pacman.next_node.position))

		if distance < 1.0 {
			pacman.current_node = pacman.next_node
			pacman.next_node = nil
		}
        return 
	}

    pacman.velocity = {0, 0}

}

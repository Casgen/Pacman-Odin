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
	target_node:  ^Node,
}

velocity_map := map[Direction]linalg.Vector2f32 {
	Direction.Right = linalg.Vector2f32{1.0, 0.0},
	Direction.Left = linalg.Vector2f32{-1.0, 0.0},
	Direction.Up = linalg.Vector2f32{0.0, -1.0},
	Direction.Down = linalg.Vector2f32{0.0, 1.0},
}

update_control :: proc(pacman: ^Pacman, scancode: SDL.Scancode) {

	assert(pacman.current_node != nil)

	new_direction: Direction

	switch {
	case scancode == SDL.Scancode.RIGHT:
		if (pacman.direction == Direction.Up || pacman.direction == Direction.Down) {
			new_direction = pacman.direction
            return
		}

		new_direction = Direction.Right
	case scancode == SDL.Scancode.LEFT:
		if (pacman.direction == Direction.Up || pacman.direction == Direction.Down) {
			new_direction = pacman.direction
            return
		}

		new_direction = Direction.Left
	case scancode == SDL.Scancode.DOWN:
		if (pacman.direction == Direction.Left || pacman.direction == Direction.Right) {
			new_direction = pacman.direction
            return
		}

		new_direction = Direction.Down
	case scancode == SDL.Scancode.UP:
		if (pacman.direction == Direction.Left || pacman.direction == Direction.Right) {
			new_direction = pacman.direction
            return
		}

		new_direction = Direction.Up
	}

	new_velocity := velocity_map[new_direction]

	length := linalg.vector_length2(new_velocity + pacman.velocity)

	if linalg.equal_single(length, 0) {
		temp := pacman.current_node
		pacman.current_node = pacman.target_node
		pacman.target_node = temp
	} else {
		pacman.target_node = pacman.current_node.neighbors[new_direction]
	}

	pacman.velocity = new_velocity
	pacman.direction = new_direction


}


update_pos :: proc(pacman: ^Pacman, dt: f32) {

	if pacman.target_node != nil {

		pacman.position += dt * pacman.velocity * pacman.speed

		distance := linalg.vector_length2(
			linalg.abs(pacman.position - pacman.target_node.position),
		)

		if distance < 1.0 {
			pacman.current_node = pacman.target_node
			pacman.target_node = nil
			pacman.direction = Direction.Stop
			pacman.velocity = {0, 0}
		}
		return
	}

	pacman.velocity = {0, 0}

}

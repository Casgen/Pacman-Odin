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

	#partial switch scancode {
	case SDL.Scancode.RIGHT:
		new_direction = Direction.Right
	case SDL.Scancode.LEFT:
		new_direction = Direction.Left
	case SDL.Scancode.DOWN:
		new_direction = Direction.Down
	case SDL.Scancode.UP:
		new_direction = Direction.Up
	case:
		new_direction = Direction.None
	}

	if new_direction == Direction.None {
		return
	}


	if pacman.direction == Direction.None {
		update_target_node(pacman, new_direction)
        return
	}

	new_velocity := velocity_map[new_direction]

	if linalg.equal_single(linalg.dot(pacman.velocity, new_velocity), 0) &&
	   pacman.direction != Direction.None {
		return
	}


	length := linalg.vector_length2(new_velocity + pacman.velocity)

	if linalg.equal_single(length, 0) {
		temp := pacman.current_node
		pacman.current_node = pacman.target_node
		pacman.target_node = temp
	} else {
		update_target_node(pacman, new_direction)
        return
	}

	pacman.velocity = new_velocity
	pacman.direction = new_direction

}

update_target_node :: proc(pacman: ^Pacman, direction: Direction) {
	target_node := pacman.current_node.neighbors[direction]

	if target_node != nil {
		pacman.target_node = target_node
		pacman.velocity = velocity_map[direction]
		pacman.direction = direction
	}
}


update_pos :: proc(pacman: ^Pacman, dt: f32) {

	if pacman.target_node != nil {

		pacman.position += dt * pacman.velocity * pacman.speed

		distance := linalg.vector_length2(
			linalg.abs(pacman.position - pacman.target_node.position),
		)

		if distance < 1.0 {
			pacman.current_node = pacman.target_node
			pacman.position = pacman.target_node.position
			pacman.target_node = nil
			pacman.direction = Direction.None
			pacman.velocity = {0, 0}
		}
		return
	}

	pacman.velocity = {0, 0}
}

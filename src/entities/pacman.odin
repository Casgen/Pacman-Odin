package entities

import "../constants"
import "core:fmt"
import "core:math/linalg"
import SDL "vendor:sdl2"


Pacman :: struct {
	position:         linalg.Vector2f32,
	velocity:         linalg.Vector2f32,
	current_node:     ^Node,
	target_node:      ^Node,
	speed:            f32,
	collision_radius: f32,
	direction:        Direction,
	num_eaten:        u32,
}

velocity_map := map[Direction]linalg.Vector2f32 {
	Direction.Right = linalg.Vector2f32{f32(constants.TILE_WIDTH / 16), 0.0},
	Direction.Left = linalg.Vector2f32{f32(-constants.TILE_WIDTH / 16), 0.0},
	Direction.Up = linalg.Vector2f32{0.0, f32(-constants.TILE_HEIGHT / 16)},
	Direction.Down = linalg.Vector2f32{0.0, f32(constants.TILE_HEIGHT / 16)},
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

			if pacman.target_node.is_portal {
				pacman.current_node = pacman.target_node.neighbors[Direction.Portal]
				pacman.target_node = pacman.current_node.neighbors[pacman.direction]
				pacman.position = pacman.current_node.position

				return
			}

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


try_eat_pellets :: proc(pacman: ^Pacman, pellets: ^[dynamic]Pellet) -> (^Pellet, int) {
	diff: linalg.Vector2f32

	for i in 0 ..< len(pellets) {
		diff = pacman.position - pellets[i].position
		distance := (diff.x * diff.x) + (diff.y * diff.y)
		r_distance :=
			(pacman.collision_radius * pacman.collision_radius) +
			(pellets[i].radius) * (pellets[i].radius)

		if distance < r_distance {
			return &pellets[i], i
		}
	}

	return nil, -1

}

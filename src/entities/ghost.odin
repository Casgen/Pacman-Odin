package entities

import Consts "../constants"
import "core:math/linalg"
import "core:math/rand"
import SDL "vendor:sdl2"

Ghost :: struct {
	using entity: ^Entity,
	color:        [3]u8,
	goal:         linalg.Vector2f32,
}


create_ghost :: proc(starting_node: ^Node, goal: linalg.Vector2f32) -> Ghost {
	ghost: Ghost

	ghost.entity = new_entity(Ghost)
	ghost.position = starting_node.position
	ghost.current_node = starting_node
	ghost.speed = 0.1 * f32(Consts.TILE_WIDTH / 16)
	ghost.collision_radius = 5
	ghost.velocity = {0, 0}
	ghost.target_node = nil
	ghost.direction = Direction.None
	ghost.color = {0xA9, 0xE1, 0x90}
	ghost.goal = goal

	return ghost
}


update_ghost_ai :: proc(ghost: ^Ghost, dt: f32) {

	if ghost.target_node == nil {
		assert(ghost.current_node != nil)

		valid_directions := get_valid_directions(ghost.current_node)
		random_dir := Direction(rand.float32() * f32(len(valid_directions)))

		next_node := ghost.current_node.neighbors[random_dir]

		ghost.position = ghost.current_node.position
		ghost.target_node = next_node
		ghost.direction = random_dir
		ghost.velocity = velocity_map[random_dir]

		return
	}

	ghost.position += dt * ghost.velocity * ghost.speed


	if !has_overshot_target(ghost) {
		return
	}

	if ghost.target_node.is_portal {
		ghost.current_node = ghost.target_node.neighbors[Direction.Portal]
		ghost.target_node = ghost.current_node.neighbors[ghost.direction]
		ghost.position = ghost.current_node.position
		return
	}

	// Find new direction
	valid_directions := get_valid_directions(ghost.target_node)

	random_val := u32(rand.float32() * f32(len(valid_directions)))
	random_dir := valid_directions[random_val]

	next_node := ghost.target_node.neighbors[random_dir]

	if next_node == ghost.current_node && len(valid_directions) > 1 {

		// offset the index by 1 with respect to the array bounds
		random_dir = valid_directions[(random_val + 1) % u32(len(valid_directions))]
		next_node = ghost.target_node.neighbors[random_dir]
	}


	ghost.position = ghost.target_node.position
	ghost.current_node = ghost.target_node
	ghost.target_node = next_node
	ghost.direction = random_dir
	ghost.velocity = velocity_map[random_dir]

	return
}

debug_render_ghost :: proc(renderer: ^SDL.Renderer, ghost: ^Ghost) {
	rect: SDL.Rect = {i32(ghost.position.x), i32(ghost.position.y), 32, 32}

	SDL.SetRenderDrawColor(renderer, ghost.color[0], ghost.color[1], ghost.color[2], 255)
	error: i32 = SDL.RenderFillRect(renderer, &rect)
}

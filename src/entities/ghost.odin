package entities

import Consts "../constants"
import "core:math/linalg"
import "core:math/rand"
import "core:math"
import SDL "vendor:sdl2"

Ghost :: struct {
	using entity: ^Entity,
	color:        [3]u8,
	goal:         linalg.Vector2f32,
}


create_ghost :: proc(starting_node: ^Node, goal: linalg.Vector2f32) -> Ghost {

    assert(starting_node != nil)

	ghost: Ghost

	ghost.entity = new_entity(Ghost)
	ghost.position = starting_node.position
	ghost.current_node = starting_node
	ghost.speed = 0.1 * f32(Consts.TILE_WIDTH / 16)
	ghost.collision_radius = 5
	ghost.target_node = nil
	ghost.color = {0xA9, 0xE1, 0x90}
	ghost.goal = goal

    valid_directions, valid_nodes := get_valid_neighbors(ghost.current_node)

    min_distance: f32 = math.F32_MAX
    closest_node_index: int

    for node, i in valid_nodes {
        distance := linalg.vector_length2(node.position - ghost.goal)
        if distance < min_distance {
            closest_node_index = i
            min_distance = distance
        }
    }

    ghost.target_node = valid_nodes[closest_node_index]
    ghost.direction = valid_directions[closest_node_index]
    ghost.velocity = velocity_map[valid_directions[closest_node_index]]

	return ghost
}


update_ghost_ai :: proc(ghost: ^Ghost, dt: f32) {

    assert(ghost.target_node != nil)

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
	// valid_directions, _ := get_valid_neighbors(ghost.target_node)
	//
	// random_val := u32(rand.float32() * f32(len(valid_directions)))
	// random_dir := valid_directions[random_val]
	//
	// next_node := ghost.target_node.neighbors[random_dir]
	//
	// if next_node == ghost.current_node && len(valid_directions) > 1 {
	//
	// 	// offset the index by 1 with respect to the array bounds
	// 	random_dir = valid_directions[(random_val + 1) % u32(len(valid_directions))]
	// 	next_node = ghost.target_node.neighbors[random_dir]
	// }

    valid_directions, valid_nodes := get_valid_neighbors(ghost.target_node)

    min_distance: f32 = math.F32_MAX
    closest_node_index: int

    for node, i in valid_nodes {
        
        distance := linalg.vector_length2(node.position - ghost.goal)
        if distance < min_distance {
            closest_node_index = i
            min_distance = distance
        }
    }

	ghost.position = ghost.target_node.position
	ghost.current_node = ghost.target_node
	ghost.target_node = valid_nodes[closest_node_index]
	ghost.direction = valid_directions[closest_node_index]
	ghost.velocity = velocity_map[valid_directions[closest_node_index]]

	return
}

debug_render_ghost :: proc(renderer: ^SDL.Renderer, ghost: ^Ghost) {
	rect: SDL.Rect = {i32(ghost.position.x), i32(ghost.position.y), 32, 32}

	SDL.SetRenderDrawColor(renderer, ghost.color[0], ghost.color[1], ghost.color[2], 255)
	error: i32 = SDL.RenderFillRect(renderer, &rect)
}

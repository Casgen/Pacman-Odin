package entities

import Consts "../constants"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import SDL "vendor:sdl2"
import "core:fmt"
import "../gfx"
import GL "vendor:OpenGL"

GhostState :: enum {
	Scatter,
	Chase,
	Freight,
	Spawn,
}

Ghost :: struct {
	using entity:       ^Entity,
	color:              [3]u8,
	goal, scatter_goal: linalg.Vector2f32,
	state:              GhostState,
	timer:              f32, // Represented in millis
}


create_ghost :: proc(starting_node: ^Node, scatter_goal: linalg.Vector2f32) -> Ghost {

	assert(starting_node != nil)

	ghost: Ghost

	ghost.entity = new_entity(Ghost)
    ghost.scale = {Consts.TILE_WIDTH, Consts.TILE_HEIGHT}
    ghost.quad = gfx.create_quad({1.0,0.0,1.0,1.0})
	ghost.position = starting_node.position
	ghost.current_node = starting_node
	ghost.speed = 0.1 * f32(Consts.TILE_WIDTH / 16)
	ghost.collision_radius = 5
	ghost.target_node = nil
	ghost.goal = {0, 0}
	ghost.scatter_goal = scatter_goal
	ghost.state = GhostState.Scatter
    ghost.timer = 7000

	valid_directions, valid_nodes := get_valid_neighbors(ghost.current_node)

	min_distance: f32 = math.F32_MAX
	closest_node_index: int

	for node, i in valid_nodes {
		distance := linalg.vector_length2(node.position - scatter_goal)
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


update_ghost_ai :: proc(ghost: ^Ghost, goal: linalg.Vector2f32, dt: f32) {

	assert(ghost.target_node != nil)

	ghost.position += dt * ghost.velocity * ghost.speed

	if !has_overshot_target(ghost) {
		advance_timer(ghost, dt)
		return
	}

	if ghost.target_node.is_portal {
		ghost.current_node = ghost.target_node.neighbors[Direction.Portal]
		ghost.target_node = ghost.current_node.neighbors[ghost.direction]
		ghost.position = ghost.current_node.position
		advance_timer(ghost, dt)
		return
	}

	// Find new random direction
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

	#partial switch ghost.state {
	case .Scatter:
		ghost.goal = ghost.scatter_goal
	case .Chase:
		ghost.goal = goal

	}

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

	advance_timer(ghost, dt)

	return
}

advance_timer :: proc(ghost: ^Ghost, dt: f32) {
	ghost.timer -= dt

	if ghost.timer > 0 {
		return
	}

	#partial switch ghost.state {
	case .Scatter:
		set_chase_mode(ghost)
	case .Chase:
		set_scatter_mode(ghost)
	}
}

// Timers are defined in millis
set_chase_mode :: proc(ghost: ^Ghost, timer: f32 = 20000) {
	ghost.state = GhostState.Chase
	ghost.timer = timer
    fmt.println(ghost.state)
}

set_scatter_mode :: proc(ghost: ^Ghost, timer: f32 = 7000) {
	ghost.state = GhostState.Scatter
	ghost.timer = timer
    fmt.println(ghost.state)
}

debug_render_ghost :: proc(renderer: ^SDL.Renderer, ghost: ^Ghost) {
	rect: SDL.Rect = {i32(ghost.position.x), i32(ghost.position.y), 32, 32}

	SDL.SetRenderDrawColor(renderer, ghost.color[0], ghost.color[1], ghost.color[2], 255)
	error: i32 = SDL.RenderFillRect(renderer, &rect)
}

ogl_debug_render_ghost :: proc(using ghost: ^Ghost, program: ^gfx.Program) {
    GL.UseProgram(program.id)
    GL.BindVertexArray(entity.quad.vao_id)
    GL.BindBuffer(GL.ELEMENT_ARRAY_BUFFER, entity.quad.ebo_id)

    gfx.set_uniform_2f(program, "u_Scale", entity.scale)
    gfx.set_uniform_2f(program, "u_Position", entity.position)
    gfx.set_uniform_1f(program, "u_Layer", entity.layer)

    GL.DrawElements(GL.TRIANGLE_STRIP, 4, GL.UNSIGNED_INT, nil)

}

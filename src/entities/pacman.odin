package entities

import "../constants"
import "core:fmt"
import "core:math/linalg"
import SDL "vendor:sdl2"
import Consts "../constants"
import "../gfx"
import GL "vendor:OpenGL"


Pacman :: struct {
    using entity: ^Entity,
	num_eaten:        u32,
}


// TODO: Take a look back at this at some point. The velocities don't have to correspond
// accordingly to the window size
velocity_map := map[Direction]linalg.Vector2f32 {
	Direction.Right = linalg.Vector2f32{1.0, 0.0},
	Direction.Left = linalg.Vector2f32{-1.0, 0.0},
	Direction.Up = linalg.Vector2f32{0.0, 1.0},
	Direction.Down = linalg.Vector2f32{0.0, -1.0},
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

    // This ensures that the player doesn't steer off from the path
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


update_pacman_pos :: proc(pacman: ^Pacman, dt: f32) {

	if pacman.target_node == nil {
	    pacman.velocity = {0, 0}
        return
	}

    pacman.position += dt * pacman.velocity * pacman.speed

    if !has_overshot_target(pacman) {
        return
    }

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

    return

}


try_eat_pellets :: proc(pacman: ^Pacman, pellets: ^[dynamic]Pellet, remove_from_array: bool = false) -> (^Pellet, int) {

	diff: linalg.Vector2f32

	for i in 0 ..< len(pellets) {
        distance := linalg.vector_length2(pacman.position - pellets[i].position)
		r_distance :=
			(pacman.collision_radius * pacman.collision_radius) +
			(pellets[i].radius) * (pellets[i].radius)

		if distance < r_distance {
            defer if remove_from_array {
                ordered_remove(pellets, i)
            }

			return &pellets[i], i
		}
	}

	return nil, -1

}

debug_render_player :: proc(renderer: ^SDL.Renderer, pacman: ^Pacman) {
	player_rect: SDL.Rect = {i32(pacman.position.x), i32(pacman.position.y), 32, 32}

	SDL.SetRenderDrawColor(renderer, 255, 0, 0, 255)
	error: i32 = SDL.RenderFillRect(renderer, &player_rect)
}

ogl_debug_render_player :: proc(using pacman: ^Pacman, program: ^gfx.Program) {

    GL.UseProgram(program.id)
    GL.BindVertexArray(entity.quad.vao_id)
    GL.BindBuffer(GL.ELEMENT_ARRAY_BUFFER, entity.quad.ebo_id)

    // scale_loc := GL.GetUniformLocation(program_id, "u_Scale")
    // GL.Uniform2f(scale_loc, entity.scale.x, entity.scale.y)

    gfx.set_uniform_2f(program, "u_Scale", pacman.entity.scale)

    // pos_loc := GL.GetUniformLocation(program_id, "u_Position")
    // GL.Uniform2f(pos_loc, entity.position.x, entity.position.y)

    gfx.set_uniform_2f(program, "u_Position", pacman.entity.position)

    // layer_loc := GL.GetUniformLocation(program_id, "u_Layer")
    // GL.Uniform1f(layer_loc, entity.layer)

    gfx.set_uniform_1f(program, "u_Layer", pacman.entity.layer)

    GL.DrawElements(GL.TRIANGLE_STRIP, 4, GL.UNSIGNED_INT, nil)

}

create_pacman :: proc(starting_node: ^Node) -> Pacman {

	pacman: Pacman

    pacman.entity = new_entity(Pacman)
	pacman.position = starting_node.position
    pacman.layer = 0.0
    pacman.scale = {Consts.TILE_WIDTH, Consts.TILE_HEIGHT}
    pacman.quad = gfx.create_quad({1.0,1.0,0.0,1.0})
	pacman.current_node = starting_node
	pacman.speed = 0.1 * f32(Consts.TILE_WIDTH / 16.0)
    pacman.collision_radius = 5
	pacman.velocity = {0, 0}
	pacman.target_node = nil
	pacman.direction = Direction.None

    return pacman
}

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
VelocityMap :: [Direction]linalg.Vector2f32 {
	Direction.Right = linalg.Vector2f32{1.0, 0.0},
	Direction.Left = linalg.Vector2f32{-1.0, 0.0},
	Direction.Up = linalg.Vector2f32{0.0, 1.0},
	Direction.Down = linalg.Vector2f32{0.0, -1.0},
    Direction.None = linalg.Vector2f32{0.0, 0.0},
    Direction.Portal = linalg.Vector2f32{0.0, 0.0},
}

velocity_map := VelocityMap

update_direction :: proc(pacman: ^Pacman, scancode: SDL.Scancode) {

	assert(pacman.current_node != nil)

	#partial switch scancode {
	case SDL.Scancode.RIGHT:
		pacman.direction = Direction.Right
	case SDL.Scancode.LEFT:
		pacman.direction = Direction.Left
	case SDL.Scancode.DOWN:
		pacman.direction = Direction.Down
	case SDL.Scancode.UP:
		pacman.direction = Direction.Up
	case:
		pacman.direction = Direction.None
	}

}

update_pacman_pos :: proc(pacman: ^Pacman, dt: f32) {

    if !is_moving(pacman) && pacman.direction != .None {
        update_target_node(pacman, pacman.direction)
    }

    if pacman.target_node == nil {
        pacman.velocity = {0, 0}
        pacman.direction = .None
        return
    }

    if pacman.target_node.is_ghost {
        pacman.target_node = nil
    }

    // Check and Reverse Direction if needed
    new_velocity := velocity_map[pacman.direction]
	length := linalg.vector_length2(new_velocity + pacman.velocity)

	if linalg.equal_single(length, 0) {
		temp := pacman.current_node
		pacman.current_node = pacman.target_node
		pacman.target_node = temp
        pacman.velocity = new_velocity
	}

    pacman.position += dt * pacman.velocity * pacman.speed
    fmt.println(pacman.position)

    if has_overshot_target(pacman) {

        if pacman.target_node.is_portal {
            pacman.current_node = pacman.target_node.neighbors[Direction.Portal]
            pacman.target_node = pacman.current_node.neighbors[pacman.direction]
            pacman.position = pacman.current_node.position
            return
        }

        pacman.current_node = pacman.target_node
        pacman.position = pacman.target_node.position
        update_target_node(pacman, pacman.direction)

    }

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

    gfx.set_uniform_2f(program, "u_Scale", pacman.entity.scale)
    gfx.set_uniform_2f(program, "u_Position", pacman.entity.position)
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

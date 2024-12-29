package game

import "../constants"
import "core:fmt"
import "core:math/linalg"
import SDL "vendor:sdl2"
import Consts "../constants"
import "../gfx"
import GL "vendor:OpenGL"
import "core:mem/virtual"
import "../logger"


Pacman :: struct {
    using entity:       Entity,
	num_eaten:          u32,
    desired_direction:  Direction
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
		pacman.desired_direction = Direction.Right
	case SDL.Scancode.LEFT:
		pacman.desired_direction = Direction.Left
	case SDL.Scancode.DOWN:
		pacman.desired_direction = Direction.Down
	case SDL.Scancode.UP:
		pacman.desired_direction = Direction.Up
	}

}

pacman_update_pos :: proc(pacman: ^Pacman, dt: f32) {

    if !is_moving(pacman) && pacman.desired_direction != .None {
        update_target_node(pacman, pacman.desired_direction)
    }

    if pacman.target_node == nil {
        return
    }

    if NodeType.GhostOnly in pacman.target_node.flags {
        pacman.target_node = nil
        return
    }

    // Is Pacman trying to reverse?
    new_velocity := velocity_map[pacman.desired_direction]
	length := linalg.vector_length2(new_velocity + pacman.velocity)

	if linalg.equal_single(length, 0) {
		temp := pacman.current_node
		pacman.current_node = pacman.target_node
		pacman.target_node = temp
        pacman.direction = pacman.desired_direction
        pacman.velocity = new_velocity
	}

    pacman.position += dt * pacman.velocity * pacman.speed

    if !has_overshot_target(pacman) {
        return
    }

    // At this point pacman has reached its target node
    if NodeType.Portal in pacman.target_node.flags {
        pacman.current_node = pacman.target_node.neighbors[Direction.Portal]
        pacman.target_node = pacman.current_node.neighbors[pacman.direction]
        pacman.position = pacman.current_node.position
        return
    }

    pacman.current_node = pacman.target_node
    pacman.position = pacman.target_node.position

    // Does a next node exist while trying to steer off?
    if pacman.direction != pacman.desired_direction && pacman.target_node.neighbors[pacman.desired_direction] != nil{
        update_target_node(pacman, pacman.desired_direction)
        return
    }

    update_target_node(pacman, pacman.direction)
}


try_eat_pellets :: proc(pacman: ^Pacman, pellets: []Pellet) -> (^Pellet, int) {
	diff: linalg.Vector2f32

	for i := 0; i < len(pellets); i += 1 {
	
		pellet := &pellets[i]

        distance := linalg.vector_length2(pacman.position - pellet.position)
		r_distance :=
			(pacman.collision_radius * pacman.collision_radius) +
			(pellet.radius) * (pellet.radius)

		if distance < r_distance && pellets[i].is_visible {
			return pellet, i
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

pacman_create :: proc(game_memory: ^GameMemory) -> ^Pacman {

	pacman, ok := arena_push_struct(&game_memory.transient_storage, Pacman)
	assert(ok)

    pacman.entity = {} 
	pacman.position = {0.0, 0.0}
    pacman.layer = 0.0
    pacman.scale = {Consts.TILE_WIDTH, Consts.TILE_HEIGHT}
    pacman.quad = gfx.create_quad({1.0,1.0,0.0,1.0})
	pacman.current_node = nil
	pacman.speed = 0.1 * f32(Consts.TILE_WIDTH / 16.0)
    pacman.collision_radius = Consts.TILE_WIDTH / 2
	pacman.velocity = {0, 0}
	pacman.target_node = nil
	pacman.direction = Direction.None
	pacman.desired_direction = Direction.Left

    return pacman
}

pacman_init :: proc(pacman: ^Pacman, starting_node: ^Node) {
	pacman.current_node = starting_node
	pacman.position = starting_node.position
}

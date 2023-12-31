package entities

import LinAlg "core:math/linalg"
import SDL "vendor:sdl2"

Direction :: enum i8 {
	None   = -1,
	Up     = 0,
	Down   = 1,
	Left   = 2,
	Right  = 3,
	Portal = 4,
}


Node :: struct {
	neighbors: [5]^Node,
	position:  LinAlg.Vector2f32,
	is_portal: bool,
	is_ghost:  bool,
}

create_node :: proc(
	position_x, position_y: f32,
	is_portal: bool = false,
	is_ghost: bool = false,
	allocator := context.allocator,
) -> ^Node {
	node: ^Node = new(Node, allocator)

	node.position.x = position_x
	node.position.y = position_y
	node.is_portal = is_portal
	node.is_ghost = is_ghost
	node.neighbors = {}

	return node
}

get_valid_neighbors :: proc(node: ^Node) -> ([dynamic]Direction, [dynamic]^Node) {

	valid_directions: [dynamic]Direction
	valid_nodes: [dynamic]^Node

	for target, index in node.neighbors {

		if target != nil {
			append(&valid_directions, Direction(index))
			append(&valid_nodes, target)
		}
	}

	return valid_directions, valid_nodes
}

debug_render_node :: proc(renderer: ^SDL.Renderer, node: ^Node, color: [3]u8, render_lines: bool) {

	SDL.SetRenderDrawColor(renderer, color[0], color[1], color[2], 255)

	node_rect: SDL.Rect = {i32(node.position.x), i32(node.position.y), 16, 16}
	SDL.RenderFillRect(renderer, &node_rect)

	if !render_lines {
		return
	}

	for neighbor in node.neighbors {
		if neighbor != nil {

			if node.is_portal && neighbor.is_portal {
				continue
			}

			SDL.RenderDrawLine(
				renderer,
				i32(node.position.x),
				i32(node.position.y),
				i32(neighbor^.position.x),
				i32(neighbor^.position.y),
			)
		}
	}

	SDL.SetRenderDrawColor(renderer, 123, 211, 0, 255)

}

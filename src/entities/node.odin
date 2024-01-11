package entities

import LinAlg "core:math/linalg"
import SDL "vendor:sdl2"
import GL "vendor:OpenGL"
import gfx "../gfx"

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

create_debug_nodes_buffer :: proc(nodes: [dynamic]^Node) -> (vao_id, vbo_id: u32) {

    node_vertices: [dynamic]f32
    reserve(&node_vertices,  len(nodes) * 7)

    for &node in nodes {
        append(&node_vertices, node.position.x, node.position.y, 1.0, 0.0, 0.0, 1.0, 20)
    }

    GL.GenVertexArrays(1, &vao_id)
    GL.GenBuffers(1, &vbo_id)

    GL.BindBuffer(GL.ARRAY_BUFFER, vbo_id)
    GL.BufferData(GL.ARRAY_BUFFER, len(node_vertices)*size_of(f32), &node_vertices[0], GL.STATIC_DRAW)
    GL.BindBuffer(GL.ARRAY_BUFFER, 0)

    vertex_builder: gfx.VertexBuilder
    gfx.push_attribute(&vertex_builder, 2, gfx.GlValueType.Float)
    gfx.push_attribute(&vertex_builder, 4, gfx.GlValueType.Float)
    gfx.push_attribute(&vertex_builder, 1, gfx.GlValueType.Float)

    gfx.generate_layout(&vertex_builder, vbo_id, vao_id)

    return vao_id, vbo_id
}


package game

import "core:math/linalg"
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

NodeType :: enum u8 {
	GhostOnly,
	GhostSpawn,
	PacmanSpawn,
	Portal,
}

Node :: struct {
	flags: bit_set[NodeType],
	neighbors:	[5]^Node,
	position:	linalg.Vector2f32,
}

// From a particular node, fetches the valid neigbhors and their direction
// Don't forget to delete the results after using it!
// TODO: Maybe change this later to an array on stack. A dynamic array is too overkill.
get_valid_neighbors :: proc(node: ^Node) -> ([dynamic]Direction, [dynamic]^Node) {

	assert(node != nil)

	valid_directions: [dynamic]Direction = {}
	valid_nodes: [dynamic]^Node = {}

	for target, index in node.neighbors {

		if target != nil {
			append(&valid_directions, Direction(index))
			append(&valid_nodes, target)
		}
	}

	return valid_directions, valid_nodes
}

create_debug_nodes_buffer :: proc(nodes: []Node) -> (vao_id, vbo_id: u32) {

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

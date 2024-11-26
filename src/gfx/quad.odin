package gfx

import GL "vendor:OpenGL"
import "core:math/linalg"

Quad :: struct {
    vao_id, vbo_id, ebo_id: u32
}

create_quad_color :: proc (color: [4]f32) -> Quad {
	return create_quad_color_scale(color, {1.0, 1.0});
}

create_quad_color_scale :: proc(color: [4]f32, scale: linalg.Vector2f32) -> Quad {

    quad: Quad

    vertices := [?]f32{
        scale.x * -0.5, scale.y * -0.5, 0.0,     0.0, 1.0,   color[0], color[1], color[2], color[3],
        scale.x * -0.5, scale.y *  0.5, 0.0,     0.0, 0.0,   color[0], color[1], color[2], color[3],
        scale.x *  0.5, scale.y * -0.5, 0.0,     1.0, 1.0,   color[0], color[1], color[2], color[3],
        scale.x *  0.5, scale.y *  0.5, 0.0,     1.0, 0.0,   color[0], color[1], color[2], color[3],
    }

    GL.GenVertexArrays(1, &quad.vao_id) 

    GL.GenBuffers(1, &quad.vbo_id) 
    GL.BindBuffer(GL.ARRAY_BUFFER, quad.vbo_id)
    GL.BufferData(GL.ARRAY_BUFFER, len(vertices) * size_of(f32), &vertices, GL.STATIC_DRAW)
    GL.BindBuffer(GL.ARRAY_BUFFER, 0)

    indices := [4]u32{0,1,2,3}
    
    GL.GenBuffers(1, &quad.ebo_id) 
    GL.BindBuffer(GL.ELEMENT_ARRAY_BUFFER, quad.ebo_id)
    GL.BufferData(GL.ELEMENT_ARRAY_BUFFER, len(indices) * size_of(u32), &indices, GL.STATIC_DRAW)
    GL.BindBuffer(GL.ELEMENT_ARRAY_BUFFER, 0)

    vertex_builder: VertexBuilder

    position_attr: VertexAttribute
    position_attr.count = 3
    position_attr.value_type = GlValueType.Float
    position_attr.normalized = false

    push_attribute(&vertex_builder, position_attr)

    tex_attr: VertexAttribute
    tex_attr.count = 2
    tex_attr.value_type = GlValueType.Float
    tex_attr.normalized = false

    push_attribute(&vertex_builder, tex_attr)

    color_attr: VertexAttribute
    color_attr.count = 4
    color_attr.value_type = GlValueType.Float
    color_attr.normalized = false

    push_attribute(&vertex_builder, color_attr)

    generate_layout(&vertex_builder, quad.vbo_id, quad.vao_id)

    GL.BindBuffer(GL.ELEMENT_ARRAY_BUFFER, 0)
    GL.BindBuffer(GL.ARRAY_BUFFER, 0)
    GL.BindVertexArray(0)

    return quad
}

create_quad :: proc {
	create_quad_color_scale,
	create_quad_color,
}

destroy_quad :: proc(quad: ^Quad) {

	vao_ptr: [1]u32 = [1]u32{quad.vao_id}
	GL.DeleteVertexArrays(1, &vao_ptr[0])

	buffer_ptrs: [2]u32 = [2]u32{quad.vbo_id, quad.ebo_id}
	GL.DeleteBuffers(2, &buffer_ptrs[0])
}

draw_quad :: proc(using quad: ^Quad, program_id: u32) {
    
    GL.UseProgram(program_id)
    GL.BindVertexArray(vao_id)
    GL.BindBuffer(GL.ARRAY_BUFFER, vbo_id)
    GL.BindBuffer(GL.ELEMENT_ARRAY_BUFFER, ebo_id)

    GL.DrawElements(GL.TRIANGLE_STRIP, 4, GL.UNSIGNED_INT, nil)
}

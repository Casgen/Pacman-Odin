package game

import "../constants"
import "core:math/linalg"
import SDL "vendor:sdl2"
import GL "vendor:OpenGL"
import gfx "../gfx"


Pellet :: struct {
	position:        linalg.Vector2f32,
	flash_time:      f32,
	points:          u32,
	radius:          f32,
	timer:           f32,
	is_power_pellet: bool,
    is_visible:		 bool,
}

PELLET_SIZE :: 10.0
POWER_PELLET_SIZE :: 20.0

create_pellets_buffer :: proc(pellets: []Pellet) -> (vao_id, vbo_id: u32, ssbo: gfx.SSBO) {

    vertices: [dynamic]f32
    reserve(&vertices, len(pellets) * 7)
    visibility: [dynamic]u32

    for &pellet in pellets {
        result_size: f32 = pellet.is_power_pellet ? POWER_PELLET_SIZE : PELLET_SIZE
        append(&vertices, pellet.position.x, pellet.position.y, 1.0, 0.7, 0.0, 1.0, result_size)
        append(&visibility, 1)
    }

    GL.GenVertexArrays(1, &vao_id)
    GL.GenBuffers(1, &vbo_id)

    GL.BindBuffer(GL.ARRAY_BUFFER, vbo_id)
    GL.BufferData(GL.ARRAY_BUFFER, len(vertices)*size_of(f32), &vertices[0], GL.STATIC_DRAW)
    GL.BindBuffer(GL.ARRAY_BUFFER, 0)

    vertex_builder: gfx.VertexBuilder

    gfx.push_attribute(&vertex_builder, 2, gfx.GlValueType.Float)
    gfx.push_attribute(&vertex_builder, 4, gfx.GlValueType.Float)
    gfx.push_attribute(&vertex_builder, 1, gfx.GlValueType.Float)

    gfx.generate_layout(&vertex_builder, vbo_id, vao_id)

    return vao_id, vbo_id, gfx.create_ssbo(&visibility[0], len(visibility) * 4)
}

set_visibility :: proc(pellet: ^Pellet, array_index: int, ssbo: gfx.SSBO, is_visible: bool) {

    assert(array_index >= 0)

    pellet.is_visible = is_visible
    
    cast_visible: u32 = u32(pellet.is_visible)

    gfx.bind_buffer_base(ssbo, 0)
    GL.BufferSubData(GL.SHADER_STORAGE_BUFFER, array_index * 4, 4, &cast_visible)
    gfx.unbind_ssbo()
}

draw_pellets :: proc(count: int, ssbo: gfx.SSBO, vao_id, program_id: u32) {

    assert(count >= 0)

    gfx.bind_program(program_id)
    gfx.bind_vao(vao_id)

    gfx.draw_arrays(GL.POINTS, u32(count))
    gfx.bind_ssbo_base(ssbo, 0)

    gfx.unbind_vao()
}

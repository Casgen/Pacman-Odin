package entities

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
    is_visible:       bool,
}

pellet_size :: 10.0
power_pellet_size :: 20.0

create_pellets_buffer :: proc(pellets: [dynamic]Pellet) -> (vao_id, vbo_id: u32, ssbo: gfx.SSBO) {

    vertices: [dynamic]f32
    reserve(&vertices, len(pellets) * 7)
    visibility: [dynamic]u32

    for &pellet in pellets {
        result_size: f32 = pellet.is_power_pellet ? power_pellet_size : pellet_size
        append(&vertices, pellet.position.x, pellet.position.y, 1.0, 0.7, 0.0, 1.0, 10)
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

    return vao_id, vbo_id, gfx.create_ssbo_ptr(&visibility[0], len(visibility) * 4, 0)
}

set_visibility :: proc(pellet: ^Pellet, array_index: int, ssbo: gfx.SSBO, is_visible: bool) {

    assert(array_index >= 0)

    pellet.is_visible = is_visible
    
    cast_visible: u32 = u32(pellet.is_visible)

    GL.BindBufferBase(GL.SHADER_STORAGE_BUFFER, ssbo.binding, ssbo.id)
    GL.BufferSubData(GL.SHADER_STORAGE_BUFFER, array_index * 4, 4, &cast_visible)
    GL.BindBuffer(GL.SHADER_STORAGE_BUFFER, 0)
}

draw_pellets :: proc(count: int, ssbo: gfx.SSBO, vao_id, program_id: u32) {

    assert(count >= 0)

    GL.UseProgram(program_id)
    GL.BindVertexArray(vao_id)

    GL.DrawArrays(GL.POINTS, 0, i32(count))
    GL.BindBufferBase(GL.SHADER_STORAGE_BUFFER, ssbo.binding, ssbo.id)

    GL.BindVertexArray(0)
}

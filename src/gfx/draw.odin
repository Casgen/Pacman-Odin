package gfx

import GL "vendor:OpenGL"

@export
ogl_draw_debug_points :: proc(count: int, vao_id, program_id: u32) {

    GL.UseProgram(program_id)
    GL.BindVertexArray(vao_id)

    GL.DrawArrays(GL.POINTS, 0, i32(count))

    GL.BindVertexArray(0)
}

draw_arrays :: proc {
	draw_arrays_with_first,
	draw_arrays_only_count,
}

draw_arrays_only_count :: #force_inline proc(mode: u32, count: u32) {
    GL.DrawArrays(GL.POINTS, 0, i32(count))
}

draw_arrays_with_first :: #force_inline proc(mode: u32, first: u32, count: u32) {
    GL.DrawArrays(GL.POINTS, i32(first), i32(count))
}


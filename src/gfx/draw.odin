package gfx

import GL "vendor:OpenGL"

@export
ogl_draw_debug_points :: proc(count: int, vao_id, program_id: u32) {

    GL.UseProgram(program_id)
    GL.BindVertexArray(vao_id)

    GL.DrawArrays(GL.POINTS, 0, i32(count))

    GL.BindVertexArray(0)
}

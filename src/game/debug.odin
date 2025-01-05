package game

import "../gfx"
import GL "vendor:OpenGL"

AxisProgram :: struct {
	program: gfx.Program,
	vao: gfx.VaoId,
	vbo: gfx.Buffer,
}

create_2d_axis_program :: proc() -> AxisProgram {

	axis_program: AxisProgram = {}
	axis_program.program = gfx.create_program("res/shaders/axis")

	vertices: [20]f32 = {
		// X axis
		0.0, 0.0,	1.0, 0.0, 0.0,
		1.0, 0.0,	1.0, 0.0, 0.0,

		// Y axis
		0.0, 0.0,	0.0, 1.0, 0.0,
		0.0, 1.0,	0.0, 1.0, 0.0,
	}
	
	axis_program.vao = gfx.create_vao();
	gfx.bind_vao(axis_program.vao);

	axis_program.vbo = gfx.create_vertex_buffer(vertices[:])
	gfx.bind_buffer(&axis_program.vbo)

	vert_builder: gfx.VertexBuilder
	gfx.push_attribute(&vert_builder, 2, gfx.GlValueType.Float)
	gfx.push_attribute(&vert_builder, 3, gfx.GlValueType.Float)
	gfx.generate_layout(&vert_builder, axis_program.vbo.id, axis_program.vao)

	return axis_program
}

draw_axis :: proc(axis: ^AxisProgram) {
	gfx.bind_program(&axis.program)

	gfx.bind_vao(axis.vao)
	gfx.bind_buffer(&axis.vbo)

	gfx.draw_arrays(GL.LINES, 4)

	gfx.unbind_program()
	gfx.unbind_vao()
}
//

destroy_axis :: proc(axis: ^AxisProgram) {
	gfx.delete_buffer(&axis.vbo)
	gfx.delete_vao(axis.vao)
	gfx.destroy_program(&axis.program)
}

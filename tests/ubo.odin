package test

import "core:testing"
import "core:log"
import "../src/gfx"
import GL "vendor:OpenGL"
import "../src/game"
import lg "core:math/linalg"

/// Tests the UBO offsets and sizes
@(test)
ubo_test :: proc(t: ^testing.T) {

	// layout (std140) uniform ExampleBlock
	// {
	//     float value;		// Offset: 0
	//     vec3  vector;	// Offset: 16
	//     mat4  matrix;	// Offset: 32
	//     float values[3];	// Offset: 96
	//     bool  boolean;	// Offset: 108
	//     int   integer;	// Offset: 112
	// };

	test_offset := map[string]u32{
		"value" = 0,
		"vector" = 16,
		"values" = 96,
		"matrix" = 32,
		"boolean" = 108,
		"integer" = 112,
	}
	ubo_size: u32 = 116

	window, gl_context := game.init_sdl_with_gl()

	ubo := gfx.ubo_create(ubo_size)

	gfx.ubo_add_uniform(&ubo, "value", f32)
	gfx.ubo_add_uniform(&ubo, "vector", lg.Vector3f32)
	gfx.ubo_add_uniform(&ubo, "matrix", lg.Matrix4f64)
	
	gfx.ubo_add_uniform_array(&ubo, "values", f32, 3)
	gfx.ubo_add_uniform(&ubo, "boolean", bool)
	gfx.ubo_add_uniform(&ubo, "integer", int)
	
	gfx.ubo_set_uniform_by_val(&ubo, "value", f32(1.2))
	gfx.ubo_set_uniform_by_val(&ubo, "vector", lg.Vector3f32{1.0, 2.0, 3.0})
	gfx.ubo_set_uniform_by_val(&ubo, "matrix", lg.Matrix4f64{
		1.0,  2.0,	3.0,  4.0,
		5.0,  6.0, 	7.0,  8.0,
		9.0,  10.0, 11.0, 12.0,
		13.0, 14.0, 15.0, 16.0,
	})
	
	gfx.ubo_set_uniform_by_val(&ubo, "values", []f32{1.0, 2.0, 3.0})
	gfx.ubo_set_uniform_by_val(&ubo, "boolean", true)
	gfx.ubo_set_uniform_by_val(&ubo, "integer", 10)


	for name, var in ubo.uniform_map {

		offset, ok := test_offset[name]

		testing.expectf(t, ok, "Variable \"%d\" was not found in the test_map!!:", name)
		testing.expectf(t, offset == var.offset, "Variable \"%s\" has wrong alignment!: Expected = %d, actual = %d", name, offset, var.offset)
	}
}


package level

import GL "vendor:OpenGL"
import "../gfx"
import Log "../logger"
import "core:math/linalg"

Maze :: struct {
	tex:		gfx.Texture2D,
	program:	gfx.Program,
	quad:		gfx.Quad

}

/*
The bits are representing the neighbors of the examined cell.

|0.|1.|2.|
|7.|X |3.|
|6.|5.|4.|
*/
wall_bitmask_map := map[u8]u8{
	0b00000000 = u8(WallType.Block),

	0b00000001 = u8(WallType.Block),
	0b00000100 = u8(WallType.Block),
	0b00010000 = u8(WallType.Block),
	0b01000000 = u8(WallType.Block),

	0b10101010 = u8(WallType.FourCorner),

	0b10101010 = u8(WallType.ThreeCorner),
	0b10101110 = u8(WallType.ThreeCorner) | u8(WallOrientation.Deg90) << 4,
	0b10111010 = u8(WallType.ThreeCorner) | u8(WallOrientation.Deg180) << 4,
	0b11101010 = u8(WallType.ThreeCorner) | u8(WallOrientation.Deg270) << 4,

	0b10000011 = u8(WallType.Bulge),
	0b00001110 = u8(WallType.Bulge) | u8(WallOrientation.Deg90) << 4,
	0b00111000 = u8(WallType.Bulge) | u8(WallOrientation.Deg180) << 4,
	0b11100000 = u8(WallType.Bulge) | u8(WallOrientation.Deg270) << 4,

	0b11100011 = u8(WallType.Wall),
	0b10001111 = u8(WallType.Wall) | u8(WallOrientation.Deg90) << 4,
	0b00111110 = u8(WallType.Wall) | u8(WallOrientation.Deg180) << 4,
	0b11111000 = u8(WallType.Wall) | u8(WallOrientation.Deg270) << 4,

	0b11110011 = u8(WallType.Wall),
	0b11001111 = u8(WallType.Wall) | u8(WallOrientation.Deg90) << 4,
	0b00111111 = u8(WallType.Wall) | u8(WallOrientation.Deg180) << 4,
	0b11111100 = u8(WallType.Wall) | u8(WallOrientation.Deg270) << 4,

	0b11100111 = u8(WallType.Wall),
	0b10011111 = u8(WallType.Wall) | u8(WallOrientation.Deg90) << 4,
	0b01111110 = u8(WallType.Wall) | u8(WallOrientation.Deg180) << 4,
	0b11111001 = u8(WallType.Wall) | u8(WallOrientation.Deg270) << 4,

	0b11111010 = u8(WallType.TwoCorner),
	0b11101011 = u8(WallType.TwoCorner) | u8(WallOrientation.Deg90) << 4,
	0b00101111 = u8(WallType.TwoCorner) | u8(WallOrientation.Deg180) << 4,
	0b01011111 = u8(WallType.TwoCorner) | u8(WallOrientation.Deg270) << 4,

	0b11111011 = u8(WallType.OneCorner),
	0b11101111 = u8(WallType.OneCorner) | u8(WallOrientation.Deg90) << 4,
	0b10111111 = u8(WallType.OneCorner) | u8(WallOrientation.Deg180) << 4,
	0b11111110 = u8(WallType.OneCorner) | u8(WallOrientation.Deg270) << 4,

	0b00100010 = u8(WallType.Column),
	0b10001000 = u8(WallType.Column) | u8(WallOrientation.Deg90) << 4,

	0b00110010 = u8(WallType.Column),
	0b11001000 = u8(WallType.Column) | u8(WallOrientation.Deg90) << 4,
	0b00100011 = u8(WallType.Column),
	0b10001100 = u8(WallType.Column) | u8(WallOrientation.Deg90) << 4,

	0b01100010 = u8(WallType.Column),
	0b10001001 = u8(WallType.Column) | u8(WallOrientation.Deg90) << 4,
	0b00100110 = u8(WallType.Column),
	0b10011000 = u8(WallType.Column) | u8(WallOrientation.Deg90) << 4,

	0b10100000 = u8(WallType.LShaped),
	0b10000010 = u8(WallType.LShaped) | u8(WallOrientation.Deg90) << 4,
	0b00001010 = u8(WallType.LShaped) | u8(WallOrientation.Deg180) << 4,
	0b00101000 = u8(WallType.LShaped) | u8(WallOrientation.Deg270) << 4,

	0b00100000 = u8(WallType.Tip),
	0b10000000 = u8(WallType.Tip) | u8(WallOrientation.Deg90) << 4,
	0b00000010 = u8(WallType.Tip) | u8(WallOrientation.Deg180) << 4,
	0b00001000 = u8(WallType.Tip) | u8(WallOrientation.Deg270) << 4,

	0b10001010 = u8(WallType.TShaped),
	0b00101010 = u8(WallType.TShaped) | u8(WallOrientation.Deg90) << 4,
	0b10101000 = u8(WallType.TShaped) | u8(WallOrientation.Deg180) << 4,
	0b10100010 = u8(WallType.TShaped) | u8(WallOrientation.Deg270) << 4,

	0b10001011 = u8(WallType.RightCornerAndWall),
	0b00101110 = u8(WallType.RightCornerAndWall) | u8(WallOrientation.Deg90) << 4,
	0b10111000 = u8(WallType.RightCornerAndWall) | u8(WallOrientation.Deg180) << 4,
	0b11100010 = u8(WallType.RightCornerAndWall) | u8(WallOrientation.Deg270) << 4,

	0b10001110 = u8(WallType.LeftCornerAndWall),
	0b00111010 = u8(WallType.LeftCornerAndWall) | u8(WallOrientation.Deg90) << 4,
	0b11101000 = u8(WallType.LeftCornerAndWall) | u8(WallOrientation.Deg180) << 4,
	0b10100011 = u8(WallType.LeftCornerAndWall) | u8(WallOrientation.Deg270) << 4,
}

// Read the 'Wall types.md' file for the diagram references
WallType :: enum {
	Empty				=  0,
	FourCorner			=  1,
	ThreeCorner 		=  2,
	Bulge				=  3,
	Wall				=  4,
	TwoCorner			=  5,
	OneCorner			=  6,
	Column				=  7,
	LShaped				=  8,
	Tip					=  9,
	TShaped				= 10,
	RightCornerAndWall	= 11,
	LeftCornerAndWall	= 12,
	Block				= 13,
}

WallOrientation :: enum u8 {
	Deg0	= 0,
	Deg90	= 1,
	Deg180	= 2,
	Deg270	= 3,
}

data_at :: #force_inline proc(using lvl_data: ^LevelData, x: int, y: int) -> u8 {
	return data[x + col_count * y]
}

wall_at :: #force_inline proc(using lvl_data: ^LevelData, x: int, y: int) -> u32 {
	return wall_data[x + col_count * y]
}


// This function takes the wall cells (which are predetermined to be either 1 or 0) and parses them into
// their different types. The function takes a 3x3 kernel and according to the center cell's neighborhood
// determines the appropriate wall type and its orientation
// @param lvl_data
// @return vector of parsed wall types and their orientation. The 0.-3. least significant
// bits determine the wall type and the 4.-5. least significant bits represent the orientation.
parse_walls :: proc(lvl_data: ^LevelData) -> [dynamic]u32 {

	parsed_wall_data := make([dynamic]u32, len(lvl_data.wall_data))

	for i in 0..<len(lvl_data.wall_data) {

		x := i % lvl_data.col_count
		y := i / lvl_data.col_count
		
		s22 := wall_at(lvl_data, x, y) // Center cell

		if s22 != 1 { 
			parsed_wall_data[x + lvl_data.col_count * y] = u32(WallType.Empty)
			continue;
		}

		x_plus_one := min(x + 1, lvl_data.col_count - 1)
		x_minus_one := max(x - 1, 0);

		y_plus_one := min(y + 1, lvl_data.row_count - 1)
		y_minus_one := max(y - 1, 0);

		top_left_cell	:= wall_at(lvl_data, x_minus_one, y_minus_one)
		top_center_cell := wall_at(lvl_data, x, y_minus_one)
		top_right_cell	:= wall_at(lvl_data, x_plus_one, y_minus_one)

		right_cell := wall_at(lvl_data, x_plus_one, y)

		bottom_right_cell	:= wall_at(lvl_data, x_plus_one, y_plus_one)
		bottom_center_cell	:= wall_at(lvl_data, x, y_plus_one)
		bottom_left_cell	:= wall_at(lvl_data, x_minus_one, y_plus_one)

		left_cell := wall_at(lvl_data, x_minus_one, y)

		wall_bitmask := top_left_cell
		wall_bitmask |= top_center_cell << 1
		wall_bitmask |= top_right_cell << 2
		wall_bitmask |= right_cell << 3
		wall_bitmask |= bottom_right_cell << 4
		wall_bitmask |= bottom_center_cell << 5
		wall_bitmask |= bottom_left_cell << 6
		wall_bitmask |= left_cell << 7

		if wall_bitmask == 255 {
			parsed_wall_data[x + lvl_data.col_count * y] = u32(WallType.Empty)
			continue
		}

		result_mask, ok := wall_bitmask_map[u8(wall_bitmask)]

		if !ok {
			Log.log_errorfl("Unrecognized wall type! reverting to WallType.Empty! - result_mask value = %b", #location(result_mask), result_mask)
		}

		parsed_wall_data[x + lvl_data.col_count * y] = u32(result_mask)
	}

	return parsed_wall_data
}

create_maze :: proc(lvl_data: ^LevelData) -> Maze {
	wall_data := parse_walls(lvl_data)

	// Build a maze texture
	maze_ssbo := gfx.create_ssbo(wall_data)
	maze_builder_prog := gfx.create_program("res/shaders/build_maze/")

	maze_tex_width := gfx.SPRITESHEET_BLOCK_SIZE * i32(lvl_data.col_count)
	maze_tex_height := gfx.SPRITESHEET_BLOCK_SIZE * i32(lvl_data.row_count)

	maze_tex := gfx.create_texture_2d(maze_tex_width, maze_tex_height)

	gfx.bind_program(&maze_builder_prog)

	gfx.bind_ssbo_base(maze_ssbo, 0)
	gfx.bind_spritesheet_as_image(1)
	gfx.bind_texture_as_image(maze_tex, 2)

	gfx.set_uniform_2u_u32(
		&maze_builder_prog,
		"u_spritesheet_dims",
		u32(gfx.get_spritesheet().tex.width),
		u32(gfx.get_spritesheet().tex.height)
	)

	gfx.set_uniform_2u_u32(&maze_builder_prog, "u_spritesheet_dims",
		u32(gfx.get_spritesheet().tex.width), u32(gfx.get_spritesheet().tex.height))

	gfx.set_uniform_1u_u32(&maze_builder_prog, "u_block_size", u32(gfx.SPRITESHEET_BLOCK_SIZE))

	gfx.set_uniform_1u_u32(&maze_builder_prog, "u_row_count", u32(lvl_data.row_count))
	gfx.set_uniform_1u_u32(&maze_builder_prog, "u_col_count", u32(lvl_data.col_count))

	gfx.dispatch_compute(u32(lvl_data.col_count), u32(lvl_data.row_count), 1)
	gfx.memory_barrier(GL.SHADER_IMAGE_ACCESS_BARRIER_BIT)

	gfx.delete_ssbo(maze_ssbo)
	gfx.destroy_program(&maze_builder_prog)
	gfx.unbind_texture_2d()

	// Build a program for the maze
	maze_program := gfx.create_program("res/shaders/maze")
	maze_quad := gfx.create_quad({1.0, 1.0, 1.0, 1.0}, linalg.Vector2f32{2.0, 2.0})

	return {maze_tex, maze_program, maze_quad};
}

destroy_maze :: proc(maze: ^Maze) {
	gfx.destroy_program(&maze.program)
	gfx.destroy_texture_2d(&maze.tex)
	gfx.destroy_quad(&maze.quad)
}

draw_maze :: proc(maze: ^Maze) {
	gfx.bind_program(maze.program.id)

	gfx.bind_texture_2d(maze.tex, 0)
	gfx.set_uniform_1i(&maze.program, "u_maze_tex", i32(0))

    GL.BindVertexArray(maze.quad.vao_id)
    GL.BindBuffer(GL.ARRAY_BUFFER, maze.quad.vbo_id)
    GL.BindBuffer(GL.ELEMENT_ARRAY_BUFFER, maze.quad.ebo_id)

    GL.DrawElements(GL.TRIANGLE_STRIP, 4, GL.UNSIGNED_INT, nil)
}

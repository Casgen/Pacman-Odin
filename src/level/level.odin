package level

import Consts "../constants"
import Ent "../entities"
import "core:fmt"
import linalg "core:math/linalg"
import "core:mem"
import "core:mem/virtual"
import "core:os"
import "core:strings"
import "core:thread"
import GL "vendor:OpenGL"
import "core:math"
import "../gfx"
import "core:simd"
import Log "../logger"

NODE_BUFFER_SIZE_BYTES :: size_of(Ent.Node) * 512
PELLET_BUFFER_SIZE_BYTES :: size_of(Ent.Pellet) * 1024

Level :: struct {
	node_arena:				virtual.Arena,
	node_buffer:        	[]u8,
	wall_data:				[dynamic]u32,
	nodes:              	[dynamic]^Ent.Node,
	pellets:            	[dynamic]Ent.Pellet,
    pellets_vao_id:     	u32,
    pellets_ssbo:       	gfx.SSBO,
    node_vao_id:        	u32,
	pacman_spawn:			^Ent.Node,
	ghost_spawns:			[dynamic]^Ent.Node,
	col_count, row_count:	i32
}

LevelData :: struct {
	data:					string,
	wall_data:				[dynamic]u32,
	row_count, col_count:	int,
}

ObjectType :: enum u8 {
	Block       = 0,
	Node        = 1,
	Empty_Space = 2,
	Ghost_Gate  = 3,
}

/*
The bits are representing the neighbors of the examined cell.

|1.|2.|3.|
|8.|X |4.|
|7.|6.|5.|
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

ParseError :: enum {
	None,
	Bad_Char,
	Couldnt_Read,
	Couldnt_Split,
	Bad_Format,
	Ambiguous_Portals,
}

char_map := map[u8]ObjectType {
	'X' = ObjectType.Block,
	'+' = ObjectType.Node,
	'.' = ObjectType.Empty_Space,
	'=' = ObjectType.Ghost_Gate,
};


load_level :: proc(filename: string) -> ^Level {
	lvl_data, err := read_level(filename)
	assert(err == ParseError.None)

	lvl := parse_level(&lvl_data) 

	build_maze(lvl);

	return lvl
}

data_at :: #force_inline proc(using lvl_data: ^LevelData, x: int, y: int) -> u8 {
	return data[x + col_count * y]
}

wall_at :: #force_inline proc(using lvl_data: ^LevelData, x: int, y: int) -> u32 {
	return wall_data[x + col_count * y]
}

// Extracts the nodes and connects them horizontally
first_parse_stage :: proc(
	node_allocator: mem.Allocator,
	lvl_data: ^LevelData,
) -> (
	node_map: map[string]^Ent.Node,
	pacman_spawn: ^Ent.Node,
	ghost_spawns: [dynamic]^Ent.Node
) {

	node_map = {}
	portal_node_map: map[u8]^Ent.Node

    normalized_dims: linalg.Vector2f32 = {Consts.TILE_WIDTH * f32(lvl_data.col_count), Consts.TILE_HEIGHT * f32(lvl_data.row_count)}

	pacman_spawn = nil
	ghost_spawns = {};

	for row in 0 ..< lvl_data.row_count {

		row_nodes: [dynamic]^Ent.Node = {}

		for col in 0 ..< lvl_data.col_count {

			obj := lvl_data.data[col + lvl_data.col_count * row]
			position: linalg.Vector2f32 =  {
				f32(col) * Consts.TILE_WIDTH - normalized_dims.x/2,
			    normalized_dims.y - f32(row) * Consts.TILE_HEIGHT - normalized_dims.y/2,
			}

			switch obj {
            case 'g':
				key: string = fmt.aprintf("%d|%d", row, col)

				new_node := Ent.create_node(position.x, position.y, node_allocator)

				new_node.is_portal = false;
				new_node.is_ghost = true;

				node_map[key] = new_node
				append(&row_nodes, new_node)
            case 's':
				key: string = fmt.aprintf("%d|%d", row, col)

				new_node := Ent.create_node(position.x, position.y, node_allocator)

				new_node.is_portal = false;
				new_node.is_ghost = true;

				node_map[key] = new_node
				append(&row_nodes, new_node)
				append(&ghost_spawns, new_node)
            case 'S':
				key: string = fmt.aprintf("%d|%d", row, col)

				new_node := Ent.create_node(position.x, position.y, node_allocator)

				new_node.is_portal = false;
				new_node.is_ghost = false;

				node_map[key] = new_node
				append(&row_nodes, new_node)

				pacman_spawn = new_node
			case '+', 'P', 'n':
				key: string = fmt.aprintf("%d|%d", row, col)

				new_node := Ent.create_node(position.x, position.y, node_allocator)

				new_node.is_portal = false;
				new_node.is_ghost = false;

				node_map[key] = new_node
				append(&row_nodes, new_node)
			case 'X':
				if len(row_nodes) > 0 {
					connect_nodes(row_nodes, false)
					clear(&row_nodes)
				}
			case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9':
				key: string = fmt.aprintf("%d|%d", row, col)

				new_node := Ent.create_node(position.x, position.y, node_allocator)

				new_node.is_portal = true;
				new_node.is_ghost = false;

				node_map[key] = new_node
				append(&row_nodes, new_node)

				portal_node, ok := portal_node_map[obj]

				if ok {
					new_node.neighbors[Ent.Direction.Portal] = portal_node
					portal_node.neighbors[Ent.Direction.Portal] = new_node
					continue
				}

				portal_node_map[obj] = new_node

			}

		}

		connect_nodes(row_nodes, false)
	}

	return
}

// Connects the given nodes vertically and creates pellets
second_parse_stage :: proc(
	lvl_data: ^LevelData,
	node_map: ^map[string]^Ent.Node,
) -> [dynamic]Ent.Pellet {

	pellets: [dynamic]Ent.Pellet

    normalized_dims: linalg.Vector2f32 = {Consts.TILE_WIDTH * f32(lvl_data.col_count), Consts.TILE_HEIGHT * f32(lvl_data.row_count)}

	for col in 0 ..< lvl_data.col_count {

		col_nodes: [dynamic]^Ent.Node = {}

		for row in 0 ..< lvl_data.row_count {

			obj := lvl_data.data[col + lvl_data.col_count * row]
			position: linalg.Vector2f32 =  {
				f32(col) * Consts.TILE_WIDTH - normalized_dims.x/2,
			    normalized_dims.y - f32(row) * Consts.TILE_HEIGHT - normalized_dims.y/2,
			}
			key: string = fmt.aprintf("%d|%d", row, col)

			switch obj {
			case 'n':
				found_node := node_map[key]
				append(&col_nodes, found_node)
			case '+':
				found_node := node_map[key]
				append(&col_nodes, found_node)
				fallthrough
			case '.':
				append(&pellets, Ent.Pellet{position, 0.2, 50, Consts.PELLET_RADIUS, 0, false, true})
			case 'P':
				found_node := node_map[key]
				append(&col_nodes, found_node)
				fallthrough
			case 'p':
				append(
					&pellets,
					Ent.Pellet{position, 0.2, 50, Consts.POWER_PELLET_RADIUS, 10, true, true},
				)
			case 'X':
				if len(col_nodes) > 0 {
					connect_nodes(col_nodes, true)
					clear(&col_nodes)
				}

			}


		}

		connect_nodes(col_nodes, true)
		clear(&col_nodes)
	}

	return pellets
}

third_parse_stage :: proc(lvl_data: ^LevelData) -> [dynamic]u32 {

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


parse_level :: proc(lvl_data: ^LevelData) -> ^Level {

	level: ^Level = new(Level)

	level.node_buffer = make([]u8, size_of(Ent.Node) * 512)

	err := virtual.arena_init_buffer(&level.node_arena, level.node_buffer)

	if err != nil {
		fmt.println("Failed to initialize a node arena %v\n", err)
	}

	node_allocator := virtual.arena_allocator(&level.node_arena)

	node_map, pacman_spawn, ghost_spawns := first_parse_stage(node_allocator, lvl_data)
	pellets := second_parse_stage(lvl_data, &node_map)
	wall_type_data := third_parse_stage(lvl_data)

	reserve(&level.nodes, len(node_map))

	for _, node in node_map {
		append(&level.nodes, node)
	}

	level.pellets = pellets

	level.wall_data = wall_type_data
    level.node_vao_id, _ = Ent.create_debug_nodes_buffer(level.nodes)
    level.pellets_vao_id, _, level.pellets_ssbo = Ent.create_pellets_buffer(level.pellets)
	level.pacman_spawn = pacman_spawn
	level.ghost_spawns = ghost_spawns
	level.col_count = i32(lvl_data.col_count)
	level.row_count = i32(lvl_data.row_count)

	// fmt.printfln("Pacman Spawn: %d", level.pacman_spawn)
	// fmt.printfln("Ghost Spawns: %d", level.ghost_spawns)

	return level
}

build_maze :: proc(lvl: ^Level) {

	maze_ssbo := gfx.create_ssbo(lvl.wall_data)
	maze_builder_prog := gfx.create_program("res/shaders/maze/")

	maze_tex_width := gfx.SPRITESHEET_BLOCK_SIZE * lvl.col_count
	maze_tex_height := gfx.SPRITESHEET_BLOCK_SIZE * lvl.row_count

	maze_tex := gfx.create_texture_2d(maze_tex_width, maze_tex_height)

	gfx.bind_program(&maze_builder_prog)

	gfx.bind_ssbo_base(maze_ssbo, 0);
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

	gfx.set_uniform_1u_u32(&maze_builder_prog, "u_row_count", u32(lvl.row_count))
	gfx.set_uniform_1u_u32(&maze_builder_prog, "u_col_count", u32(lvl.col_count))

	gfx.dispatch_compute(u32(lvl.col_count), u32(lvl.row_count), 1)
	gfx.memory_barrier(GL.SHADER_IMAGE_ACCESS_BARRIER_BIT)
}

destroy_level :: proc(level: ^Level) {

	virtual.arena_destroy(&level.node_arena)
    
    delete(level.node_buffer)
	delete(level.nodes)
	delete(level.pellets)

	free(level)
}

connect_nodes :: proc(nodes: [dynamic]^Ent.Node, connect_in_col: bool) {

	if connect_in_col {
		for i in 0 ..< (len(nodes) - 1) {
			nodes[i].neighbors[Ent.Direction.Down] = nodes[i + 1]
			nodes[i + 1].neighbors[Ent.Direction.Up] = nodes[i]
		}

		return
	}

	for i in 0 ..< (len(nodes) - 1) {
		nodes[i].neighbors[Ent.Direction.Right] = nodes[i + 1]
		nodes[i + 1].neighbors[Ent.Direction.Left] = nodes[i]
	}
}

create_debug_gl_points :: proc(level: ^Level) {

    pellet_vertices: [dynamic]f32
    node_vertices: [dynamic]f32

    reserve(&pellet_vertices, len(level.pellets) * 7)
    reserve(&node_vertices,  len(level.nodes) * 7)

    for &pellet in level.pellets {
        append(&pellet_vertices, pellet.position.x, pellet.position.y, 1.0, 0.7, 0.0, 1.0, 10)
    }

    for &node in level.nodes {
        append(&node_vertices, node.position.x, node.position.y, 1.0, 0.0, 0.0, 1.0, 20)
    }

    vao_ids := [2]u32{0,0}
    GL.GenVertexArrays(2, raw_data(&vao_ids))

    vbo_ids := [2]u32{0,0}
    GL.GenBuffers(2,raw_data(&vbo_ids))

    // Nodes
    GL.BindBuffer(GL.ARRAY_BUFFER, vbo_ids[0])
    GL.BufferData(GL.ARRAY_BUFFER, len(node_vertices)*size_of(f32), &node_vertices[0], GL.STATIC_DRAW )
    GL.BindBuffer(GL.ARRAY_BUFFER, 0)

    // Pellets
    GL.BindBuffer(GL.ARRAY_BUFFER, vbo_ids[1])
    GL.BufferData(GL.ARRAY_BUFFER, len(pellet_vertices)*size_of(f32), &pellet_vertices[0], GL.STATIC_DRAW )
    GL.BindBuffer(GL.ARRAY_BUFFER, 0)

    vertex_builder: gfx.VertexBuilder

    pos_attr: gfx.VertexAttribute
    pos_attr.count = 2
    pos_attr.value_type = .Float

    gfx.push_attribute(&vertex_builder, pos_attr)

    color_attr: gfx.VertexAttribute
    color_attr.count = 4
    color_attr.value_type = .Float

    gfx.push_attribute(&vertex_builder, color_attr)

    size_attr: gfx.VertexAttribute
    size_attr.count = 1
    size_attr.value_type = .Float

    gfx.push_attribute(&vertex_builder, size_attr)

    gfx.generate_layout(&vertex_builder, vbo_ids[0], vao_ids[0])
    gfx.generate_layout(&vertex_builder, vbo_ids[1], vao_ids[1])

    level.node_vao_id = vao_ids[0]
    level.pellets_vao_id = vao_ids[1]
    
}

read_level :: proc(filename: string) -> (LevelData, ParseError) {
	file, read_ok := os.read_entire_file(filename, context.allocator)

	if !read_ok {
		return LevelData{}, .Couldnt_Read
	}

	str_data := string(file)

	lines, split_ok := strings.split_lines(str_data)

	if split_ok != nil {
		return LevelData{}, .Couldnt_Split
	}

	num_chars := 0

	for i in 0 ..< len(lines) {
		new_line, was_alloc := strings.remove_all(lines[i], " ")
		lines[i] = new_line

		num_chars += len(new_line)
	}

	row_count := len(lines) - 1
	col_count := num_chars / row_count

	if num_chars % row_count != 0 || num_chars % col_count != 0 {
		return LevelData{}, .Bad_Format
	}

	data := strings.concatenate(lines)
	wall_data: [dynamic]u32 = make([dynamic]u32, row_count * col_count)

	portal_count_map: map[rune]u32

	for rune, i in data {
		switch rune {
		case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9':
			ok := rune in portal_count_map

			if ok {
				portal_count_map[rune] += 1
				continue
			}

			portal_count_map[rune] = 1
		case 'X':
			wall_data[i] = 1
		}
	}

	for _, count in portal_count_map {
		if count != 2 {
			return LevelData{}, .Ambiguous_Portals
		}
	}


	delete(file)
	delete(lines)

	return {data, wall_data, row_count, col_count}, .None
}


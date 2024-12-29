package game

import Consts "../constants"
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
import "../logger"

NODE_BUFFER_SIZE_BYTES :: size_of(Node) * 512
PELLET_BUFFER_SIZE_BYTES :: size_of(Pellet) * 1024

MAX_NODE_COUNT :: 512

Level :: struct {
	node_buffer:    []u8,
	nodes:          []Node,
	pellets:        []Pellet,
	maze:			Maze,
	pacman_spawn:	^Node,
	ghost_spawns:	[]^Node,
	col_count:		i32,
	row_count:		i32,

    pellets_vao_id: u32,
    pellets_ssbo:   gfx.SSBO,

    node_vao_id:    u32,

	point_program:	gfx.Program,
	pellets_program:gfx.Program,
}

LevelData :: struct {
	data:					string,
	wall_data:				[dynamic]u32,
	row_count, col_count:	int,
}

FirstStageResult :: struct {
	node_array:		[]Node,
	pacman_spawn:	^Node,
	ghost_spawns:	[]^Node,
}

ObjectType :: enum u8 {
	Block       = 0,
	Node        = 1,
	Empty_Space = 2,
	Ghost_Gate  = 3,
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

cell_to_node_type := map[u8]bit_set[NodeType] {
	'g' = {.GhostOnly},
	's' = {.GhostOnly, .GhostSpawn},
	'S' = {.PacmanSpawn},
	'n' = {},
	'P' = {},
	'+' = {},
	'0' = {.Portal},
	'1' = {.Portal},
	'2' = {.Portal},
	'3' = {.Portal},
	'4' = {.Portal},
	'5' = {.Portal},
	'6' = {.Portal},
	'7' = {.Portal},
	'8' = {.Portal},
	'9' = {.Portal},
};


// TODO: Deal with the game memory passing and allocation
@export
load_level :: proc(game_memory: ^GameMemory, filename: string) -> ^Level {

	lvl_data, err := read_level(filename)

	if err != nil {
		fmt.panicf("Failed to read the level! %v", err)
	}

	lvl := parse_level(game_memory, &lvl_data) 
	lvl.maze = create_maze(&lvl_data);
	
	lvl.point_program = gfx.create_program("res/shaders/node_pellets")
	lvl.pellets_program = gfx.create_program("res/shaders/pellets")

	delete(lvl_data.wall_data)
	delete(lvl_data.data)

	return lvl
}


// Extracts the nodes and connects them horizontally.
// Note: It is up to the caller to free the given resources!
@export
create_and_connect_nodes :: proc(
	game_memory: ^GameMemory,
	lvl_data: ^LevelData,
) -> FirstStageResult {
	ghost_spawn_count: u32 = 0
	node_map: map[u64]Node = {}
	defer delete(node_map)

	portal_node_map: map[u8]^Node = {}
	defer delete(portal_node_map)

	row_nodes: [dynamic]^Node = {}
	defer delete(row_nodes)

    normalized_dims: linalg.Vector2f32 = {
		Consts.TILE_WIDTH * f32(lvl_data.col_count),
		Consts.TILE_HEIGHT * f32(lvl_data.row_count)
	}

	// Create new nodes and connect them horizontally
	for row in 0 ..< lvl_data.row_count {
		for col in 0 ..< lvl_data.col_count {

			obj := data_at(lvl_data, col, row) 

			if obj == 'X' {
				if len(row_nodes) > 0 {
					connect_nodes(&row_nodes, false)
					clear(&row_nodes)
				}

				continue;
			}

			node_flags, node_found := cell_to_node_type[obj]

			if !node_found {
				continue
			}

			key := u64(col | row << 32)

			position: linalg.Vector2f32 =  {
				f32(col) * Consts.TILE_WIDTH - normalized_dims.x/2,
			    normalized_dims.y - f32(row) * Consts.TILE_HEIGHT - normalized_dims.y/2,
			}

			node_map[key] = Node{
				position = position,
				flags = node_flags
			}

			new_node, _ := &node_map[key]
			new_node.flags = node_flags
			append(&row_nodes, new_node)

			if NodeType.GhostSpawn in node_flags {
				ghost_spawn_count += 1
			}

			if node_flags == {NodeType.Portal} {
				portal_node, ok := portal_node_map[obj]

				if ok {
					new_node.neighbors[Direction.Portal] = portal_node
					portal_node.neighbors[Direction.Portal] = new_node
					continue
				}

				portal_node_map[obj] = new_node
			}
		}

		if len(row_nodes) > 0 {
			connect_nodes(&row_nodes, false)
			clear(&row_nodes)
		}
	}


	// Connect found nodes vertically
	col_nodes: [dynamic]^Node = {}
	defer delete(col_nodes)

	// For checking whether all the nodes were found.
	node_count := 0

	for col in 0 ..< lvl_data.col_count {
		for row in 0 ..< lvl_data.row_count {
			obj := lvl_data.data[col + lvl_data.col_count * row]

			position: linalg.Vector2f32 =  {
				f32(col) * Consts.TILE_WIDTH - normalized_dims.x/2,
				normalized_dims.y - f32(row) * Consts.TILE_HEIGHT - normalized_dims.y/2,
			}

			if obj == 'X' && len(col_nodes) > 0 {
				connect_nodes(&col_nodes, true)
				clear(&col_nodes)
			}

			found_node, ok := &node_map[u64(col | row << 32)]

			if ok {
				append(&col_nodes, found_node)
				node_count += 1
			}
		}

		if len(col_nodes) > 0 {
			connect_nodes(&col_nodes, true)
			clear(&col_nodes)
		}
	}

	assert(node_count == len(node_map))

	result: FirstStageResult = {
		node_array = make([]Node, node_count),
		ghost_spawns = make([]^Node, ghost_spawn_count)
	}

	node_i := 0
	ghost_i := 0

	for _, &node in node_map {
		result.node_array[node_i] = node

		fmt.printfln("Node %d: %v", node_i, rawptr(&result.node_array[node_i]))

		if NodeType.GhostSpawn in node.flags {
			result.ghost_spawns[ghost_i] = &result.node_array[node_i]
			ghost_i += 1
		}

		if node.flags == {NodeType.PacmanSpawn} {
			result.pacman_spawn = &result.node_array[node_i]
		}

		node_i += 1
	}

	return result
}

// Connects the given nodes vertically and creates pellets
// The second stage of creating a level.
@export
find_and_create_pellets :: proc(
	lvl_data: ^LevelData,
) -> []Pellet {
	assert(len(lvl_data.data) > 0)
 
	pellets: [dynamic]Pellet = {}

    normalized_dims: linalg.Vector2f32 = {
		Consts.TILE_WIDTH * f32(lvl_data.col_count),
		Consts.TILE_HEIGHT * f32(lvl_data.row_count)
	}

	for col in 0 ..< lvl_data.col_count {
		for row in 0 ..< lvl_data.row_count {

			obj := lvl_data.data[col + lvl_data.col_count * row]

			position: linalg.Vector2f32 =  {
				f32(col) * Consts.TILE_WIDTH - normalized_dims.x/2,
			    normalized_dims.y - f32(row) * Consts.TILE_HEIGHT - normalized_dims.y/2,
			}
			
			if (obj == '.' || obj == '+' || obj == 'P' || obj == 'p') {
				append(&pellets, Pellet{
					position = position,
					flash_time = 0.2,
					points = 50,
					radius = obj == 'P' ? Consts.POWER_PELLET_RADIUS : Consts.PELLET_RADIUS,
					timer = obj == 'P' ? 0 : 10,
					is_power_pellet = obj == 'P',
					is_visible = true,
				})
			}

		}
	}

	return pellets[:]
}

@export
parse_level :: proc(game_memory: ^GameMemory, lvl_data: ^LevelData) -> ^Level {

	lvl, ok := arena_push_struct(&game_memory.permanent_storage, Level)

	if !ok {
		panic("Failed to parse Level! Level is nil!")
	}

	first_stage_result := create_and_connect_nodes(game_memory, lvl_data)
	assert(
		first_stage_result.pacman_spawn != nil && len(first_stage_result.node_array) > 0 &&
		len(first_stage_result.ghost_spawns) > 0
	)

	pellets := find_and_create_pellets(lvl_data)
	assert(len(pellets) > 0)

	lvl.nodes = first_stage_result.node_array
	lvl.pellets = pellets
    lvl.node_vao_id, _ = create_debug_nodes_buffer(lvl.nodes)
    lvl.pellets_vao_id, _, lvl.pellets_ssbo = create_pellets_buffer(lvl.pellets)
	lvl.pacman_spawn = first_stage_result.pacman_spawn
	lvl.ghost_spawns = first_stage_result.ghost_spawns
	lvl.col_count = i32(lvl_data.col_count)
	lvl.row_count = i32(lvl_data.row_count)

	// fmt.printfln("Pacman Spawn: %d", level.pacman_spawn)
	// fmt.printfln("Ghost Spawns: %d", level.ghost_spawns)

	return lvl
}

@export
destroy_level :: proc(lvl: ^Level) {

	gfx.delete_ssbo(lvl.pellets_ssbo)
	destroy_maze(&lvl.maze)

	node_vao_ptr: [1]u32 = [1]u32{lvl.node_vao_id}
	GL.DeleteVertexArrays(1, &node_vao_ptr[0])

	pellets_vao_ptr: [1]u32 = [1]u32{lvl.pellets_vao_id}
	GL.DeleteVertexArrays(1, &pellets_vao_ptr[0])
    
    delete(lvl.node_buffer)
	delete(lvl.nodes)
	delete(lvl.pellets)
	delete(lvl.ghost_spawns)

	lvl.ghost_spawns = nil
	lvl.pacman_spawn = nil
	
	lvl.col_count = -1
	lvl.row_count = -1

	free(lvl)
}

@export
connect_nodes :: proc(nodes: ^[dynamic]^Node, connect_in_col: bool) {
	if connect_in_col {
		for i in 0 ..<len(nodes) - 1 {
			nodes[i].neighbors[Direction.Down] = nodes[i + 1]
			nodes[i + 1].neighbors[Direction.Up] = nodes[i]
		}

		return
	}

	for i in 0 ..<len(nodes) - 1 {
		nodes[i].neighbors[Direction.Right] = nodes[i + 1]
		nodes[i + 1].neighbors[Direction.Left] = nodes[i]
	}
}

@export
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

@export
read_level :: proc(filename: string) -> (LevelData, ParseError) {
	file, read_ok := os.read_entire_file(filename, context.allocator)
	defer delete(file)

	if !read_ok {
		return LevelData{}, .Couldnt_Read
	}

	str_data := string(file)

	lines, split_ok := strings.split_lines(str_data)
	defer delete(lines)

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

	return {data, wall_data, row_count, col_count}, .None
}

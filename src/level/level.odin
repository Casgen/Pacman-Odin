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
import "../gfx"

NODE_BUFFER_SIZE_BYTES :: size_of(Ent.Node) * 512
PELLET_BUFFER_SIZE_BYTES :: size_of(Ent.Pellet) * 1024

Level :: struct {
	node_arena:         virtual.Arena,
	node_buffer:        []u8,
	nodes:              [dynamic]^Ent.Node,
	pellets:            [dynamic]Ent.Pellet,
    pellets_vao_id:     u32,
    pellets_ssbo:       gfx.SSBO,
    node_vao_id:        u32,
}

LevelData :: struct {
	data:                 string,
	row_count, col_count: int,
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


load_level :: proc(filename: string) -> ^Level {
	lvl_data, err := read_level(filename)
	assert(err == ParseError.None)

	return parse_level(&lvl_data)
}

// Extracts the nodes and connects them horizontally
first_parse_stage :: proc(
	node_allocator: mem.Allocator,
	lvl_data: ^LevelData,
) -> map[string]^Ent.Node {

	node_map: map[string]^Ent.Node
	portal_node_map: map[u8]^Ent.Node

    normalized_dims: linalg.Vector2f32 = {Consts.TILE_WIDTH * f32(lvl_data.col_count), Consts.TILE_HEIGHT * f32(lvl_data.row_count)}

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

				new_node := Ent.create_node(position.x, position.y, false, true, node_allocator)

				node_map[key] = new_node
				append(&row_nodes, new_node)
			case '+', 'P', 'n':
				key: string = fmt.aprintf("%d|%d", row, col)

				new_node := Ent.create_node(position.x, position.y, false, false, node_allocator)

				node_map[key] = new_node
				append(&row_nodes, new_node)
			case 'X':
				if len(row_nodes) > 0 {
					connect_nodes(row_nodes, false)
					clear(&row_nodes)
				}
			case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9':
				key: string = fmt.aprintf("%d|%d", row, col)

				new_node := Ent.create_node(position.x, position.y, true, false, node_allocator)

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

	return node_map
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


parse_level :: proc(lvl_data: ^LevelData) -> ^Level {

	level: ^Level = new(Level)

	level.node_buffer = make([]u8, size_of(Ent.Node) * 512)


	err := virtual.arena_init_buffer(&level.node_arena, level.node_buffer)

	if err != nil {
		fmt.println("Failed to initialize a node arena %v\n", err)
	}

	node_allocator := virtual.arena_allocator(&level.node_arena)


	node_map := first_parse_stage(node_allocator, lvl_data)
	pellets := second_parse_stage(lvl_data, &node_map)

	reserve(&level.nodes, len(node_map))

	for _, node in node_map {
		append(&level.nodes, node)
	}

	level.pellets = pellets

    level.node_vao_id, _ = Ent.create_debug_nodes_buffer(level.nodes)
    level.pellets_vao_id, _, level.pellets_ssbo = Ent.create_pellets_buffer(level.pellets)

	return level
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

	portal_count_map: map[rune]u32

	for rune in data {
		switch rune {
		case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9':
			ok := rune in portal_count_map

			if ok {
				portal_count_map[rune] += 1
				continue
			}

			portal_count_map[rune] = 1
		}
	}

	for _, count in portal_count_map {
		if count != 2 {
			return LevelData{}, .Ambiguous_Portals
		}
	}


	delete(file)
	delete(lines)

	return {data, row_count, col_count}, .None
}


package level

import Consts "../constants"
import Ent "../entities"
import "core:fmt"
import linalg "core:math/linalg"
import "core:os"
import "core:strings"

Level :: struct {
	nodes:   [dynamic]^Ent.Node,
	pellets: [dynamic]Ent.Pellet,
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




parse_level :: proc(lvl_data: LevelData) -> ^Level {

	node_map: map[string]^Ent.Node
	portal_node_map: map[u8]^Ent.Node
    pellets: [dynamic]Ent.Pellet

	// Process all Nodes in rows
	for row in 0 ..< lvl_data.row_count {

		row_nodes: [dynamic]^Ent.Node = {}

		for col in 0 ..< lvl_data.col_count {

			obj := lvl_data.data[col + lvl_data.col_count * row]
            position: linalg.Vector2f32 = {f32(col * int(Consts.TILE_WIDTH)), f32(row * int(Consts.TILE_HEIGHT))}

			switch obj {
			case '+', 'P', 'n':
				key: string = fmt.aprintf("%d|%d", row, col)
                
                new_node := Ent.create_node(position.x, position.y)

				node_map[key] = new_node
				append(&row_nodes, new_node)
			case 'X':
				if len(row_nodes) > 0 {
					connect_nodes(row_nodes, false)
					clear(&row_nodes)
				}
			case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9':
				key: string = fmt.aprintf("%d|%d", row, col)

                new_node := Ent.create_node(position.x, position.y, true)

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

	// Process all Nodes in columns and create pellets
	for col in 0 ..< lvl_data.col_count {

		col_nodes: [dynamic]^Ent.Node = {}

		for row in 0 ..< lvl_data.row_count {

			obj := lvl_data.data[col + lvl_data.col_count * row]
            position: linalg.Vector2f32 = {f32(col * int(Consts.TILE_WIDTH)), f32(row * int(Consts.TILE_HEIGHT))}

			switch obj {
            case 'n':
				key: string = fmt.aprintf("%d|%d", row, col)
				found_node := node_map[key]
				append(&col_nodes, found_node)
			case '+':
				key: string = fmt.aprintf("%d|%d", row, col)
				found_node := node_map[key]
				append(&col_nodes, found_node)
                fallthrough
            case '.':
                append(&pellets, Ent.Pellet{false, position, 0.2, 50, Consts.PELLET_RADIUS, 0})
			case 'P':
				key: string = fmt.aprintf("%d|%d", row, col)
				found_node := node_map[key]
				append(&col_nodes, found_node)
                fallthrough
            case 'p':
                append(&pellets, Ent.Pellet{false, position, 0.2, 50, Consts.POWER_PELLET_RADIUS, 10})
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

	level: ^Level = new(Level)
	reserve(&level.nodes, len(node_map))

	for _, node in node_map {
		append(&level.nodes, node)
	}

    level.pellets = pellets

	return level
}

destroy_level :: proc(level: ^Level) {
	delete(level.nodes)
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

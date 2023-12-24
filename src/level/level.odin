package level

import Consts "../constants"
import Ent "../entities"
import "core:fmt"
import linalg "core:math/linalg"
import "core:os"

Level :: struct {
	nodes: [dynamic]^Ent.Node,
}

LevelData :: struct {
	data:                 [dynamic]u8,
	row_count, col_count: int,
}

ObjectType :: enum u8 {
	Block       = 0,
	Node        = 1,
	Empty_Space = 2,
	Ghost_Gate  = 3,
}


load_level :: proc(lvl_data: LevelData) -> ^Level {

	node_map: map[string]^Ent.Node

	// Process all Nodes in rows
	for row in 0 ..< lvl_data.row_count {

		row_nodes: [dynamic]^Ent.Node = {}

		for col in 0 ..< lvl_data.col_count {

			obj_type: ObjectType = ObjectType(lvl_data.data[col + lvl_data.col_count * row])

			#partial switch obj_type {
			case ObjectType.Node:
				key: string = fmt.aprintf("%d|%d", row, col)

				new_node: ^Ent.Node = new(Ent.Node)
				new_node.position =  {
					f32(col * int(Consts.TILE_WIDTH)),
					f32(row * int(Consts.TILE_HEIGHT)),
				}

				node_map[key] = new_node
				append(&row_nodes, new_node)
			case ObjectType.Block:
				if len(row_nodes) > 0 {
					connect_nodes(row_nodes, false)
					clear(&row_nodes)
				}
			}

		}

		connect_nodes(row_nodes, false)
		clear(&row_nodes)
	}

	// Process all Nodes in columns
	for col in 0 ..< lvl_data.col_count {

		col_nodes: [dynamic]^Ent.Node = {}

		for row in 0 ..< lvl_data.row_count {

			obj_type: ObjectType = ObjectType(lvl_data.data[col + lvl_data.col_count * row])

			#partial switch obj_type {
			case ObjectType.Node:
				key: string = fmt.aprintf("%d|%d", row, col)
				found_node := node_map[key]
				append(&col_nodes, found_node)
			case ObjectType.Block:
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

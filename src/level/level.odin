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
}


load_level :: proc(lvl_data: LevelData) -> ^Level {

	node_map: map[string]^Ent.Node

	// Process all Nodes in rows
	for row in 0 ..< lvl_data.row_count {

		row_nodes: [dynamic]^Ent.Node = {}

		for col in 0 ..< lvl_data.col_count {

			byte: ObjectType = ObjectType(lvl_data.data[col + lvl_data.col_count * row])

			if ObjectType.Node == byte {
				key: string = fmt.aprintf("%d|%d", row, col)

				new_node: ^Ent.Node = new(Ent.Node)
				new_node.position =  {
					f32(col * int(Consts.TILE_WIDTH)),
					f32(row * int(Consts.TILE_HEIGHT)),
				}

				node_map[key] = new_node
				append(&row_nodes, new_node)
			}


		}

		for i in 0 ..< (len(row_nodes) - 1) {
			row_nodes[i].neighbors[Ent.Direction.Right] = row_nodes[i + 1]
			row_nodes[i + 1].neighbors[Ent.Direction.Left] = row_nodes[i]
		}

		clear(&row_nodes)
	}

	// Process all Nodes in columns
	for col in 0 ..< lvl_data.col_count {

		col_nodes: [dynamic]^Ent.Node = {}

		for row in 0 ..< lvl_data.row_count {

			byte: ObjectType = ObjectType(lvl_data.data[col + lvl_data.col_count * row])

			if ObjectType.Node == byte {
				key: string = fmt.aprintf("%d|%d", row, col)

				new_node: ^Ent.Node = new(Ent.Node)
				new_node.position =  {
					f32(col * int(Consts.TILE_WIDTH)),
					f32(row * int(Consts.TILE_HEIGHT)),
				}

				append(&col_nodes, node_map[key])
			}


		}

		for i in 0 ..< (len(col_nodes) - 1) {
			col_nodes[i].neighbors[Ent.Direction.Down] = col_nodes[i + 1]
			col_nodes[i + 1].neighbors[Ent.Direction.Up] = col_nodes[i]
		}

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

package entities

import LinAlg "core:math/linalg"

Direction :: enum i8 {
	None   = -1,
	Up     = 0,
	Down   = 1,
	Left   = 2,
	Right  = 3,
    Portal = 4
}

Node :: struct {
	neighbors: [5]^Node,
	position:  LinAlg.Vector2f32,
    is_portal: bool,
}

create_node :: proc(position_x, position_y: f32, is_portal: bool = false) -> ^Node {
	node: ^Node = new(Node)

	node.position.x = position_x
	node.position.y = position_y
    node.is_portal = is_portal
	node.neighbors = {}

	return node
}

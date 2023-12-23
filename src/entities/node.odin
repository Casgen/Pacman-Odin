package entities

import LinAlg "core:math/linalg"

Direction :: enum i8 {
	Stop  = -1,
	Up    = 0,
	Down  = 1,
	Left  = 2,
	Right = 3,
}

Node :: struct {
	neighbors: [4]^Node,
	position:  LinAlg.Vector2f32,
	index:     u32,
}

prepare_nodes_test :: proc() -> [7]^Node {

	nodeA: ^Node = new_node(80, 80, 0) // {{}, 80, 80, 0}
	nodeB: ^Node = new_node(160, 80, 0) // {{}, 80, 80, 0}
	nodeC: ^Node = new_node(80, 160, 0) // {{}, 80, 80, 0}
	nodeD: ^Node = new_node(160, 160, 0) // {{}, 80, 80, 0}
	nodeE: ^Node = new_node(208, 160, 0) // {{}, 80, 80, 0}
	nodeF: ^Node = new_node(80, 320, 0) // {{}, 80, 80, 0}
	nodeG: ^Node = new_node(208, 320, 0) // {{}, 80, 80, 0}

	nodeA.neighbors[Direction.Right] = nodeB
	nodeA.neighbors[Direction.Down] = nodeC
	nodeB.neighbors[Direction.Left] = nodeA
	nodeB.neighbors[Direction.Down] = nodeD
	nodeC.neighbors[Direction.Up] = nodeA
	nodeC.neighbors[Direction.Right] = nodeD
	nodeC.neighbors[Direction.Down] = nodeF
	nodeD.neighbors[Direction.Up] = nodeB
	nodeD.neighbors[Direction.Left] = nodeC
	nodeD.neighbors[Direction.Right] = nodeE
	nodeE.neighbors[Direction.Left] = nodeD
	nodeE.neighbors[Direction.Down] = nodeG
	nodeF.neighbors[Direction.Up] = nodeC
	nodeF.neighbors[Direction.Right] = nodeG
	nodeG.neighbors[Direction.Up] = nodeE
	nodeG.neighbors[Direction.Left] = nodeF

	return [7]^Node{nodeA, nodeB, nodeC, nodeD, nodeE, nodeF, nodeG}
}

new_node :: proc(position_x, position_y: f32, index: u32) -> ^Node {
	node: ^Node = new(Node)
	node.position.x = position_x
	node.position.y = position_y
	node.neighbors = {}

	node.index = index

	return node
}

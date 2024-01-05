package entities

import "core:math/linalg"
import "../gfx"

Entity :: struct {
	position:         linalg.Vector2f32,
    scale:            linalg.Vector2f32,
	velocity:         linalg.Vector2f32,
    layer:            f32,
    quad:             gfx.Quad,
	current_node:     ^Node,
	target_node:      ^Node,
	speed:            f32,
	collision_radius: f32,
	direction:        Direction,
    derived: union {Pacman, Ghost}
}

new_entity :: proc($T: typeid) -> ^Entity {
    t := new(Entity)
    t.derived = T{entity = t}
    return t
}

has_overshot_target :: proc(entity: ^Entity) -> bool {
    path_distance := linalg.vector_length2(entity.current_node.position - entity.target_node.position)
    distance_to_node := linalg.vector_length2(entity.current_node.position - entity.position) 

    return path_distance <= distance_to_node
}


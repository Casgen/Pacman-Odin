package entities
import "core:math/linalg"

Entity :: struct {
	position:         linalg.Vector2f32,
	velocity:         linalg.Vector2f32,
	current_node:     ^Node,
	target_node:      ^Node,
	speed:            f32,
	collision_radius: f32,
	direction:        Direction,

    derived: union { Pacman, Ghost}
}

new_entity :: proc($T: typeid) -> ^Entity {
    t := new(Entity)
    t.derived = T{entity = t}
    return t
}


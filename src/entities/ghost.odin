package entities

import "core:math/linalg"

Ghost :: struct {
	position:         linalg.Vector2f32,
	velocity:         linalg.Vector2f32,
	current_node:     ^Node,
	target_node:      ^Node,
	speed:            f32,
	collision_radius: f32,
	direction:        Direction,
}





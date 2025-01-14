package game

import lg "core:math/linalg"

AABB_2D :: struct {
	min, max: lg.Vector2f32
}

// Ideally use this after every creation of the AABB_2D. swaps the
// min and max points to be positioned properly.
fix_points :: proc(aabb: ^AABB_2D) {

	if (aabb.min.y > aabb.max.y) {
		temp := aabb.min.y
		aabb.min.y = aabb.max.y
		aabb.max.y = temp
	}

	if (aabb.min.x > aabb.max.x) {
		temp := aabb.min.x
		aabb.min.x = aabb.max.x
		aabb.max.x = temp
	}
}

collides_with_aabb :: proc(aabb: ^AABB_2D, other: ^AABB_2D) -> bool {

	is_to_the_right := aabb.max.x > other.min.x
	is_to_the_left := aabb.min.x < other.max.x

	is_above := aabb.max.y < other.min.y
	is_below := aabb.min.y > other.max.y

	return !(is_to_the_right || is_to_the_left || is_below || is_above)
}

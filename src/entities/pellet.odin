package entities

import "../constants"
import "core:math/linalg"

Pellet :: struct {
	is_power_pellet: bool,
	position:        linalg.Vector2f32,
	flash_time:      f32,
	points:          u32,
	radius:          i32,
	timer:           f32,
}


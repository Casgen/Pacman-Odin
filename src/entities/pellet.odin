package entities

import "../constants"
import "core:math/linalg"

Pellet :: struct {
	position:         linalg.Vector2f32,
	flash_time:       f32,
	points:           u32,
	radius:           f32,
	timer:            f32,
	is_power_pellet:  bool,
}


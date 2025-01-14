package game

import lg "core:math/linalg"
import "../gfx"

Entity_Type :: enum u32 {
	STATIC_OBJECT,
	DYNAMIC_OBJECT,
    PLAYER,
}

Direction :: enum u8 {
	Right,
	Down,
	Left,
	Up,
}

DirectionToVector :: [Direction]lg.Vector2f32 {
	Direction.Right = lg.Vector2f32{1.0, 0.0},
	Direction.Left = lg.Vector2f32{-1.0, 0.0},
	Direction.Up = lg.Vector2f32{0.0, 1.0},
	Direction.Down = lg.Vector2f32{0.0, -1.0}
}

direction_to_vec := DirectionToVector

Entity :: struct {
	type:		Entity_Type,
	position:	lg.Vector2f32,
	scale:		lg.Vector2f32,
    quad:		gfx.Quad,
}

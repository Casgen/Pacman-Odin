package game

import "../gfx"
import lg "core:math/linalg"

Player_State :: enum u8 {
	Moving,
	Idle,
	Jumping,
}


Player :: struct {
    using entity:   Entity,
    bounding_box:   AABB_2D,
    jump_height:    f32,
    curr_dirs:      bit_set[Direction],
    speed:          f32,
    state:			Player_State,
    velocity:       lg.Vector2f32,
    mass:           f32,
}

player_init :: proc(player: ^Player) {
	player.velocity = {0.0, 0.0}
	player.position = {0.0, 0.0}
	player.jump_height = 0.0025
	player.curr_dirs = {}
	player.state = .Idle
	player.scale = {0.25, 0.25}
	player.mass = 1.0
	player.quad = gfx.create_quad({0.0, 1.0, 1.0, 1.0}, player.scale, player.position)
	player.speed = 0.0005
}

player_set_direction :: proc(player: ^Player, dir: Direction) {
	player.curr_dirs += {dir}
}

player_unset_direction :: proc(player: ^Player, dir: Direction) {
	player.curr_dirs -= {dir}
}

player_jump :: proc(player: ^Player) {

	if (player.velocity.y <= 0.0) {
		player.velocity.y += player.jump_height
	}
}

player_update :: proc(player: ^Player, dt: f32) {
	player.velocity.x = 0.0

	if (card(player.curr_dirs) > 0) {
		player.velocity.x -= f32(u32(Direction.Left in player.curr_dirs)) * 1.0 * player.speed
		player.velocity.x += f32(u32(Direction.Right in player.curr_dirs)) * 1.0 * player.speed
	}

	player.velocity.y -= GRAVITY_FORCE * 0.00001
	player.velocity.y = player.velocity.y

	player.position += player.velocity * dt
	player.position.y = max(0.0, player.position.y)

	if (player.position.y <= 0.0) {
		player.velocity.y = 0
	}
}

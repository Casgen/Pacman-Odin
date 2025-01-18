package game

import "../gfx"
import lg "core:math/linalg"
import SDL "vendor:sdl2"
import "core:fmt"

Player_State :: enum u8 {
	Moving,
	Idle,
	InAir,
}


Player :: struct {
    using entity:   Entity,
    bounding_box:   AABB_2D,
    jump_force:     f32,
    speed:          f32,
    acceleration:   f32,
    mass:           f32,
    curr_dirs:      bit_set[Direction],
    state:			Player_State,
    velocity:       lg.Vector2f32,
}

player_init :: proc(player: ^Player) {
	player.velocity = {0.0, 0.0}
	player.position = {0.0, 0.0}
	player.jump_force = 0.01
	player.state = .Idle
	player.scale = {0.25, 0.25}
	player.mass = 1.0
    player.acceleration = 0.2
	player.quad = gfx.create_quad({0.0, 1.0, 1.0, 1.0}, player.scale, player.position)
	player.speed = 0.001
    player.curr_dirs = {}
}

// player_handle_input :: proc(player: ^Player, event: ^SDL.Event) {
//
//     if event.type == SDL.EventType.KEYUP {
//         key_scancode := event.key.keysym.scancode
//
//         prev_state := player.state
//
//         switch player.state {
//             case .Moving:
//                 if key_scancode == SDL.Scancode.RIGHT {
//                     player.curr_dirs -= {Direction.Right}
//                 }
//
//                 if key_scancode == SDL.Scancode.LEFT {
//                     player.curr_dirs -= {Direction.Left}
//                 }
//
//                 is_moving :=  player.curr_dirs & {Direction.Left, Direction.Right}
//
//                 if card(is_moving) == 0 {
//                     fmt.printfln("KEYUP: Transition %v -> %v, ", prev_state, player.state)
//                     player.velocity.x = 0.0
//                     player.state = .Idle
//                 }
//             case .Idle: // Do Nothing
//                 fmt.printfln("KEYUP: Idle -- Doing Nothing")
//             case .InAir: // Do Nothing
//                 if key_scancode == SDL.Scancode.RIGHT {
//                     player.curr_dirs -= {Direction.Right}
//                 }
//
//                 if key_scancode == SDL.Scancode.LEFT {
//                     player.curr_dirs -= {Direction.Left}
//                 }
//         }
//
//
//     }
//
//     if event.type == SDL.EventType.KEYDOWN {
//         key_scancode := event.key.keysym.scancode
//         prev_state := player.state
//
//         switch player.state {
//             case .Moving:
//                 if key_scancode == SDL.Scancode.LEFT {
//                     player.velocity.x -= player.speed
//                 }
//
//                 if key_scancode == SDL.Scancode.RIGHT {
//                     player.velocity.x += player.speed
//                 }
//
//                 if key_scancode == SDL.Scancode.UP {
//                     player.velocity.y = player.jump_force
//                     player.state = Player_State.InAir     
//                     fmt.printfln("KEYDOWn: Transition %v -> %v, ", prev_state, player.state)
//                 }
//             case .Idle:
//                 if key_scancode == SDL.Scancode.LEFT {
//                     player.velocity.x -= player.speed
//                     player.curr_dirs += {Direction.Left}
//                     player.state = Player_State.Moving     
//                     fmt.printfln("KEYDOWn: Transition %v -> %v, ", prev_state, player.state)
//                 }
//
//                 if key_scancode == SDL.Scancode.RIGHT {
//                     player.velocity.x += player.speed
//                     player.curr_dirs += {Direction.Right}
//                     player.state = Player_State.Moving     
//                     fmt.printfln("KEYDOWn: Transition %v -> %v, ", prev_state, player.state)
//                 }
//
//                 if key_scancode == SDL.Scancode.UP {
//                     player.velocity.y = player.jump_force
//                     player.state = Player_State.InAir     
//                     fmt.printfln("KEYDOWn: Transition %v -> %v, ", prev_state, player.state)
//                 }
//             case .InAir:
//                 if key_scancode == SDL.Scancode.LEFT {
//                     player.velocity.x -= player.speed
//                     player.curr_dirs += {Direction.Left}
//                 }
//
//                 if key_scancode == SDL.Scancode.RIGHT {
//                     player.velocity.x += player.speed
//                     player.curr_dirs += {Direction.Right}
//                 }
//         }
//     }
// }
//
// is_moving_right_or_left :: proc(player: ^Player) -> bool {
//     is_moving := player.curr_dirs & {Direction.Left, Direction.Right}
//     return card(is_moving) > 0
// }
//
// player_update :: proc(player: ^Player, dt: f32) {
//
//     if player.state == .Idle {
//         player.velocity = {0.0, 0.0}
//     }
//
//     if player.state == .InAir {
// 	    player.velocity.y -= GRAVITY_FORCE * 0.00001
//     }
//
//     player.velocity.x = clamp(player.velocity.x, -player.speed, player.speed)
// 	player.position += player.velocity * dt
//
// 	if player.position.y < 0.0 {
// 		player.velocity.y = 0
// 		player.position.y = 0
//
//         if is_moving_right_or_left(player) {
//             fmt.printfln("Transition %v -> %v, ", player.state, Player_State.Idle)
//             player.state = .Moving
//         } else {
//             player.state = .Idle
//         }
// 	}
//
// }

// Checks by doing an intersection of the set
is_moving_right_or_left :: proc(player: ^Player) -> bool {
    return card(player.curr_dirs & {Direction.Left, Direction.Right}) > 0
}

@private
handle_keyup :: proc(player: ^Player, key_scancode: SDL.Scancode) {

    #partial switch key_scancode {
        case SDL.Scancode.LEFT:
            player.curr_dirs -= {Direction.Left}
        case SDL.Scancode.RIGHT:
            player.curr_dirs -= {Direction.Right}
        case SDL.Scancode.UP:
            player.curr_dirs -= {Direction.Up}

    }

    if is_moving_right_or_left(player) && player.state != .InAir {
        player.state = .Idle
    }
}

@private
handle_keydown :: proc(player: ^Player, key_scancode: SDL.Scancode) {

    #partial switch key_scancode {
        case SDL.Scancode.LEFT:
            player.curr_dirs += {Direction.Left}
            
            if player.state != .InAir {
                player.state = .Moving
            }
        case SDL.Scancode.RIGHT:
            player.curr_dirs += {Direction.Right}

            if player.state != .InAir {
                player.state = .Moving
            }
        case SDL.Scancode.UP:
            if Direction.Up in player.curr_dirs || player.state == .InAir {
                break
            }
            
            player.curr_dirs += {Direction.Up}
            player.velocity.y = player.jump_force
            player.state = .InAir
    }
}

// TODO: Eventually probably refactor this. It might get soon complicated
player_handle_input :: proc(player: ^Player, event: ^SDL.Event) {
        
    key_scancode := event.key.keysym.scancode

    if event.type == SDL.EventType.KEYUP {
        handle_keyup(player, key_scancode)
    } else if event.type == SDL.EventType.KEYDOWN {
        handle_keydown(player, key_scancode)
    }
}


player_update :: proc(player: ^Player, dt: f32) {

    move_direction := f32(u32(Direction.Left in player.curr_dirs)) * -1 +
                      f32(u32(Direction.Right in player.curr_dirs)) * 1

    player.velocity.x += (move_direction * player.speed - player.velocity.x) * player.acceleration

    if player.state == .InAir {
        player.velocity.y -= GRAVITY_FORCE * 0.0001
    }

    player.position += player.velocity * dt

    if player.position.y < 0.0 {
        player.velocity.y = 0
        player.position.y = 0
        
        player.state = is_moving_right_or_left(player) ? .Moving : .Idle
    }

    fmt.printfln("State: %v, Velocity: %v", player.state, player.velocity)
}

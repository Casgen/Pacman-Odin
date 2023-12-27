package entities

import "../constants"
import "core:math/linalg"
import SDL "vendor:sdl2"

Pellet :: struct {
	position:        linalg.Vector2f32,
	flash_time:      f32,
	points:          u32,
	radius:          f32,
	timer:           f32,
	is_power_pellet: bool,
}

render_pellets :: proc(renderer: ^SDL.Renderer, pellets: [dynamic]Pellet) {
	for item in pellets {
		SDL.SetRenderDrawColor(renderer, 255, 255, 0, 255)
		rect: SDL.FRect = {item.position.x, item.position.y, f32(item.radius), f32(item.radius)}

		SDL.RenderFillRectF(renderer, &rect)
	}
}

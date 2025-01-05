package gfx

import SDL "vendor:sdl2"

gl_context: SDL.GLContext = nil

@export
set_gl_context :: proc(ctx: SDL.GLContext, win: ^SDL.Window) {
	gl_context = ctx
	ok := SDL.GL_MakeCurrent(win, gl_context)

	if ok != 0 {
		panic("Failed to set the OpenGL context")
	}
}

// You should not modify the context unless you know what you are doing!
get_gl_context :: proc() -> SDL.GLContext {
	return SDL.GL_GetCurrentContext()
}

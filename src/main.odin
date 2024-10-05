package main

import Consts "constants"
import "core:fmt"
import GL "vendor:OpenGL"
import SDL "vendor:sdl2"
import "entities"
import Level "level"
import "gfx"
import "core:time"
import "core:c/libc"

App :: struct {
	perf_frequency: f64,
	renderer:       ^SDL.Renderer,
	window:         ^SDL.Window,
	gl_context:     rawptr,
}

app := App{}

debug_callback := proc "c" (source: u32, type: u32, id: u32, severity: u32, length: i32, message: cstring, userParam: rawptr) {

    if (id == 131169 || id == 131185 || id == 131218 || id == 131204) { return }

    libc.fprintf(libc.stdout,"-------------------------")
    libc.fprintf(libc.stdout,"Debug Message (%d): %s\n", id, message)


    switch source
    {
    case GL.DEBUG_SOURCE_API: libc.fprintf(libc.stdout,"Source: API")
    case GL.DEBUG_SOURCE_WINDOW_SYSTEM: libc.fprintf(libc.stdout,"Source: Window System")
    case GL.DEBUG_SOURCE_SHADER_COMPILER: libc.fprintf(libc.stdout,"Source: Shader Compiler")
    case GL.DEBUG_SOURCE_THIRD_PARTY: libc.fprintf(libc.stdout,"Source: Third Party")
    case GL.DEBUG_SOURCE_APPLICATION: libc.fprintf(libc.stdout,"Source: Application")
    case GL.DEBUG_SOURCE_OTHER: libc.fprintf(libc.stdout,"Source: Other")
    }
    libc.fprintf(libc.stdout,"\n")

    switch type
    {
    case GL.DEBUG_TYPE_ERROR: libc.fprintf(libc.stdout,"Type: Error")
    case GL.DEBUG_TYPE_DEPRECATED_BEHAVIOR: libc.fprintf(libc.stdout,"Type: Deprecated Behaviour")
    case GL.DEBUG_TYPE_UNDEFINED_BEHAVIOR: libc.fprintf(libc.stdout,"Type: Undefined Behaviour")
    case GL.DEBUG_TYPE_PORTABILITY: libc.fprintf(libc.stdout,"Type: Portability")
    case GL.DEBUG_TYPE_PERFORMANCE: libc.fprintf(libc.stdout,"Type: Performance")
    case GL.DEBUG_TYPE_MARKER: libc.fprintf(libc.stdout,"Type: Marker")
    case GL.DEBUG_TYPE_PUSH_GROUP: libc.fprintf(libc.stdout,"Type: Push Group")
    case GL.DEBUG_TYPE_POP_GROUP: libc.fprintf(libc.stdout,"Type: Pop Group")
    case GL.DEBUG_TYPE_OTHER: libc.fprintf(libc.stdout,"Type: Other")
    }
    libc.fprintf(libc.stdout,"\n")

    switch severity
    {
    case GL.DEBUG_SEVERITY_HIGH: libc.fprintf(libc.stdout,"Severity: high")
    case GL.DEBUG_SEVERITY_MEDIUM: libc.fprintf(libc.stdout,"Severity: medium")
    case GL.DEBUG_SEVERITY_LOW: libc.fprintf(libc.stdout,"Severity: low")
    case GL.DEBUG_SEVERITY_NOTIFICATION: libc.fprintf(libc.stdout,"Severity: notification")
    }

    libc.fprintf(libc.stdout,"\n")
}

init_sdl_with_gl :: proc() {

	assert(SDL.Init(SDL.INIT_VIDEO | SDL.INIT_JOYSTICK | SDL.INIT_EVENTS) == 0, SDL.GetErrorString())

	SDL.GL_SetAttribute(SDL.GLattr.CONTEXT_PROFILE_MASK, auto_cast (SDL.GLprofile.CORE))
	SDL.GL_SetAttribute(SDL.GLattr.CONTEXT_MAJOR_VERSION, 4)
	SDL.GL_SetAttribute(SDL.GLattr.CONTEXT_MINOR_VERSION, 6)
	SDL.GL_SetAttribute(SDL.GLattr.DOUBLEBUFFER, 1)
	SDL.GL_SetAttribute(SDL.GLattr.DEPTH_SIZE, 24)

	app.window = SDL.CreateWindow(
		"PacMan",
		SDL.WINDOWPOS_CENTERED,
		SDL.WINDOWPOS_CENTERED,
		Consts.SCREEN_WIDTH,
		Consts.SCREEN_HEIGHT,
		SDL.WINDOW_SHOWN | SDL.WINDOW_OPENGL,
	)



    GL.load_up_to(4, 6, SDL.gl_set_proc_address)

	assert(app.window != nil, SDL.GetErrorString())

	app.gl_context = SDL.GL_CreateContext(app.window)

	assert(app.gl_context != nil, SDL.GetErrorString())

	if SDL.GL_SetSwapInterval(1) < 0 {
		fmt.panicf("Failed to set Swap Interval!: %s", SDL.GetErrorString())
	}

    GL.Enable(GL.DEBUG_OUTPUT)
    GL.Enable(GL.DEBUG_OUTPUT_SYNCHRONOUS)
    GL.Enable(GL.BLEND)
    GL.BlendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
    GL.DebugMessageCallback(debug_callback, nil)

}

main :: proc() {
	init_sdl_with_gl()

    spritesheet := gfx.load_spritesheet("res/spritesheet_new.png")
	level := Level.load_level("res/mazetest.txt")

	pacman := entities.create_pacman(level.nodes[0])
	ghost := entities.create_ghost(level.nodes[1], {1.0,1.0})
    program := gfx.create_program("res/shaders/quad/")
    point_program := gfx.create_program("res/shaders/node_pellets")
    pellets_program := gfx.create_program("res/shaders/pellets")

	time_start, time_last: f64
	timestep: f32 = 0

	event: SDL.Event
	state: [^]u8

    start_time: time.Duration
    delta_time: f32

    stopwatch: time.Stopwatch
    time.stopwatch_start(&stopwatch)

    GL.Enable(GL.PROGRAM_POINT_SIZE)

	game_loop: for {

        start_time = time.stopwatch_duration(stopwatch)

		#partial switch event.type {

        case SDL.EventType.QUIT:
            break game_loop

		case SDL.EventType.KEYDOWN:
			entities.update_direction(&pacman, event.key.keysym.scancode)
		}


		entities.update_pacman_pos(&pacman, delta_time)
        pellet, i := entities.try_eat_pellets(&pacman, &level.pellets)

        if pellet != nil {
            entities.set_visibility(pellet, i, level.pellets_ssbo, false)
            fmt.println("Eaten!")
        }

        entities.update_ghost_ai(&ghost, pacman.position, delta_time)

        GL.Clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)

        gfx.ogl_draw_debug_points(len(level.nodes), level.node_vao_id, point_program.id) 

        GL.BindBuffer(GL.SHADER_STORAGE_BUFFER, level.pellets_ssbo.id)
        GL.BindBufferBase(GL.SHADER_STORAGE_BUFFER, level.pellets_ssbo.binding, level.pellets_ssbo.id)
        gfx.ogl_draw_debug_points(len(level.pellets), level.pellets_vao_id, pellets_program.id) 

        entities.ogl_debug_render_player(&pacman, &program)
        entities.ogl_debug_render_ghost(&ghost, &program)

        SDL.GL_SwapWindow(app.window)

		SDL.PollEvent(&event)

        delta_time = cast(f32)time.duration_milliseconds(time.stopwatch_duration(stopwatch) - start_time)
	}
}

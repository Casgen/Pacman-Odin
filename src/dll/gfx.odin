/**
 * This struct serves the purpose of calling the gfx library which is dynamically linked at runtime
 * (explicitly linked).
 * How are procedure newly defined in this case is the following.
 * 1. Define the new procedure.
 * 2. Add a new member to the GfxProcs struct with a newly defined procedure type.
 * 3. In the `load_gfx_lib`, add a new call to `find_symbol` which will load a symbol address
 *	  based on the procedure name in the call. Make sure that you defined the name correctly!
 *	  If the search fails, it will log it and it's going to return `nil`.
 * 4. It is heavily advised to cast the `rawptr` to a desired procedure type to prevent type
 *	  confusion and mismatch. Also the LSP can better detect what is being used.
 * 5. After doing the definitions and adding needed calls, now the odin compiler has to
 *	  compile the given code to a .dll or .so file. (a dynamically linked library on Windows
 *    or shared object on Unix). With the newly created library, we can now link it at runtime
 *	  by calling the `load_library` function by passing the filepath to the library.
 *
 * NOTE: In the future somehow make the code fetch the procedure names by itself?
 * Maybe the `reflect` package could help with that.
 */

// TODO: Support hot reloading! See Casey's Handmade Hero video on linking
// Day 021

package dll

import "core:dynlib"
import SDL "vendor:sdl2"
import "../gfx"
import "../logger"

// A struct containing explicitly linked procedures to the GFX library. Should be used
// to support hot reloading!
GfxApi :: struct {
	create_program: proc(shader_dir_path: string) -> gfx.Program,
	create_shader: proc(shader_path: string, shader_type: u32) -> (shader: gfx.Shader, error: gfx.ShaderError),
	get_uniform_location: proc(using program: ^gfx.Program, name: cstring) -> i32,
	set_gl_context: proc(SDL.GLContext, ^SDL.Window),
	get_gl_context: proc() -> SDL.GLContext,
}


@private
library: dynlib.Library = nil


// Loads the gfx library dynamically at runtime and sets it GL context
// TODO: Find out why the OpenGL can not be called and crashes when a function from it
// is called. It has to do maybe something with the context not being passed in or set correctly.
load_gfx :: proc(ctx: SDL.GLContext, win: ^SDL.Window) -> GfxApi {

	lib, lib_ok := dynlib.load_library("build/gfx.so")
	assert(lib_ok, "Failed to load gfx.so library!")

	library = lib

	gfx_api := GfxApi{
		create_program = nil,
		create_shader = nil,
		get_uniform_location = nil,
		set_gl_context = nil
	}

	// Casting the procedures to ensure type safety.
	gfx_api.create_program = cast(proc(string) -> gfx.Program) find_symbol("create_program") 
	gfx_api.create_shader = cast(proc(string, u32) -> (gfx.Shader,gfx.ShaderError)) find_symbol("create_shader")
	gfx_api.get_uniform_location = cast(proc(^gfx.Program, cstring) -> i32) find_symbol("get_uniform_location")
	gfx_api.set_gl_context = cast(proc(SDL.GLContext, ^SDL.Window)) find_symbol("set_gl_context")
	gfx_api.get_gl_context = cast(proc() -> SDL.GLContext) find_symbol("get_gl_context")

	gfx_api.set_gl_context(ctx, win)

	return gfx_api
}

@private
find_symbol :: proc(symbol_name: string) -> rawptr {
	addr, ok := dynlib.symbol_address(library, symbol_name)

	if !ok {
		logger.log_errorf("Failed to fetch a symbol address %s", dynlib.last_error())
		return nil
	}

	logger.log_debugf("Fetched a symbol \"%s\"", symbol_name)

	return addr
}

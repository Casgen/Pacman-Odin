package game

import "core:mem"

back :: proc(array: ^$T/[dynamic]$E) -> ^E {
	assert(len(array) > 0)
	return &array[len(array) - 1]
}

copy_to_new_slice :: proc(array: ^$T/[dynamic]$E) -> []E {
	slice := make_slice([]E, len(array))
	copy(array[:], slice)

	return slice
}

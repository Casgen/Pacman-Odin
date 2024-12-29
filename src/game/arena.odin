package game

import "core:mem/virtual"
import "../logger"
import "core:mem"

// TODO: Test if the alignment is okay here. It might be wrong
arena_push_struct :: proc(arena: ^virtual.Arena, $T: typeid, alignment: uint = mem.DEFAULT_ALIGNMENT) -> (^T, bool) {
	alloc, ok := virtual.arena_alloc(arena, size_of(T), alignment)

	logger.log_debugf("Allocated %d B of memory of type %v. Ptr: %v", len(alloc), typeid_of(T), &alloc[0])

	using virtual.Allocator_Error;

	switch ok {
		case .None: return cast(^T)&alloc[0], true
		case .Out_Of_Memory: logger.log_fatalf("Failed to allocate a struct in arena! Out of memory!")
		case .Invalid_Pointer: logger.log_fatalf("Failed to allocate a struct in arena! Invalid pointer!")
		case .Invalid_Argument: logger.log_fatalf("Failed to allocate a struct in arena! Invalid argument!")
		case .Mode_Not_Implemented: logger.log_fatalf("Failed to allocate a struct in arena! Mode not implemented!")
	}

	return nil, false
}

// TODO: Test if the alignment is okay here. It might be wrong
arena_push_array :: proc(arena: ^virtual.Arena, $T: typeid, #any_int count: i32) -> []T {

	assert(count > 0)
	alloc, ok := virtual.arena_alloc(arena, size_of(T) * uint(count), mem.DEFAULT_ALIGNMENT)

	using virtual.Allocator_Error;
	switch ok {
		case .None: return mem.slice_data_cast([]T, alloc)
		case .Out_Of_Memory: logger.log_fatalf("Failed to allocate an array in arena! Out of memory!")
		case .Invalid_Pointer: logger.log_fatalf("Failed to allocate an array in arena! Invalid pointer!")
		case .Invalid_Argument: logger.log_fatalf("Failed to allocate an array in arena! Invalid argument!")
		case .Mode_Not_Implemented: logger.log_fatalf("Failed to allocate an array in arena! Mode not implemented!")
	}

	return nil
}

arena_offset :: proc(arena: ^virtual.Arena) -> ^u8 {
	alloc, ok := virtual.arena_alloc(arena, 0, mem.DEFAULT_ALIGNMENT)

	using virtual.Allocator_Error;

	switch ok {
		case .None: return &alloc[0]
		case .Out_Of_Memory: logger.log_fatalf("Failed to allocate an array in arena! Out of memory!")
		case .Invalid_Pointer: logger.log_fatalf("Failed to allocate an array in arena! Invalid pointer!")
		case .Invalid_Argument: logger.log_fatalf("Failed to allocate an array in arena! Invalid argument!")
		case .Mode_Not_Implemented: logger.log_fatalf("Failed to allocate an array in arena! Mode not implemented!")
	}

	return nil
}

package level

import "core:fmt"
import "core:os"
import "core:strings"

ParseError :: enum {
	Bad_Char,
	Couldnt_Read,
	Couldnt_Split,
	Bad_Format,
}

char_map := map[u8]ObjectType {
	'X' = ObjectType.Block,
	'+' = ObjectType.Node,
	'.' = ObjectType.Empty_Space,
}


parse_level :: proc(filename: string) -> (LevelData, ParseError) {
	file, read_ok := os.read_entire_file(filename, context.allocator)

	if !read_ok {
		return LevelData{}, ParseError.Couldnt_Read
	}

	str_data := string(file)

	lines, split_ok := strings.split_lines(str_data)

	if split_ok != nil {
		return LevelData{}, ParseError.Couldnt_Split
	}


	row_count := len(lines) - 1

	// This doesn't take into consideration the '\n' char
	num_chars := (len(file) - row_count)
	col_count := num_chars / row_count

	if num_chars % row_count != 0 || num_chars % col_count != 0 {
		return LevelData{}, ParseError.Couldnt_Split
	}

	level_data: LevelData = {{}, row_count, col_count}

	reserve(&level_data.data, num_chars)

	for line in lines {

		// Characters in a string are represented as []rune!
		for index in 0 ..< len(line) {
			append(&level_data.data, u8(char_map[line[index]]))
		}
	}

    delete(file)

	return level_data, nil

}

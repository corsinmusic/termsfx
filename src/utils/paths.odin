package utils

import "core:fmt"
import "core:os"
import "core:path/filepath"

resolve_path :: proc(file_path: string) -> (path: string) {
	home_dir: string

	// FIXME: should be a dynamic determination
	is_windows :: false

	if is_windows {
		home_dir = os.get_env("USERPROFILE") // Windows uses USERPROFILE
	} else {
		home_dir = os.get_env("HOME") // Unix-like systems use HOME
	}

	resolved_path := file_path
	if len(file_path) >= 1 && file_path[0] == '~' {
		// Remove '~' and any following separator, then append to home_dir
		rest_of_path := file_path[1:] if len(file_path) > 1 else ""

		if len(rest_of_path) > 0 &&
		   (rest_of_path[0] == '/' || rest_of_path[0] == '\\') {
			rest_of_path = rest_of_path[1:] // Skip the separator
		}

		resolved_path = fmt.tprintf(
			"%s%s%s",
			home_dir,
			filepath.SEPARATOR_STRING,
			rest_of_path,
		)
	}

	return resolved_path
}

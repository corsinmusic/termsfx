package config

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:path/filepath"

UserConfig :: struct {
	commands: []TermCommandConfig,
}

TermCommandConfig :: struct {
	command:       string,
	audioFilePath: string,
}

ReadUserConfigError :: union {
	FileReadFailed,
	ParseFailed,
}
FileReadFailed :: struct {
	file_path: string,
}
ParseFailed :: struct { }

read_user_config :: proc(file_path: string) -> (config: ^UserConfig, err: ReadUserConfigError) {
	resolved_path := resolve_path(file_path)
	config_contents, read_file_success := os.read_entire_file_from_filename(
		resolved_path,
	)

	if !read_file_success {
		return new(UserConfig), FileReadFailed { file_path = resolved_path }
	}
	defer delete(config_contents)

	json_contents, json_parse_err := json.parse(config_contents)
	if json_parse_err != .None {
		return new(UserConfig), ParseFailed {}
	}

	root := json_contents.(json.Object)

	commands: [dynamic]TermCommandConfig
	for c in root["commands"].(json.Array) {
		command := c.(json.Object)["command"].(json.String)
		audioFilePath := c.(json.Object)["audioFilePath"].(json.String)

		append(&commands, TermCommandConfig {
			command = strings.clone(command),
			audioFilePath = strings.clone(audioFilePath),
		})
	}

	user_config := new(UserConfig)
	user_config.commands = commands[:]
	return user_config, nil
}

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

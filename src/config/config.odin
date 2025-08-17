package config

import "core:encoding/json"
import "core:os"
import "core:strings"

import "../utils"

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
ParseFailed :: struct {}

read_user_config :: proc(
	file_path: string,
) -> (
	config: ^UserConfig,
	err: ReadUserConfigError,
) {
	resolved_path := utils.resolve_path(file_path)
	config_contents, read_file_success := os.read_entire_file_from_filename(
		resolved_path,
	)

	if !read_file_success {
		return new(UserConfig), FileReadFailed{file_path = resolved_path}
	}
	defer delete(config_contents)

	json_contents, json_parse_err := json.parse(config_contents)
	if json_parse_err != .None {
		return new(UserConfig), ParseFailed{}
	}

	root := json_contents.(json.Object)

	commands: [dynamic]TermCommandConfig
	for c in root["commands"].(json.Array) {
		command := c.(json.Object)["command"].(json.String)
		audioFilePath := c.(json.Object)["audioFilePath"].(json.String)

		append(
			&commands,
			TermCommandConfig {
				command = strings.clone(command),
				audioFilePath = strings.clone(audioFilePath),
			},
		)
	}

	user_config := new(UserConfig)
	user_config.commands = commands[:]
	return user_config, nil
}

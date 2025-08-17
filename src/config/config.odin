package config

import "core:encoding/json"
import "core:os"
import "core:path/filepath"
import "core:strings"

UserConfig :: struct {
	commands: []TermCommandConfig,
}

TermCommandConfig :: struct {
	command:         string,
	audio_file_path: string,
}

ReadUserConfigError :: union {
	FileReadFailed,
	ParseFailed,
	AudioFilePathInvalid,
}
FileReadFailed :: struct {
	file_path: string,
}
AudioFilePathInvalid :: struct {
	audio_file_path: string,
}
ParseFailed :: struct {}

read_user_config :: proc(
	file_path: string,
) -> (
	^UserConfig,
	ReadUserConfigError,
) {
	config_file_path, ok := filepath.abs(resolve_home_dir(file_path))
	if !ok {
		return new(UserConfig), FileReadFailed{file_path = file_path}
	}

	config_contents, read_file_success := os.read_entire_file_from_filename(
		config_file_path,
	)

	if !read_file_success {
		return new(UserConfig), FileReadFailed{file_path = config_file_path}
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
		audio_file_path := c.(json.Object)["audioFilePath"].(json.String)

		audio_file_path, ok = filepath.abs(
			strings.join({filepath.dir(config_file_path), audio_file_path}, "/"),
		)
		if !ok {
			return new(UserConfig), AudioFilePathInvalid{audio_file_path}
		}

		append(
			&commands,
			TermCommandConfig {
				command = strings.clone(command),
				audio_file_path = strings.clone(audio_file_path),
			},
		)
	}

	user_config := new(UserConfig)
	user_config.commands = commands[:]
	return user_config, nil
}

resolve_home_dir :: proc(path: string) -> string {
	if strings.starts_with(path, "~/") || strings.starts_with(path, "$HOME/") {

		env_home_var := "HOME"
		if os.OS == .Windows {
			env_home_var = "USERPROFILE"
		}

		home_dir := os.get_env("HOME")
		if home_dir == "" {
			return path // Return original path if HOME is not set
		}
		return strings.join({home_dir, path[2:]}, "/")
	}
	return path
}

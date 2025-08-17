package config

import "core:encoding/json"
import "core:os"
import "core:path/filepath"
import "core:strings"
import r "core:text/regex"

UserConfig :: struct {
	is_disabled: bool,
	sounds:      []SoundConfig,
}

SoundConfig :: struct {
	name:            string,
	lookups:         []r.Regular_Expression,
	audio_file_path: string,
	start_offset:    f64,
	duration:        f64,
	is_disabled:     bool,
}

ReadUserConfigError :: union {
	FileReadFailed,
	ParseFailed,
	AudioFileNotFound,
}
FileReadFailed :: struct {
	file_path: string,
}
AudioFileNotFound :: struct {
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

	is_disabled :=
		root["disable"] == nil ? false : root["disable"].(json.Boolean)
	sounds: [dynamic]SoundConfig
	for c in root["sounds"].(json.Array) {
		name := c.(json.Object)["name"].(json.String)
		lookups := c.(json.Object)["lookups"].(json.Array)
		audio_file_path := c.(json.Object)["audioFilePath"].(json.String)
		start_offset :=
			c.(json.Object)["startOffset"] == nil ? 0.0 : c.(json.Object)["startOffset"].(json.Float)
		duration :=
			c.(json.Object)["duration"] == nil ? 0.0 : c.(json.Object)["duration"].(json.Float)
		is_disabled :=
			c.(json.Object)["disable"] == nil ? false : c.(json.Object)["disable"].(json.Boolean)


		lookup_regexes: [dynamic]r.Regular_Expression
		for l in lookups {
			lookup := l.(json.String)
			lookup_regex, regex_create_error := r.create(
				strings.join({"^", lookup, "$"}, ""),
				{.Unicode},
			)
			if regex_create_error != nil {
				continue // Skip this sound if regex creation fails
			}
			append(&lookup_regexes, lookup_regex)
		}

		absolute_audio_file_path, create_absolute_audio_file_path_ok :=
			filepath.abs(
				strings.join({filepath.dir(config_file_path), audio_file_path}, "/"),
			)
		if !create_absolute_audio_file_path_ok {
			return new(UserConfig), AudioFileNotFound{audio_file_path}
		}

		append(
			&sounds,
			SoundConfig {
				name = name,
				lookups = lookup_regexes[:],
				audio_file_path = strings.clone(absolute_audio_file_path),
				start_offset = start_offset,
				duration = duration,
				is_disabled = is_disabled,
			},
		)
	}

	user_config := new(UserConfig)
	user_config.is_disabled = is_disabled
	user_config.sounds = sounds[:]
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

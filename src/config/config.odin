package config

import "core:encoding/json"
import "core:os"
import "core:path/filepath"
import "core:strings"
import r "core:text/regex"

UserConfigSrc :: struct {
	disable: bool,
	items:   []struct {
		disable: bool,
		regexes: []string,
		sounds:  []struct {
			disable:        bool,
			audioFilePath:  string,
			startOffset:    i64,
			duration:       i64,
			chanceModifier: i64,
		},
	},
}

UserConfig :: struct {
	is_disabled: bool,
	items:       []ItemConfig,
}

ItemConfig :: struct {
	is_disabled: bool,
	regexes:     []r.Regular_Expression,
	sounds:      []SoundConfig,
}

SoundConfig :: struct {
	audio_file_path: string,
	start_offset:    i64,
	duration:        i64,
	is_disabled:     bool,
	chance_modifier: i64,
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

	user_config_src := UserConfigSrc{}
	json.unmarshal(config_contents, &user_config_src)

	user_config := new(UserConfig)
	user_config.is_disabled = user_config_src.disable

	items := [dynamic]ItemConfig{}

	for item_src in user_config_src.items {
		item := ItemConfig {
			is_disabled = item_src.disable,
			regexes     = []r.Regular_Expression{},
			sounds      = []SoundConfig{},
		}

		// Compile regexes
		{
			regexes := [dynamic]r.Regular_Expression{}
			for regex in item_src.regexes {
				compiled_regex, regex_create_error := r.create(
					strings.join({"^", regex, "$"}, ""),
					{.Unicode},
				)
				if regex_create_error != nil {
					continue // Skip this regex if creation fails
				}
				append(&regexes, compiled_regex)
			}
			item.regexes = regexes[:]
		}

		// Map sounds
		{
			sounds := [dynamic]SoundConfig{}
			for sound_src in item_src.sounds {
				absolute_audio_file_path, create_absolute_audio_file_path_ok :=
					filepath.abs(
						strings.join(
							{filepath.dir(config_file_path), sound_src.audioFilePath},
							"/",
						),
					)
				if !create_absolute_audio_file_path_ok {
					return new(
						UserConfig,
					), AudioFileNotFound{audio_file_path = sound_src.audioFilePath}
				}

				sound := SoundConfig {
						audio_file_path = absolute_audio_file_path,
						start_offset    = sound_src.startOffset,
						duration        = sound_src.duration,
						is_disabled     = sound_src.disable,
						chance_modifier = sound_src.chanceModifier == 0 ? 1 : sound_src.chanceModifier,
					}
				append(&sounds, sound)
			}
			item.sounds = sounds[:]
		}

		append(&items, item)
	}
	user_config.items = items[:]

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

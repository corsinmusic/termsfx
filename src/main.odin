package main

import "core:fmt"
import "core:os"
import r "core:text/regex"

import "cli"
import "config"
import "player"

// NOTE: if silent, won't print anything to stdout or stderr
is_silent := false

main :: proc() {
	// Parse command line arguments
	cli_args, parse_cli_args_err := cli.parse_cli_args()
	if parse_cli_args_err != nil {
		output(parse_cli_args_err)
		os.exit(1)
	}
	defer free(cli_args)

	is_silent = cli_args.silent

	for arg in cli_args.unknown_args {
		output("Unknown argument:", arg.arg)
	}

	// Read user configuration
	user_config, read_config_err := config.read_user_config(
		cli_args.config_file_path,
	)
	if read_config_err != nil {
		output(read_config_err)
		os.exit(1)
	}
	defer free(user_config)

	// Handle the parsed command
	switch c in cli_args.command {
		case cli.PlayCommand:
			{
				found_sound := false

				for sound in user_config.sounds {
					for lookup in sound.lookups {
						// Check if the regex matches the command lookup
						_, matches := r.match(lookup, c.lookup)
						if matches {
							found_sound = true
							ok, err := player.play_audio(
								{
									audio_file_path = sound.audio_file_path,
									start_offset = sound.start_offset,
									duration = sound.duration,
								},
							)
							if !ok {
								output("Error playing audio:", err)
							}
							break
						}
					}
				}

				if !found_sound {
					output(
						"Warn: sound not found in configuration for given lookup",
						c.lookup,
					)
				}
			}
	}
}

output :: proc(args: ..any) {
	if !is_silent {
		fmt.println(args)
	}
}

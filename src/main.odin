package main

import "core:fmt"
import "core:math/rand"
import "core:os"
import r "core:text/regex"

import "cli"
import "config"
import "player"

// NOTE: if no_output, won't print anything to stdout or stderr
no_output := false

main :: proc() {
	// Parse command line arguments
	cli_args, parse_cli_args_err := cli.parse_cli_args()
	if parse_cli_args_err != nil {
		output(parse_cli_args_err)
		os.exit(1)
	}
	defer free(cli_args)

	no_output = cli_args.no_output

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

	if user_config.is_disabled {
		output("User configuration is disabled. Exiting.")
		os.exit(0)
	}

	// Handle the parsed command
	switch c in cli_args.command {
		case cli.PrintHelp:
			{
				output(c.help_text)
				os.exit(0)
			}
		case cli.PlayCommand:
			{
				found_sound := false

				for item in user_config.items {
					if item.is_disabled {
						continue
					}

					for regex in item.regexes {
						// Check if the regex matches the command lookup
						_, matches := r.match(regex, c.lookup)
						if matches {
							found_sound = true

							chance_modified_indexes: [dynamic]int
							for sound, i in item.sounds {
								if sound.is_disabled {
									continue
								}

								for _ in 0 ..< sound.chance_modifier {
									append(&chance_modified_indexes, i)
								}
							}
							random_index := rand.choice(chance_modified_indexes[:])
							sound := item.sounds[random_index]

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
					outputf(
						"Warn: sound not found in configuration for given lookup '%s'",
						c.lookup,
					)
				}
			}
	}
}

output :: proc(args: ..any) {
	if !no_output {
		fmt.println(..args)
	}
}

outputf :: proc(format: string, args: ..any) {
	if !no_output {
		fmt.printfln(format, ..args)
	}
}

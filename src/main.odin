package main

import "core:fmt"
import "core:os"

import "cli"
import "config"
import "player"


main :: proc() {
	// Parse command line arguments
	cli_args, parse_cli_args_err := cli.parse_cli_args()
	if parse_cli_args_err != nil {
		fmt.println(parse_cli_args_err)
		os.exit(1)
	}

	// Read user configuration
	user_config, read_config_err := config.read_user_config(
		cli_args.config_file_path,
	)
	if read_config_err != nil {
		fmt.println(read_config_err)
		os.exit(1)
	}
	defer free(user_config)

	// Handle the parsed command
	switch v in cli_args.command {
		case cli.PlayCommand:
			{
				for cmd in user_config.commands {
					if cmd.command == v.command {
						ok, err := player.play_audio(cmd.audio_file_path)
						if !ok {
							fmt.println("Error playing audio:", err)
						}
					}
				}
			}
	}
}

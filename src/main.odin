package main

import "core:fmt"
import "core:os"

import "cli"
import "config"


main :: proc() {
	user_config, read_config_err := config.read_user_config(
		"~/.config/termsfx/termsfx.json",
	)
	if read_config_err != nil {
		fmt.println(read_config_err)
		os.exit(1)
	}

	// TODO: remove for production
	fmt.println(user_config)

	cli_command, parse_cli_command_err := cli.parse_cli_command()
	if parse_cli_command_err != nil {
		fmt.println(parse_cli_command_err)
		os.exit(1)
	}

	switch v in cli_command {
		case cli.PlayCommand:
			{
				fmt.println("Playing your command:", v.command)
			}
	}

}

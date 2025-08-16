package main

import "core:os"
import "core:fmt"

import "config"
import "cli"


main :: proc() {
	user_config, read_config_err := config.read_user_config("~/.config/termsfx/termsfx.json")
	if read_config_err != nil {
		fmt.println(read_config_err)
		os.exit(1)
	}

	cli_command, parse_cli_command_err := cli.parse_cli_command()
	if parse_cli_command_err != nil {
		fmt.println(parse_cli_command_err)
		os.exit(1)
	}

	switch v in cli_command {
	case cli.PlayCommand: {
		fmt.println("Playing your command:", v.command)
	}
	}

}


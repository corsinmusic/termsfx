package cli

import "core:os"

DEFAULT_CONFIG_FILE_PATH :: "~/.config/termsfx/termsfx.json"

CliArgs :: struct {
	config_file_path: string,
	command:          CliCommand,
}

CliCommand :: union {
	PlayCommand,
}

PlayCommand :: struct {
	command: string,
}

ParseCliArgsError :: union {
	TooFewArguments,
	UnknownArgument,
}
TooFewArguments :: struct {
	message: string,
}
UnknownArgument :: struct {
	arg: string,
}

parse_cli_args :: proc() -> (^CliArgs, ParseCliArgsError) {
	// Omit the first argument which is the program name
	args := os.args[1:]

	if len(args) <= 0 {
		return nil, TooFewArguments{}
	}

	cli_args := new(CliArgs)

	remaining_args := args[:]
	for len(remaining_args) > 0 {
		current_arg := remaining_args[0]
		remaining_args = remaining_args[1:]

		if current_arg == "--config" || current_arg == "-c" {
			if len(remaining_args) == 0 {
				return nil, TooFewArguments {
					message = "Expected a file path after --config or -c",
				}
			}

			cli_args.config_file_path = remaining_args[0]
			remaining_args = remaining_args[1:]

			continue
		}

		if current_arg == "play" {
			if len(remaining_args) == 0 {
				return nil, TooFewArguments {
					message = "Expected a command after 'play'",
				}
			}

			command := remaining_args[0]
			cli_args.command = PlayCommand {
				command = command,
			}
			remaining_args = remaining_args[1:]

			continue
		}

		return nil, UnknownArgument{current_arg}
	}

	if cli_args.config_file_path == "" {
		cli_args.config_file_path = DEFAULT_CONFIG_FILE_PATH
	}

	return cli_args, nil
}

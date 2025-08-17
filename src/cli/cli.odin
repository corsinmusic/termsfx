package cli

import "core:os"

DEFAULT_CONFIG_FILE_PATH :: "~/.config/termsfx/termsfx.json"

CliArgs :: struct {
	config_file_path: string,
	silent:           bool,
	command:          CliCommand,
	unknown_args:     []UnknownArgument,
}

CliCommand :: union {
	PlayCommand,
}
PlayCommand :: struct {
	lookup: string,
}
UnknownArgument :: struct {
	arg: string,
}

ParseCliArgsError :: union {
	TooFewArguments,
}
TooFewArguments :: struct {
	message: string,
}

parse_cli_args :: proc() -> (^CliArgs, ParseCliArgsError) {
	// Omit the first argument which is the program name
	args := os.args[1:]

	if len(args) <= 0 {
		return nil, TooFewArguments{}
	}

	cli_args := new(CliArgs)
	unknown_args := new([dynamic]UnknownArgument)

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

		if current_arg == "--silent" || current_arg == "-s" {
			cli_args.silent = true
			continue
		}

		if current_arg == "play" {
			if len(remaining_args) == 0 {
				return nil, TooFewArguments {
					message = "Expected a lookup string after 'play'",
				}
			}

			command := remaining_args[0]
			cli_args.command = PlayCommand {
				lookup = command,
			}
			remaining_args = remaining_args[1:]

			continue
		}

		append(unknown_args, UnknownArgument{arg = current_arg})
	}

	if cli_args.config_file_path == "" {
		cli_args.config_file_path = DEFAULT_CONFIG_FILE_PATH
	}

	cli_args.unknown_args = unknown_args[:]

	return cli_args, nil
}

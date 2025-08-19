package cli

import "core:os"

DEFAULT_CONFIG_FILE_PATH :: "~/.config/termsfx/termsfx.jsonc"

CliArgs :: struct {
	config_file_path: string,
	no_output:        bool,
	timing:           bool,
	command:          CliCommand,
	unknown_args:     []UnknownArgument,
}

CliCommand :: union {
	PlayCommand,
	PrintHelp,
	CacheCommand,
}
PlayCommand :: struct {
	lookup: string,
}
PrintHelp :: struct {
	help_text: string,
}
CacheCommand :: union {
	CacheInitCommand,
	CachePurgeCommand,
}
CacheInitCommand :: struct {
	// No additional fields needed for initialization command
}
CachePurgeCommand :: struct {
	// No additional fields needed for purge command
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

	help_command := PrintHelp {
		help_text = `
Usage: termsfx [options] [command]
Options:
	--config, -c <path>   Specify the config file path
	--no-output, -no      Supress output to stdout/stderr
Commands:
	play "<lookup>"       Play a sound based on the lookup string
	help, --help, -h      Show this help message
		`,
	}

	cli_args := new(CliArgs)
	cli_args.command = help_command

	unknown_args := new([dynamic]UnknownArgument)

	remaining_args := args[:]
	for len(remaining_args) > 0 {
		current_arg := remaining_args[0]
		remaining_args = remaining_args[1:]

		if current_arg == "help" ||
		   current_arg == "--help" ||
		   current_arg == "-h" {
			cli_args.command = help_command
			break
		}

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

		if current_arg == "--no-output" || current_arg == "-no" {
			cli_args.no_output = true
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

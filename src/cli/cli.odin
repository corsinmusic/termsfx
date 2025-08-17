package cli

import "core:os"

CliCommand :: union {
	PlayCommand,
}

PlayCommand :: struct {
	command: string,
}

ParseCliCommandError :: union {
	TooFewArguments,
	UnknownCommand,
	UnknownError,
}
TooFewArguments :: distinct string
UnknownCommand :: distinct string
UnknownError :: distinct string

parse_cli_command :: proc(
) -> (
	command: CliCommand,
	err: ParseCliCommandError,
) {
	args := os.args[1:]

	if len(args) <= 0 {
		return nil, TooFewArguments{}
	}

	command_arg := args[0]

	switch command_arg {
		case "play":
			{
				if len(args) < 2 {
					return nil, TooFewArguments{}
				}

				play_command := args[1]

				return PlayCommand{command = play_command}, nil
			}
		case:
			{
				return nil, UnknownCommand{}
			}
	}

	return nil, UnknownError{}
}

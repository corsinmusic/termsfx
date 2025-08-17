# termsfx

Terminal Sound Effects tool to play user configured sounds when user defined regex patterns match a given string.

## Requirements

- Odin compiler

## Installation

1. Clone repository
2. Run `./release` script to build the executable
3. Move the `termsfx` binary to a directory in your PATH or add the `./build/` directory to your PATH\
   You could also add an alias to your shell configuration:
   ```
    alias termsfx='~/path/to/termsfx/build/termsfx'
   ```

## Configuration

### Create config file

```bash
mkdir -p ~/.config/termsfx
touch ~/.config/termsfx/termsfx.json
```

### Example config file

[Schema](https://raw.githubusercontent.com/corsinmusic/termsfx/refs/heads/main/assets/termsfx.schema.json)

```
# Example folder contents
~/.config/termsfx/
  - termsfx.json
  - kill.mp3
  - whoami.wav
  - sl.mp3
  - git/
    - git_push.mp3
    - git_commit.wav

```

```json
// ~/.config/termsfx/termsfx.json
{
  "$schema": "https://raw.githubusercontent.com/corsinmusic/termsfx/refs/heads/main/assets/termsfx.schema.json",
  "disable": false,
  "sounds": [
    {
      "name": "whoami",
      "lookups": ["whoami.*"],
      "audioFilePath": "whoami.wav",
      "startOffset": 100
    },
    {
      "name": "kill",
      "lookups": ["kill\\s.+", "killall\\s.+"],
      "audioFilePath": "kill.mp3"
    },
    {
      "name": "git push",
      "lookups": ["git push.*"],
      "audioFilePath": "git/git_push.mp3"
    },
    {
      "name": "git commit",
      "lookups": ["git commit.*"],
      "audioFilePath": "git/git_commit.wav"
    },
    {
      "name": "sl",
      "lookups": ["sl"],
      "audioFilePath": "sl.mp3",
      "duration": 15000
    }
  ]
}
```

## Usage

```bash
Usage: termsfx [options] [command]
Options:
	--config, -c <path>   Specify the config file path
	--no-output, no       Supress output to stdout/stderr
Commands:
	play "<lookup>"       Play a sound based on the lookup string
	help, --help, -h      Show this help message
```

```bash
termsfx play "git push --force" # Play the sound for the lookup regex "git push.*"
```

### Sending zsh commands to termsfx in the background

```bash
# ~/.zshrc
preexec() {
    # $1 contains the command as typed by the user
    if [[ -n "$1" ]]; then
        # Pass the command to termsfx
        (termsfx --no-output "$1" &) >/dev/null 2>&1
    fi
}
```

```bash
# Typing `git push` in the terminal will now automatically play the sound configured for the lookup regex "git push.*"
git push
```

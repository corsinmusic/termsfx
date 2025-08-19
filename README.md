# termsfx

Tool that plays sounds based on a given string. If the string matches a user defined regex, the corresponding sound will be played.\
This can be used to play sounds for terminal commands, e.g. when you type `git push`,
a sound will be played if you have configured a sound with a regex like `git push.*`.

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
  - kill.mp3
  - npm.mp3
  - sl.mp3
  - termsfx.json
  - whoami.wav
  - git/
    - git_commit.wav
    - git_commit_alternate.mp3
    - git_push.mp3

```

```json
// ~/.config/termsfx/termsfx.json
{
  "$schema": "https://raw.githubusercontent.com/corsinmusic/termsfx/refs/heads/main/assets/termsfx.schema.json",
  "disable": false,
  "globalVolumeModifier": 0.8,
  "items": [
    {
      "regexes": ["npm\\s.*install[\\s]?.*", "npm\\s.*i[\\s]?.*"],
      "sounds": [
        {
          "audioFilePath": "./npm.mp3"
        }
      ]
    },
    {
      "regexes": ["whoami.*"],
      "sounds": [
        {
          "audioFilePath": "./whoami.wav",
          "startOffset": 100,
          "volumeModifier": 0.5
        }
      ]
    },
    {
      "regexes": ["kill\\s.+", "killall\\s.+"],
      "sounds": [
        {
          "audioFilePath": "./kill.mp3"
        }
      ]
    },
    {
      "regexes": ["git push.*"],
      "sounds": [
        {
          "audioFilePath": "./git/git_push.mp3"
        }
      ]
    },
    {
      "regexes": ["git commit.*"],
      "sounds": [
        {
          "audioFilePath": "./git/git_commit.wav",
          "chanceModifier": 2
        },
        {
          "audioFilePath": "./git/git_commit_alternate.mp3",
          "volumeModifier": 2
        }
      ]
    },
    {
      "regexes": ["sl"],
      "sounds": [
        {
          "audioFilePath": "./sl.mp3",
          "duration": 15000
        }
      ]
    }
  ]
}
```

## Usage

```bash
Usage: termsfx [options] [command]
Options:
	--config, -c <path>   Specify the config file path
	--no-output, -no      Supress output to stdout/stderr
Commands:
	play "<lookup>"       Play a sound based on the lookup string
	help, --help, -h      Show this help message
```

Example:

```bash
# Play the sound for the regex "git push.*"
termsfx play "git push --force"
```

### Sending zsh commands to termsfx in the background

```bash
# ~/.zshrc
preexec() {
    # $1 contains the command as typed by the user
    if [[ -n "$1" ]]; then
        # Pass the command to termsfx
        (termsfx --no-output play "$1" &) >/dev/null 2>&1
    fi
}
```

```bash
# Typing `git push` in the terminal will now automatically play the sound
# configured for the regex "git push.*"
git push
```

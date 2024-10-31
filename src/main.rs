#![allow(unused_parens)]

use std::env;

mod audio;
mod config;

fn main() {
    config::create_new_config_if_not_exists();

    let args: Vec<String> = env::args().collect();

    if (args.len() < 2) {
        eprintln!("Usage: termsfx <command>");
        return;
    }

    let command_input = &args[1..].join(" ");

    let config = config::load_config();

    for command_config in config.commands {
        if (command_config.command == *command_input) {
            let audio_file_path = command_config.audio_file_path;
            audio::play_audio(audio_file_path.as_str());
            return;
        }
    }
}

use config::{Config, File};
use regex::Regex;
use serde::Deserialize;
use std::{error::Error, path::PathBuf};

#[derive(Debug, Deserialize)]
struct Settings {
    commands: Vec<SourceCommandConfig>,
}

#[derive(Debug, Deserialize)]
struct SourceCommandConfig {
    command: String,
    audio_file_path: String,
}

pub struct CommandConfig {
    pub regex: Regex,
    pub absolute_audio_file_path: String,
}

pub fn load_and_compile_config(
    config_path: Option<&PathBuf>,
) -> Result<Vec<CommandConfig>, Box<dyn Error>> {
    // Determine the configuration file path
    let default_config_path = dirs::home_dir()
        .expect("Could not find home directory")
        .join(".config")
        .join("termsfx")
        .join("termsfx.toml");

    let config_file_path = config_path.unwrap_or(&default_config_path);

    // Add configuration file
    let config = Config::builder()
        .add_source(File::from(config_file_path.clone()).required(false))
        .build()?;

    let settings: Settings = config.try_deserialize()?;

    // Compile regex patterns
    let compiled = settings
        .commands
        .iter()
        .map(|cmd_conf| {
            let re = Regex::new(&cmd_conf.command)
                .unwrap_or_else(|e| panic!("Invalid regex '{}': {}", cmd_conf.command, e));

            let absolute_audio_file_path = config_file_path
                .parent()
                .unwrap()
                .join(&cmd_conf.audio_file_path)
                .to_string_lossy()
                .to_string();

            CommandConfig {
                regex: re,
                absolute_audio_file_path,
            }
        })
        .collect();

    Ok(compiled)
}

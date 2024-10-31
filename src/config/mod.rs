use indoc::indoc;
use serde::Deserialize;

#[derive(Deserialize)]
pub struct Config {
    pub commands: Vec<CommandConfig>,
}

#[derive(Deserialize)]
pub struct CommandConfig {
    pub command: String,
    pub audio_file_path: String,
}

pub fn load_config() -> Config {
    let config_path = get_config_path();

    let config_str =
        std::fs::read_to_string(config_path.clone()).expect("Could not read config file");
    let config: Config = toml::from_str(&config_str).expect("Could not parse config file");

    Config {
        commands: config
            .commands
            .into_iter()
            .map(|command_config: CommandConfig| {
                let audio_file_path = std::path::PathBuf::from(&command_config.audio_file_path);

                if (audio_file_path.is_absolute()) {
                    return command_config;
                }

                let absolute_audio_file_path = config_path.parent().unwrap().join(&audio_file_path);

                CommandConfig {
                    command: command_config.command.clone(),
                    audio_file_path: absolute_audio_file_path.to_str().unwrap().to_string(),
                }
            })
            .collect(),
    }
}

pub fn create_new_config_if_not_exists() {
    // Check if termsfx.toml exists
    let config_path = get_config_path();

    if !config_path.exists() {
        // Create the directory if it doesn't exist
        std::fs::create_dir_all(config_path.parent().unwrap())
            .expect("Could not create config directory");

        // Create the config file
        let config_contents = indoc! {r#"
            [[commands]]
            command = "git push"
            audio_file_path = "git_push.mp3"
        "#};

        std::fs::write(&config_path, config_contents).expect("Could not write to config file");
    }
}

fn get_config_path() -> std::path::PathBuf {
    dirs::home_dir()
        .unwrap()
        .join(".config")
        .join("termsfx")
        .join("termsfx.toml")
}

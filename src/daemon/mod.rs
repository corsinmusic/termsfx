use std::{
    error::Error,
    fs,
    path::{Path, PathBuf},
    sync::Arc,
};
use tokio::io::AsyncBufReadExt;

use rodio::{OutputStream, Sink};
use tokio::{io::BufReader, net::UnixListener};

use crate::settings::{self, CommandConfig};

pub async fn run(config_path: &Option<PathBuf>) -> Result<(), Box<dyn Error>> {
    // Load and compile configurations
    let config = settings::load_and_compile_config(config_path.as_ref())?;

    // Initialize audio output once
    let (_stream, stream_handle) =
        OutputStream::try_default().expect("Failed to get default output stream");
    let sink = Sink::try_new(&stream_handle).expect("Failed to create audio sink");

    // Use Arc to share the sink between tasks
    let sink = Arc::new(sink);
    let config = Arc::new(config);

    // Set up Unix domain socket
    let socket_path = "/tmp/termsfx.sock";
    // Remove the socket file if it already exists
    if Path::new(&socket_path).exists() {
        std::fs::remove_file(&socket_path)?;
    }
    let listener = UnixListener::bind(&socket_path)?;

    println!("Daemon is running and listening on {}", socket_path);

    loop {
        match listener.accept().await {
            Ok((stream, _)) => {
                let sink = Arc::clone(&sink);
                let config = Arc::clone(&config);

                tokio::spawn(async move {
                    let reader = BufReader::new(stream);
                    let mut lines = reader.lines();

                    while let Ok(Some(line)) = lines.next_line().await {
                        process_command(&line, &config, &sink).await;
                    }
                });
            }
            Err(e) => {
                eprintln!("Failed to accept connection: {}", e);
            }
        }
    }
}

async fn process_command(command: &str, configs: &Vec<CommandConfig>, sink: &Arc<Sink>) {
    for c in configs {
        if c.regex.is_match(command) {
            play_audio(&c.absolute_audio_file_path, sink).await;
            break;
        }
    }
}

async fn play_audio(audio_file: &str, sink: &Arc<Sink>) {
    // Load and decode the audio file
    let file = fs::File::open(audio_file)
        .unwrap_or_else(|_| panic!("Failed to open audio file: {}", audio_file));
    let source =
        rodio::Decoder::new(std::io::BufReader::new(file)).expect("Failed to decode audio file");

    // Append the audio source to the sink
    sink.append(source);
}

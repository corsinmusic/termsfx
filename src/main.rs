#![allow(unused_parens)]

mod cli;
mod client;
mod daemon;
mod settings;

use cli::{Cli, Commands};

#[tokio::main]
async fn main() {
    let cli = Cli::parse();

    match &cli.command {
        Commands::Daemon { config } => {
            if let Err(e) = daemon::run(config).await {
                eprintln!("Error runnig daemon: {:?}", e);
            }
        }
        Commands::Send { command_input } => {
            let cmd = command_input.join(" ");
            if let Err(e) = client::send_command(&cmd).await {
                eprintln!("Error sending command: {:?}", e);
            }
        }
    }
}

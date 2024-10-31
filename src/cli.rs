pub use clap::{Parser, Subcommand};
pub use std::path::PathBuf;

#[derive(Parser)]
#[command(name = "termsfx")]
#[command(about = "Plays audio snippets when specific commands are run in the terminal")]
struct ClapCli {
    #[command(subcommand)]
    pub command: Commands,
}

impl Into<Cli> for ClapCli {
    fn into(self) -> Cli {
        Cli {
            command: self.command,
        }
    }
}

pub struct Cli {
    pub command: Commands,
}

impl Cli {
    pub fn parse() -> Self {
        ClapCli::parse().into()
    }
}

#[derive(Subcommand)]
pub enum Commands {
    /// Start the termsfx daemon
    Daemon {
        /// Optional configuration file path
        #[arg(short, long, value_name = "FILE")]
        config: Option<PathBuf>,
    },
    /// Send a command to the daemon
    Send {
        /// The command to send
        #[arg(value_name = "COMMAND")]
        command_input: Vec<String>,
    },
}

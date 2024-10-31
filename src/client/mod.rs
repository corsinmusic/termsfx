use std::error::Error;

use tokio::{io::AsyncWriteExt, net::UnixStream};

pub async fn send_command(cmd_input: &str) -> Result<(), Box<dyn Error>> {
    // Connect to the Unix socket
    let socket_path = "/tmp/termsfx.sock";
    let mut stream = UnixStream::connect(socket_path).await?;

    // Send the command with a newline
    stream
        .write_all(format!("{}\n", cmd_input).as_bytes())
        .await?;

    Ok(())
}

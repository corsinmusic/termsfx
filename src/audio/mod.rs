pub fn play_audio(audio_file_path: &str) {
    // Initialize audio output
    let (_stream, stream_handle) =
        rodio::OutputStream::try_default().expect("Could not create audio stream");

    let sink = rodio::Sink::try_new(&stream_handle).expect("Could not create audio sink");

    // Load audio file
    let file = std::fs::File::open(audio_file_path)
        .unwrap_or_else(|_| panic!("Could not open audio file: {}", audio_file_path));

    let source =
        rodio::Decoder::new(std::io::BufReader::new(file)).expect("Failed to decode audio file");

    sink.append(source);
    sink.sleep_until_end();
}

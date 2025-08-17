package player

import "core:fmt"
import "core:strings"
import "core:time"
import ma "vendor:miniaudio"

// Configuration constants
AUDIO_CHANNELS :: 0 // 0 means use device's native channel count
AUDIO_SAMPLE_RATE :: 0 // 0 means use device's native sample rate

PlayAudioRequest :: struct {
	audio_file_path: string,
	start_offset:    f64,
	duration:        f64,
}

PlayAudioError :: union {
	FailedToInitializeEngine,
	FailedToStartEngine,
	FailedToInitializeSound,
	FailedToStartSound,
	FailedToSeekSound,
}
FailedToInitializeEngine :: struct {
	message: string,
}
FailedToStartEngine :: struct {
	message: string,
}
FailedToInitializeSound :: struct {
	message: string,
}
FailedToStartSound :: struct {
	message: string,
}
FailedToSeekSound :: struct {
	message: string,
}

play_audio :: proc(
	request: PlayAudioRequest,
) -> (
	ok: bool,
	err: PlayAudioError,
) {
	// Initialize the audio engine
	engine_config := ma.engine_config_init()
	engine_config.channels = AUDIO_CHANNELS
	engine_config.sampleRate = AUDIO_SAMPLE_RATE
	engine_config.listenerCount = 1 // Use one listener for spatial audio (optional)

	engine: ma.engine
	if result := ma.engine_init(&engine_config, &engine); result != .SUCCESS {
		return false, FailedToInitializeEngine {
			message = fmt.tprintf(
				"Failed to initialize miniaudio engine: %v\n",
				result,
			),
		}
	}
	defer ma.engine_uninit(&engine) // Clean up engine when done

	// Start the engine
	result := ma.engine_start(&engine)
	if result != .SUCCESS {
		return false, FailedToStartEngine {
			message = fmt.tprintf("Failed to start miniaudio engine: %v\n", result),
		}
	}

	// Initialize the sound from a file (replace "path/to/audio.mp3" with your file path)
	sound: ma.sound
	flags: bit_set[ma.sound_flag;u32] = {.DECODE}
	result = ma.sound_init_from_file(
		&engine,
		strings.clone_to_cstring(request.audio_file_path),
		flags,
		nil,
		nil,
		&sound,
	)
	if result != .SUCCESS {
		return false, FailedToInitializeSound {
			message = fmt.tprintf(
				"Failed to initialize sound from file '%s': %v\n",
				request.audio_file_path,
				result,
			),
		}
	}
	defer ma.sound_uninit(&sound) // Clean up sound when done

	// Start playing the sound
	result = ma.sound_start(&sound)
	if result != .SUCCESS {
		fmt.eprintf("Failed to start sound: %v\n", result)
		return false, FailedToStartSound {
			message = fmt.tprintf("Failed to start sound: %v\n", result),
		}
	}

	if request.duration > 0 {
		ma.sound_set_stop_time_in_milliseconds(
			&sound,
			u64(request.start_offset + request.duration), // Convert seconds to ms
		) // Convert ms to seconds)
	}

	if request.start_offset > 0 {
		ma.sound_seek_to_second(&sound, f32(request.start_offset * 0.001)) // Convert ms to seconds
	}

	// Wait until the sound finishes playing
	for ma.sound_is_playing(&sound) {
		time.sleep(17 * time.Millisecond) // Poll every 50ms to avoid busy-waiting
	}

	return true, nil
}

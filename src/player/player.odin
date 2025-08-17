package player

import "core:fmt"
import "core:strings"
import "core:time"
import ma "vendor:miniaudio"

// Configuration constants
AUDIO_CHANNELS :: 0 // 0 means use device's native channel count
AUDIO_SAMPLE_RATE :: 0 // 0 means use device's native sample rate

PlayAudioError :: union {
	FailedToInitializeEngine,
	FailedToStartEngine,
	FailedToInitializeSound,
	FailedToStartSound,
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

play_audio :: proc(
	audio_file_path: string,
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
	if result := ma.engine_start(&engine); result != .SUCCESS {
		return false, FailedToStartEngine {
			message = fmt.tprintf("Failed to start miniaudio engine: %v\n", result),
		}
	}

	// Initialize the sound from a file (replace "path/to/audio.mp3" with your file path)
	sound: ma.sound
	flags: bit_set[ma.sound_flag;u32] = {.DECODE}
	if result := ma.sound_init_from_file(
		&engine,
		strings.clone_to_cstring(audio_file_path),
		flags,
		nil,
		nil,
		&sound,
	); result != .SUCCESS {
		return false, FailedToInitializeSound {
			message = fmt.tprintf(
				"Failed to initialize sound from file '%s': %v\n",
				audio_file_path,
				result,
			),
		}
	}
	defer ma.sound_uninit(&sound) // Clean up sound when done

	// Start playing the sound
	if result := ma.sound_start(&sound); result != .SUCCESS {
		fmt.eprintf("Failed to start sound: %v\n", result)
		return false, FailedToStartSound {
			message = fmt.tprintf("Failed to start sound: %v\n", result),
		}
	}

	// Wait until the sound finishes playing
	for !ma.sound_at_end(&sound) {
		time.sleep(100 * time.Millisecond) // Poll every 100ms to avoid busy-waiting
	}

	return true, nil
}

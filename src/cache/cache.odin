package cache

import "core:fmt"
import "core:os"
import "core:path"
import "core:path/filepath"

CACHE_DIR :: "~/.cache/termsfx"

InitCacheError :: union {
	FailedToCreateCacheDir,
}

FailedToCreateCacheDir :: struct {
	message: string,
}

init_cache :: proc() -> InitCacheError {
	// Initialize the cache directory if it does not exist.
	if !os.exists(CACHE_DIR) {
		err := os.make_directory(CACHE_DIR)
		if err != nil {
			return FailedToCreateCacheDir {
				message = fmt.tprintf(
					"Failed to create cache directory '%s': %v",
					CACHE_DIR,
					err,
				),
			}
		}
	}

	return nil
}

PurgeCacheError :: union {
	FailedToDeleteCacheDir,
}

FailedToDeleteCacheDir :: struct {
	message: string,
}

purge_cache :: proc() -> PurgeCacheError {
	err := os.remove(CACHE_DIR)
	if err != nil {
		return FailedToDeleteCacheDir {
			message = fmt.tprintf(
				"Failed to delete cache directory '%s': %v",
				CACHE_DIR,
				err,
			),
		}
	}

	return nil
}

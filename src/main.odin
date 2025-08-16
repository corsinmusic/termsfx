package main

import "core:os"
import "core:fmt"
import "config"


main :: proc() {
	user_config, read_config_err := config.read_user_config("~/.config/termsfx/termsfx.json")

	if read_config_err != nil {
		fmt.println(read_config_err)
		os.exit(1)
	}

	fmt.println(user_config)
}


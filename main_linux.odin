package main

import "linux"

setupSignals :: proc() {
	// 	str := (cast(^u8) uintptr(35251));
	// 	blah := cast(cstring) str;
	
	// Ignore Ctrl+C Interactive Attention Signal
	// and Ctrl+Z Terminal Stop Signal
	linux.signal(linux.SIGINT, linux.SIG_IGN);
	linux.signal(linux.SIGTSTP, linux.SIG_IGN);
	
	linux.signal(linux.SIGQUIT, linux.sighandler_t(terminate));
	linux.signal(linux.SIGTERM, linux.sighandler_t(terminate));
	linux.signal(linux.SIGABRT, linux.sighandler_t(terminate));
	linux.signal(linux.SIGALRM, linux.sighandler_t(terminate));
	linux.signal(linux.SIGVTALRM, linux.sighandler_t(terminate));
	linux.signal(linux.SIGXCPU, linux.sighandler_t(terminate));
	linux.signal(linux.SIGXFSZ, linux.sighandler_t(terminate));
	// TODO: Handle SIGCONT signal? This signal is sent when
	// the process is restarted from being suspended/paused by SIGSTOP or SIGTSTP
	// TODO: Handle SIGFPE so that an erroneous arithmetic operation doesn't terminate the shell?
}

setupUserInfo :: proc(globalData: ^GlobalData) {
	username, username_exists := os.getenv("USER");
	homeDir, homeDir_exists := os.getenv("HOME");
	
	if !homeDir_exists {
		uid := linux.getuid();
		passwd := linux.getpwuid(uid);
		globalData.homeDirectory = string(passwd.pw_dir);
		globalData.username = string(passwd.pw_name);
	} else {
		globalData.homeDirectory = string(homeDir);
		globalData.username = string(username);
	}
}

setupDefaultDirectories :: proc(globalData: ^GlobalData) {
	globalData.executablePath = linux.get_executable_path();
	globalData.executableDir = path.dir(globalData.executablePath);
	
	builder := strings.make_builder(0, len(globalData.executableDir));
	defer strings.destroy_builder(&builder);
	
	strings.write_string(&builder, globalData.executableDir);
	append_to_path(&builder, "tools");
	globalData.toolsFolder = strings.clone(strings.to_string(builder));
	strings.reset_builder(&builder);
	
	strings.write_string(&builder, globalData.executableDir);
	append_to_path(&builder, "wrappers");
	globalData.wrappersFolder = strings.clone(strings.to_string(builder));
	
	hashDirectoryFiles(globalData, globalData.toolsFolder);
	hashDirectoryFiles(globalData, globalData.wrappersFolder);
}

setupEnvironmentVariables :: proc(globalData: ^GlobalData) {
	linux.setenv("USER", globalData.username, true);
	linux.setenv("USERNAME", globalData.username, true);
	linux.setenv("HOME", globalData.homeDirectory, true);
	linux.setenv("SHELL", "paled", true);
	
	// TODO: LOGNAME?
}

hashDirectoryFiles :: proc(globalData: ^GlobalData, directory: string) {
	dp: ^linux.DIR;
	dp_error: os.Errno;
	dirp: ^linux.dirent;
	dirp_error: os.Errno;
	
	dp, dp_error = linux.opendir(directory);
	if (dp == nil) {
		fmt.printf("Error opening directory '%s': %s\n", directory, dp_error);
		terminate(0);
		//ncure.enableEcho();
		//os.exit(1); // TODO
	}
	defer linux.closedir(dp);
	
	path_builder := strings.make_builder();
	defer strings.destroy_builder(&path_builder);
	for {
		defer strings.reset_builder(&path_builder);
		
		dirp, dirp_error = linux.readdir(dp);
		if dirp == nil && dirp_error == os.ERROR_NONE do break;
		else if dirp == nil do continue; // TODO: Print error?
		
		d_name_length := len(cstring(&dirp.d_name[0]));
		d_name_str := string(dirp.d_name[:d_name_length]);
		
		strings.write_string(&path_builder, directory);
		append_to_path(&path_builder, d_name_str);
		path := strings.to_string(path_builder);
		fileInfo, info_err := os.stat(path);
		if info_err != os.ERROR_NONE {
			fmt.printf("Error stating file '%s': %s\n", path, info_err);
			continue;
		}
		
		if os.S_ISREG(cast(u32) fileInfo.mode) || os.S_ISLNK(cast(u32) fileInfo.mode) {
			copy_path := strings.clone(path);
			globalData.path_hash[strings.clone(d_name_str)] = copy_path; // TODO
			//ncure.write_string(ncure.ForegroundColor.Red, ":");
			// 			fmt.println(d_name_str);
		}
	}
	
	// 	fmt.println(globalData.path_hash);
}

append_to_path :: proc(builder: ^strings.Builder, sarr: ..string) {
	for s in sarr {
		if !os.is_path_separator(rune(peek_byte(builder))) do strings.write_rune_builder(builder, linux.get_path_separator());
		// 		if peek_byte(builder) != '/' do strings.write_rune_builder(builder, '/');
		strings.write_string(builder, s);
	}
}

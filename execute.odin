package main

import "linux"
import "ncure"
import "core:strings"
import "core:path/filepath"

is_file :: proc(path: string) -> bool {
	return true;
}

defaultCallProc :: proc(self: ^Call, globalData: ^GlobalData) {
	// 	ncure.printf("%s\n", self^);
	
	// Check if command is in hashtable
	// TODO: command is a slice that can be of multiple tokens
	commandPath, isHashed := globalData.path_hash[self.command[0].str];
	if !isHashed {
		commandPath = self.command[0].str;
		
		// Check that file exists, is a file, and is executable
		exists := is_file(commandPath);
		ncure.println(commandPath);
		if !exists {
			ncure.write_string(ncure.ForegroundColor.Red, "Error: File doesn't exist");
			ncure.newLine();
			return;
		}
	}
	
	amt := 1;
	if self.hasSubcommand || !self.help {
		amt += 1;
	}
	args := make([dynamic]cstring, amt, len(self.params) + amt);
	args[0] = strings.clone_to_cstring(commandPath);
	if self.hasSubcommand do args[1] = strings.clone_to_cstring(self.subcommand[0].str); // TODO
	else if !self.help do args[1] = strings.clone_to_cstring("default");
	
	defer delete(args);
	builder := strings.make_builder();
	for i in 0..<len(self.params) {
		param := &self.params[i];
		if param.name != nil {
			strings.write_string(&builder, param.name.str);
			strings.write_byte(&builder, '=');
			append(&args, strings.clone_to_cstring(strings.to_string(builder)));
			strings.reset_builder(&builder);
		}
		
		valueString, _ := strings.replace_all(param.value.str, "\"", "");
		strings.write_string(&builder, valueString); // TODO
		append(&args, strings.clone_to_cstring(strings.to_string(builder)));
		strings.reset_builder(&builder);
	}
	append(&args, nil);
	
	commandPath_cstr := strings.clone_to_cstring(commandPath);
	defer delete(commandPath_cstr);
	executeProgram(globalData, commandPath_cstr, &args[0]);
}

executeProgram :: proc(globalData: ^GlobalData, path: cstring, args: ^cstring) {
	pid, wpid: linux.pid_t;
	status: int;
	
	if globalData.singleCommandMode {
		pid = 0;
		ncure.enableEcho();
	} else {
		pid = linux.fork();
	}
	
	if pid == 0 {
		// Child process
		// Set terminal stop and interactive attention signals to default
		linux.signal(linux.SIGINT, linux.SIG_DFL);
		linux.signal(linux.SIGTSTP, linux.SIG_DFL);
		// Ignore SIGHUP to allow program to continue
		// running even if the controlling terminal/paled closes.
		// 		linux.signal(linux.SIGHUP, linux.SIG_IGN);
		
		result := linux._unix_execvp(path, args);
		if result == -1 {
			// TODO: Error
		}
	} else if pid < 0 {
		// TODO: Forking error
	} else {
		// Parent - Paled
		for {
			wpid = linux.waitpid(pid, &status, linux.WUNTRACED);
			if linux.WIFEXITED(status) || linux.WIFSIGNALED(status) do break;
		}
	}
}

package main

import "core:fmt"
import "core:os"
import "core:path"
import "core:strings"
import "core:unicode/utf8"
import "core:container"
import "core:runtime"

import "linux"
import "ncure"
import "tokenizer"

NAME :: "Paled";
VERSION :: "0.5";
COPYRIGHT_YEAR :: "2021";
LICENSE :: "MIT";
AUTHOR :: "Christian Lee Seibold";

GlobalData :: struct {
	singleCommandMode: bool,
	running: bool,
	executablePath: string,
	executableDir: string,
	
	username: string,
	homeDirectory: string,
	
	toolsFolder: string,
	wrappersFolder: string,
	
	path_hash: map[string]string,
	shell_vars: map[string]string, // TODO
	
	directoryHistory: [dynamic]string,
	commandHistory: container.Queue(string),
	history_index: int,
	current: string,
}

init_globalData :: proc(globalData: ^GlobalData) {
	globalData.path_hash = make(map[string]string);
	globalData.shell_vars = make(map[string]string); // TODO
	globalData.directoryHistory = make([dynamic]string);
	// 	globalData.commandHistory = make([dynamic]string);
	container.queue_init(&globalData.commandHistory, 0, 5);
	globalData.history_index = 0;
}

add_history :: proc(globalData: ^GlobalData, s: string) {
	if container.queue_len(globalData.commandHistory) >= 200 {
		for i in 0..<(container.queue_len(globalData.commandHistory) - 200) {
			container.queue_pop_front(&globalData.commandHistory);
		}
	}
	
	container.queue_push(&globalData.commandHistory, s);
}

terminate :: proc "c" (signum: int) {
	context = runtime.default_context();
	
	// TODO: Determine if should wait for something to finish or not
	// TODO: Wait for child processes to finish? Or deattach them
	// TODO: Save important state here
	
	// ncure.batch_end();
	ncure.newLine();
	ncure.enableEcho();
	os.exit(0);
}

foo :: cast(^u8) cast(uintptr) 35251;

main :: proc() {
	setupSignals();
	
	globalData: GlobalData;
	
	init_globalData(&globalData);
	setupUserInfo(&globalData);
	setupDefaultDirectories(&globalData);
	setupEnvironmentVariables(&globalData);
	
	for s in os.args {
		if s == "-s" {
			globalData.singleCommandMode = true;
		}
	}
	
	globalData.current = os.get_current_directory();
	linux.setenv("PWD", globalData.current, true); // TODO: Linux; Make functions for getting and setting of PWD and OLDPWD
	// TODO: Set OLDPWD for previous working directory
	
	ncure.disableEcho(false);
	defer ncure.enableEcho();
	// ncure.batch_start();
	{
		// defer ncure.batch_end();
		//ncure.clearScreen();
		//ncure.setCursor_topleft();
		
		// 		ncure.println(typeid_of(type_of(foo)));
		
		printPrompt(&globalData);
	}
	
	// NOTE: Only used for tokenizer
	keywords: tokenizer.Set = transmute(tokenizer.Set) map[string]bool {
		"true" = true,
		"false" = true,
		"sh" = true,
		"bash" = true,
		"nil" = true,
	};
	
	builtins := map[string]BuiltinProc {
		"cd" = BuiltinCd,
		"clear" = BuiltinClear,
		"help" = BuiltinHelp,
		"version" = BuiltinVersion,
		"exit" = BuiltinExit,
		"debug" = BuiltinDebug,
		"getenv" = BuiltinGetenv,
		
		"hash" = BuiltinUnimplemented,
		"tools" = BuiltinUnimplemented,
		"wrappers" = BuiltinUnimplemented,
		"motd" = BuiltinUnimplemented,
		"dhist" = BuiltinUnimplemented,
		
		"sh" = BuiltinUnimplemented,
		"bash" = BuiltinUnimplemented,
		"mksh" = BuiltinUnimplemented,
	};
	
	builtinCalls := map[string]CallProc {
	};
	
	running := true;
	first := true;
	input := strings.make_builder();
	defer strings.destroy_builder(&input);
	for running {
		strings.reset_builder(&input);
		if !first do printPrompt(&globalData);
		else do first = false;
		
		cliInput(&input, &globalData);
		inputString := strings.to_string(input);
		fmt.println("");
		if len(inputString) == 0 do continue;
		
		
		tok := tokenizer.makeTokenizer(inputString, &keywords);
		tokenizer.tokenize(&tok);
		defer tokenizer.destroyTokenizer(&tok);
		// 		tokenizer.printTokens(&tok);
		
		parser: Parser;
		makeParser(&parser, &builtins, &builtinCalls);
		defer destroyParser(&parser);
		error := parseInput(&parser, &tok);
		
		if error != nil {
			#partial switch v in error {
				case ParserError_UnexpectedToken: {
					token := error.(ParserError_UnexpectedToken).tokens[0];
					ncure.printf(ncure.ForegroundColor.Red, "Parsing Error: Unexpected %s '%s'", token.type, token.str);
					ncure.newLine();
				}
			}
			continue;
		}
		
		ncure.newLine();
		
		// Runs statements
		for statement in parser.statements {
			#partial switch v in statement { // TODO
				case Builtin: {
					builtin := statement.(Builtin);
					builtin->p(&globalData);
				}
				case Call: {
					call := statement.(Call);
					call->p(&globalData);
				}
			}
		}
		
		ncure.newLine();
		
		/*fmt.printf("\n");
		fmt.println(inputString);*/
		
		// Add command to history
		// 		append(&globalData.commandHistory, strings.clone(strings.to_string(input)));
		container.queue_push(&globalData.commandHistory, strings.clone(strings.to_string(input)));
		
		if globalData.singleCommandMode do break;
	}
	
	ncure.write_rune('\n');
}

printPrompt :: proc(globalData: ^GlobalData) {
	ncure.setColor(ncure.ForegroundColor.Green);
	ncure.write_string(globalData.username);
	ncure.write_string(": ");
	ncure.write_string(globalData.current);
	ncure.write_string("|> ");
	ncure.resetColors();
}

cliInput :: proc(input: ^strings.Builder, globalData: ^GlobalData) {
	strings.reset_builder(input);
	data: byte;
	for {
		data = ncure.getch();
		
		// 		ncure.batch_start();
		// 		defer ncure.batch_end();
		
		if ncure.Input(data) == ncure.Input.CTRL_C {
			globalData.running = false;
			strings.reset_builder(input);
			break;
		} else if ncure.Input(data) == ncure.Input.BACKSPACE {
			if len(input.buf) <= 0 do continue;
			
			strings.pop_rune(input);
			ncure.backspace();
			continue;
		} else if ncure.Input(data) == ncure.Input.ENTER {
			globalData.history_index = 0;
			break;
		} else if ncure.Input(data) == ncure.Input.CTRL_BACKSPACE {
			if len(input.buf) <= 0 do continue;
			
			// Search for whitespace before cursor
			last_whitespace_index := strings.last_index(string(input.buf[:]), " ");
			rune_count := strings.rune_count(string(input.buf[:]));
			if last_whitespace_index == -1{
				strings.reset_builder(input);
				ncure.backspace(rune_count);
				continue;
			}
			num_to_delete := rune_count - last_whitespace_index;
			ncure.backspace(num_to_delete);
			for i in 0..<num_to_delete {
				strings.pop_rune(input);
			}
			continue;
		} else if ncure.Input(data) == ncure.Input.CTRL_L {
			ncure.clearScreen();
			ncure.setCursor_topleft();
			printPrompt(globalData);
			ncure.write_string(string(input.buf[:]));
			continue;
		} else if ncure.isSpecial(data) {
			data = ncure.getch();
			
			handleHistory :: proc(input: ^strings.Builder, using globalData: ^GlobalData) {
				old_rune_count := strings.rune_count(string(input.buf[:]));
				
				if history_index > 0 && history_index <= container.queue_len(commandHistory) {
					hist_str := container.queue_get(commandHistory, container.queue_len(commandHistory) - (history_index));
					strings.reset_builder(input);
					strings.write_string(input, hist_str);
					ncure.backspace(old_rune_count);
					ncure.write_string(string(input.buf[:]));
				} else if history_index <= 0 {
					strings.reset_builder(input);
					ncure.backspace(old_rune_count);
				}
			}
			
			if data == 0x1D { // Hack for Konsole
				data = ncure.getch();
			}
			if ncure.Input(data) == ncure.Input.UP {
				if globalData.history_index < container.queue_len(globalData.commandHistory) {
					globalData.history_index += 1;
					handleHistory(input, globalData);
				}
			} else if ncure.Input(data) == ncure.Input.DOWN {
				//ncure.write_string("test down");
				if globalData.history_index != 0 {
					globalData.history_index -= 1;
					handleHistory(input, globalData);
				}
			}
			continue;
		} else if data >= 32 && data <= 126 {
			ncure.write_byte(data);
			strings.write_byte(input, data);
		}
	}
}

handlePathsConfigFile :: proc(globalData: ^GlobalData, path: string) {
	contents, ok := os.read_entire_file(path);
	// TODO
}

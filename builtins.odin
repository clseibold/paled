package main

import "core:os"
import "core:container"

import "tokenizer"
import "ncure"
import "linux"

// -- Builtins --

printVersionAndCopyright :: proc() {
	ncure.printf(ncure.ForegroundColor.Blue, "%s (odin) V%s", NAME, VERSION);
	ncure.newLine();
	ncure.printf("Copyright (c) %s %s. %s Licensed.", COPYRIGHT_YEAR, AUTHOR, LICENSE);
	ncure.newLine();
	ncure.newLine();
}

BuiltinVersion :: proc(self: ^Builtin, globalData: ^GlobalData) {
	//ncure.batch_start();
	//defer ncure.batch_end();
	
	printVersionAndCopyright();
}

BuiltinHelp :: proc(self: ^Builtin, globalData: ^GlobalData) {
	// ncure.batch_start();
	// defer ncure.batch_end();
	
	// Version and Copyright
	printVersionAndCopyright();
	
	// Builtins
	ncure.write_line(ncure.ForegroundColor.Blue, "Builtins:");
	ncure.write_line("* tools - prints out list of all programs in tools directory");
	ncure.write_line("* cd - changes current directory");
	ncure.write_line("* motd - prints the message of the day");
	ncure.write_line("* getenv - prints the value of the given environment variable");
	ncure.write_line("* dhist - print the directory history");
	ncure.newLine();
	
	ncure.write_line("* sh");
	ncure.write_line("* builtins");
	ncure.write_line("* clear");
	ncure.write_line("* exit");
	ncure.newLine();
	
	// Syntax
	ncure.write_line(ncure.ForegroundColor.Blue, "Syntax:");
	ncure.write_line("The syntax for calling programs/binaries is much like C");
	ncure.write_line("and other programming languages:");
	ncure.write_line(ncure.ForegroundColor.Cyan, "> list(\".\")");
	ncure.newLine();
	
	ncure.write_line("Some programs support subcommands. The syntax for");
	ncure.write_line("calling a subcommand is:");
	ncure.write_line(ncure.ForegroundColor.Cyan, "> list.dirs(\".\")");
	ncure.newLine();
	
	ncure.write_line("You can see the documentation, including a list of");
	ncure.write_line("subcommands, for a program by typing the name without");
	ncure.write_line("parentheses:");
	ncure.write_line(ncure.ForegroundColor.Cyan, "> list");
	ncure.newLine();
	
	ncure.write_line("Named Parameters and Default Arguments are also");
	ncure.write_line("supported. Notice that list's documentation shows the");
	ncure.write_line("first parameter defaults to \".\" - this parameter is");
	ncure.write_line("optional.");
	ncure.write_line(ncure.ForegroundColor.Cyan, "> list(detail = true)");
	ncure.newLine();
	
	ncure.write_line("Lastly, Builtins do not need to use parentheses:");
	ncure.write_line(ncure.ForegroundColor.Cyan, "> cd ~");
}

BuiltinDebug :: proc(self: ^Builtin, globalData: ^GlobalData) {
	// ncure.batch_start();
	// defer ncure.batch_end();
	
	ncure.printf("History Count: %d", container.queue_len(globalData.commandHistory));
	ncure.newLine();
}

BuiltinExit :: proc(self: ^Builtin, globalData: ^GlobalData) {
	ncure.enableEcho();
	ncure.showCursor();
	os.exit(0);
}

BuiltinClear :: proc(self: ^Builtin, globalData: ^GlobalData) {
	// ncure.batch_start();
	// defer ncure.batch_end();
	
	ncure.clearScreen();
	ncure.setCursor_topleft();
}

BuiltinUnimplemented :: proc(self: ^Builtin, globalData: ^GlobalData) {
	// ncure.batch_start();
	// defer ncure.batch_end();
	
	ncure.write_string("Unimplemented.");
	ncure.newLine();
}

// -- Builtin Calls --




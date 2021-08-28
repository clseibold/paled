# Paled TODO

## August 25, 2020
[ ] Finally fix up and down arrow problems
[ ] Cd builtin command
    [ ] Tokenizer - paths can start with "./", "../", "~/", "~", or "/" on macOS, Linux, and Windows
        or ".\", "..\", "~\", "~", "C:", "\", or "C:\" (or "C:/") for Windows only
[ ] getenv & setenv
[ ] dhist builtin

## August 22, 2020
[x] write_strings
[x] write_at and print_at
[~] ncure example program in Odin
[x] More parsing - Arguments

## Overall
[ ] Ncure - Linux
	[x] General manipulation
	[~] Batch commands
	[x] Enable/disable echo
	[~] Colors
	    [ ] 256 Colors
	    [ ] 32-bit Colors
	[~] Input
		[x] ASCII
		[ ] UTF8

[ ] Directory hashing
	[x] tools/wrappers folders
	[ ] Read paths.pconfig files
	[ ] Reconstruct hashtable on directory changes

[ ] Command Input
	[ ] Line Editor
	    [~] Backspace
	    [~] Delete
	    [ ] Left and Right Keys
	    [ ] Mouse Input?
	    [ ] Command history
	[~] Lexer
		[x] Char
		[x] String
		[x] Ident
		[x] Keyword
		[ ] Path?
		[x] Others: (, ), {, }, ., ;
	[ ] Parser
		[x] Builtins
		[ ] Argument handling
			[ ] Math expressions: +, -, /, *, (), %, ^
		[ ] Paths
		[ ] Subcommand mode
			[ ] Pipes/IPC
	[ ] Execution
		[x] Builtins

[ ] Paled Lib
	[ ] Subcommand
		[ ] Pipes/IPC
	[ ] Argument handling
	[ ] Paths

[ ] Builtins
	[ ] cd
	[ ] hash
	[x] exit
	[~] help
	[x] clear
	[ ] debug
	[ ] lib - load and call into libraries from the command line.
	[ ] dhist
[ ] Tools
	[ ] List
	[ ] Copy
	[ ] Make
	[ ] Move
	[ ] Print
	[ ] Remove
	[ ] Rename
	[ ] Trash
[ ] Wrappers
	[ ] Odin
	[ ] Man
	[ ] Vi
	[ ] Ssh
	[ ] Finger
	[ ] Mail
	[ ] Pijul
	[ ] Go
	[ ] Gcc

[ ] Builtin File Management
    [ ] Copy file(s)
    [ ] Paste file(s) into current dir or specific dir
	[ ] Cut file(s)
	[ ] Clear copied file(s)
	[ ] Directory history (back and forward)
	[ ] Directory stack (push and pop directories)
	[ ] Search files/dirs, ability to go to containing directory quickly
	[ ] Change file/dir properties
	[ ] 'list' command sortby and filtering options?
	[ ] Project directories (named dirs) - start with '~'
[ ] Launching default program for a specified file
    [ ] Text files
    [ ] Source code files - editor or compiler
    [ ] Image files
    [ ] Video files
    [ ] directories?
    [ ] .desktop, executable, appimage, dmg, msi, etc.
[ ] Launch default program for a function
    [ ] A way to specify default programs for these functions
    [ ] editor
    [ ] shell
    [ ] shell script
    [ ] pager
    [ ] webbrowser, gopher browser, gemini browser
    [ ] file browser
    [ ] terminal
    [ ] terminal multiplexer

* max history to 400-450 by default ?
* Possible memory leak - hit just an enter many many times, and eventually the memory jumped - could it be ncure?

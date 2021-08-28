package ncure

// batch_start
// batch_end
// batch
// getTermSize

// getCursor
// getCursor_topleft
// getCursor_topright
// getCursor_bottomleft
// getCursor_bottomright

// hideCursor
// showCursor
// saveCursor
// restoreCursor
// save_restore

// getSequence_set
// getSequence_moveup
// getSequence_movedown
// getSequence_moveleft
// getSequence_moveright

// setCursor
// setCursor_topleft
// setCursor_topright
// setCursor_bottomleft
// setCursor_bottomright
// moveCursor_up
// moveCursor_down
// moveCursor_left
// moveCursor_right
// moveCursor_start
// moveCursor_end

// write_string
// write_strings
// write_line
// write_byte
// write_rune
// print
// println
// printf

// clearScreen
// clearLine
// clearLine_right
// clearLine_left
// backspace

import "core:strings"
import "core:strconv"
import "core:os"
import "core:fmt"
import "core:mem"

import "../linux"

ESC :: "\e";
SEQUENCE_START :: "\e[";
NEWLINE :: "\n";

CLEAR :: "\e[2J";
CLEAR_DOWN :: "\e[J";
CLEAR_UP :: "\e[1J";
CLEAR_LINE :: "\e[2K";
CLEAR_LINE_RIGHT :: "\e[K";
CLEAR_LINE_LEFT :: "\e[1K";

TOP_LEFT :: "\e[1;1H";

GET_CURSOR :: "\e[6n";
HIDE_CURSOR :: "\e[?25l";
SHOW_CURSOR :: "\e[?25h";
SAVE_CURSOR :: "\e7";
RESTORE_CURSOR :: "\e8";

MOVE_UP :: "\e[1A";
MOVE_DOWN :: "\e[1B";
MOVE_LEFT :: "\e[1D";
MOVE_RIGHT :: "\e[1C";

BatchInfo :: struct {
	builder: strings.Builder,
	cursor: CursorPos, // Current cursor position at latest ncure call. NOTE: Doesn't necessarily work properly atm.
	cursor_start: CursorPos, // Cursor position at the start of a batch
	savedCursor: bool,
	savedCursorPos: CursorPos, // NOTE: Doesn't necessarily work atm.
	termSize: TermSize,
}
@private
_batch := false;
@private
_batchInfo: ^BatchInfo = nil; // TODO: Switch to a stack thing so we can have nested Batches

@private
_createBatchInfo :: proc(batchInfo: ^BatchInfo) {
	batchInfo.builder = strings.make_builder();
	batchInfo.cursor = getCursor();
	batchInfo.cursor_start = batchInfo.cursor;
	batchInfo.termSize = getTermSize();
	batchInfo.savedCursor = false;
	_batchInfo = batchInfo;
}

@private
_destroyBatchInfo :: proc(batchInfo: ^BatchInfo) {
	strings.destroy_builder(&batchInfo.builder);
}

batch_start :: proc() -> ^BatchInfo { // TODO
	batchInfo: ^BatchInfo = cast(^BatchInfo) mem.alloc(size_of(BatchInfo));
	_createBatchInfo(batchInfo);
	_batch = true;
	return batchInfo;
}
batch_end :: proc() {
	if _batch != true do return;
	
	os.write_string(os.stdout, strings.to_string(_batchInfo.builder));
	_destroyBatchInfo(_batchInfo);
	_batch = false;
}

// TODO: This isn't thread-safe at all
batch :: proc(p: #type proc(batchInfo: ^BatchInfo, args: ..any), args: ..any) {
	// State for Batch Build: builder, cursor, and termsize
	batchInfo: BatchInfo;
	_createBatchInfo(&batchInfo);
	defer _destroyBatchInfo(&batchInfo);
	_batch = true;
	
	p(&batchInfo, ..args);
	os.write_string(os.stdout, strings.to_string(batchInfo.builder));
	
	_batch = false;
}

getTermSize :: proc() -> (termSize: TermSize) {
	w: linux.winsize;
	if _, err := linux.ioctl(os.stdout, linux.TIOCGWINSZ, &w); err != os.ERROR_NONE {
		// Error
	}
	
	termSize.width = int(w.ws_col);
	termSize.height = int(w.ws_row);
	return termSize;
}

getCursor :: proc() -> CursorPos {
	if _batch do return _batchInfo.cursor;
	
	cursor: CursorPos;
	
	// Disable Echo, send request, then switch terminal
	// back to previous settings
	prev, _ := disableEcho(false);
	os.write_string(os.stdout, GET_CURSOR);
	if set_error := linux.tcsetattr(os.stdin, linux.TCSANOW, &prev); set_error != os.ERROR_NONE {
		fmt.println("Error setting terminal info: %s\n", set_error);
	}
	
	// Get response
	response := strings.make_builder();
	defer strings.destroy_builder(&response);
	data: byte;
	for {
		data = getch();
		
		strings.write_byte(&response, data);
		if data == 'R' do break;
	}
	
	// Parse response
	response_str := strings.to_string(response);
	arg1_start: int;
	arg1_end: int;
	arg2_start: int;
	arg2_end: int;
	for c, i in response_str {
		if c == '[' do arg1_start = i + 1;
		if c == ';' {
			arg1_end = i;
			arg2_start = i + 1;
		}
		if c == 'R' {
			arg2_end = i;
		}
	}
	
	arg1 := response_str[arg1_start:arg1_end];
	arg2 := response_str[arg2_start:arg2_end];
	
	cursor.y = strconv.atoi(arg1);
	cursor.x = strconv.atoi(arg2);
	
	return cursor;
}

getCursor_topleft :: proc() -> CursorPos {
	return CursorPos {1, 1};
}

getCursor_topright :: proc(termSize: ^TermSize = nil) -> CursorPos {
	new_ts: TermSize;
	
	if _batch {
		new_ts = _batchInfo.termSize;
	} else {
		new_ts = getTermSize();
		if termSize != nil do termSize^ = new_ts;
	}
	
	return CursorPos {new_ts.width, 1};
}

getCursor_bottomleft :: proc(termSize: ^TermSize = nil) -> CursorPos {
	new_ts: TermSize;
	
	if _batch {
		new_ts = _batchInfo.termSize;
	} else {
		new_ts = getTermSize();
		if termSize != nil do termSize^ = new_ts;
	}
	
	return CursorPos {1, new_ts.height};
}

getCursor_bottomright :: proc(termSize: ^TermSize = nil) -> CursorPos {
	new_ts: TermSize;
	
	if _batch {
		new_ts = _batchInfo.termSize;
	} else {
		new_ts = getTermSize();
		if termSize != nil do termSize^ = new_ts;
	}
	
	return CursorPos {new_ts.width, new_ts.height};
}

hideCursor :: proc() {
	if _batch {
		strings.write_string(&_batchInfo.builder, HIDE_CURSOR);
	} else {
		os.write_string(os.stdout, HIDE_CURSOR);
	}
}

showCursor :: proc() {
	if _batch {
		strings.write_string(&_batchInfo.builder, SHOW_CURSOR);
	} else {
		os.write_string(os.stdout, SHOW_CURSOR);
	}
}

saveCursor :: proc(overwrite := false) {
	if !overwrite {
		assert(!_batchInfo.savedCursor, "A cursor has already been saved without being restored.");
	}
	
	if _batch {
		strings.write_string(&_batchInfo.builder, SAVE_CURSOR);
		// Set savedCursor so that subsequent commands know when a saved cursor will be overridden
		_batchInfo.savedCursor = true;
		_batchInfo.savedCursorPos = _batchInfo.cursor;
	} else {
		os.write_string(os.stdout, SAVE_CURSOR);
	}
}

restoreCursor :: proc() {
	if _batch {
		strings.write_string(&_batchInfo.builder, RESTORE_CURSOR);
		// Set savedCursor so that subsequent commands know when a saved cursor is being overridden
		_batchInfo.savedCursor = false;
		_batchInfo.cursor = _batchInfo.savedCursorPos;
	} else {
		os.write_string(os.stdout, RESTORE_CURSOR);
	}
}

// TODO: Add option to do something like this in the batching stuff??
save_restore :: proc(cursor: CursorPos, f: #type proc()) {
	saveCursor();
	setCursor(cursor);
	f();
	restoreCursor();
}

getSequence_set :: proc(x, y: int, b: ^strings.Builder = nil) -> string {
	if x == 1 && y == 1 {
		if b != nil {
			strings.write_string(b, TOP_LEFT);
			return strings.to_string(b^);
		}
		return strings.clone(TOP_LEFT);
	}
	
	buf: [129]byte;
	builder_new: strings.Builder;
	builder: ^strings.Builder = b;
	if b == nil {
		// Create new builder for this sequence only if not
		// being added to a pre-existing builder.
		builder_new = strings.make_builder();
		builder = &builder_new;
	}
	
	strings.write_string(builder, SEQUENCE_START);
	
	if y == 1 do strings.write_string(builder, "1;");
	else {
		strings.write_string(builder, strconv.itoa(buf[:], y));
		strings.write_rune_builder(builder, ';');
	}
	
	if x == 1 do strings.write_string(builder, "1H");
	else {
		strings.write_string(builder, strconv.itoa(buf[:], x));
		strings.write_rune_builder(builder, 'H');
	}
	
	return strings.to_string(builder^);
}

getSequence_moveup :: proc(amt: int, b: ^strings.Builder = nil) -> string {
	if amt == 1 {
		if b != nil {
			strings.write_string(b, MOVE_UP);
			return strings.to_string(b^);
		}
		return strings.clone(MOVE_UP);
	}
	
	builder_new: strings.Builder;
	builder: ^strings.Builder = b;
	if b == nil {
		// Create new builder for this sequence only if not
		// being added to a pre-existing builder.
		builder_new = strings.make_builder();
		builder = &builder_new;
	}
	
	strings.write_string(builder, SEQUENCE_START);
	
	buf: [129]byte;
	strings.write_string(builder, strconv.itoa(buf[:], amt));
	strings.write_rune_builder(builder, 'A');
	
	return strings.to_string(builder^);
}

getSequence_movedown :: proc(amt: int, b: ^strings.Builder = nil) -> string {
	if amt == 1 {
		if b != nil {
			strings.write_string(b, MOVE_DOWN);
			return strings.to_string(b^);
		}
		return strings.clone(MOVE_DOWN);
	}
	
	builder_new: strings.Builder;
	builder: ^strings.Builder = b;
	if b == nil {
		// Create new builder for this sequence only if not
		// being added to a pre-existing builder.
		builder_new = strings.make_builder();
		builder = &builder_new;
	}
	
	strings.write_string(builder, SEQUENCE_START);
	
	buf: [129]byte;
	strings.write_string(builder, strconv.itoa(buf[:], amt));
	strings.write_rune_builder(builder, 'B');
	
	return strings.to_string(builder^);
}

getSequence_moveleft :: proc(amt: int, b: ^strings.Builder = nil) -> string {
	if amt == 1 {
		if b != nil {
			strings.write_string(b, MOVE_LEFT);
			return strings.to_string(b^);
		}
		return strings.clone(MOVE_LEFT);
	}
	
	builder_new: strings.Builder;
	builder: ^strings.Builder = b;
	if b == nil {
		// Create new builder for this sequence only if not
		// being added to a pre-existing builder.
		builder_new = strings.make_builder();
		builder = &builder_new;
	}
	
	strings.write_string(builder, SEQUENCE_START);
	
	buf: [129]byte;
	strings.write_string(builder, strconv.itoa(buf[:], amt));
	strings.write_rune_builder(builder, 'D');
	
	return strings.to_string(builder^);
}

getSequence_moveright :: proc(amt: int, b: ^strings.Builder = nil) -> string {
	if amt == 1 {
		if b != nil {
			strings.write_string(b, MOVE_RIGHT);
			return strings.to_string(b^);
		}
		return strings.clone(MOVE_RIGHT);
	}
	
	builder_new: strings.Builder;
	builder: ^strings.Builder = b;
	if b == nil {
		// Create new builder for this sequence only if not
		// being added to a pre-existing builder.
		builder_new = strings.make_builder();
		builder = &builder_new;
	}
	
	strings.write_string(builder, SEQUENCE_START);
	
	buf: [129]byte;
	strings.write_string(builder, strconv.itoa(buf[:], amt));
	strings.write_rune_builder(builder, 'C');
	
	return strings.to_string(builder^);
}

setCursor_xy :: proc(x, y: int, cursor: ^CursorPos = nil, savePrev := false) {
	str: string;
	defer delete(str);
	
	if savePrev {
		saveCursor();
	}
	
	if _batch {
		str := getSequence_set(x, y, &_batchInfo.builder);
		_batchInfo.cursor.x = x;
		_batchInfo.cursor.y = y;
	} else {
		str := getSequence_set(x, y);
		defer delete(str);
		os.write_string(os.stdout, str);
	}
	
	if cursor != nil {
		cursor.x = x;
		cursor.y = y;
	}
}
setCursor_cursor :: proc(cursor: CursorPos, savePrev := false) {
	setCursor_xy(x = cursor.x, y = cursor.y, savePrev = savePrev);
}
setCursor :: proc{setCursor_xy, setCursor_cursor};

setCursor_topleft :: proc(cursor: ^CursorPos = nil, savePrev := false) {
	if savePrev {
		saveCursor();
	}
	
	if _batch {
		strings.write_string(&_batchInfo.builder, TOP_LEFT);
		_batchInfo.cursor.x = 1;
		_batchInfo.cursor.y = 1;
	} else {
		os.write_string(os.stdout, TOP_LEFT);
	}
	
	if cursor != nil {
		cursor.x = 1;
		cursor.y = 1;
	}
}

setCursor_topright :: proc(termSize: ^TermSize = nil, cursor: ^CursorPos = nil, savePrev := false) {
	if savePrev {
		saveCursor();
	}
	
	c := getCursor_topright(termSize);
	setCursor(c);
	if cursor != nil do cursor^ = c;
}

setCursor_bottomleft :: proc(termSize: ^TermSize = nil, cursor: ^CursorPos = nil, savePrev := false) {
	if savePrev {
		saveCursor();
	}
	
	c := getCursor_bottomleft(termSize);
	setCursor(c);
	if cursor != nil do cursor^ = c;
}

setCursor_bottomright :: proc(termSize: ^TermSize = nil, cursor: ^CursorPos = nil, savePrev := false) {
	if savePrev {
		saveCursor();
	}
	
	c := getCursor_bottomright(termSize);
	setCursor(c);
	if cursor != nil do cursor^ = c;
}

// TODO: Add optional cursor argument to be set
moveCursor_up :: proc(amt: int = 1) {
	if _batch {
		str := getSequence_moveup(amt, &_batchInfo.builder);
		_batchInfo.cursor.y -= amt;
	} else {
		str := getSequence_moveup(amt);
		defer delete(str);
		os.write_string(os.stdout, str);
	}
}

moveCursor_down :: proc(amt: int = 1) {
	if _batch {
		str := getSequence_movedown(amt, &_batchInfo.builder);
		_batchInfo.cursor.y += amt;
	} else {
		str := getSequence_movedown(amt);
		defer delete(str);
		os.write_string(os.stdout, str);
	}
}

moveCursor_left :: proc(amt: int = 1) {
	if _batch {
		str := getSequence_moveleft(amt, &_batchInfo.builder);
		_batchInfo.cursor.x -= amt;
	} else {
		str := getSequence_moveleft(amt);
		defer delete(str);
		os.write_string(os.stdout, str);
	}
}

moveCursor_right :: proc(amt: int = 1) {
	if _batch {
		str := getSequence_moveright(amt, &_batchInfo.builder);
		_batchInfo.cursor.x += amt;
	} else {
		str := getSequence_moveright(amt);
		defer delete(str);
		os.write_string(os.stdout, str);
	}
}

moveCursor_start :: proc() {
	if _batch {
		strings.write_byte(&_batchInfo.builder, '\r');
		_batchInfo.cursor.x = 1;
	} else {
		os.write_byte(os.stdout, '\r');
	}
}

moveCursor_end :: proc(termSize: ^TermSize = nil) {
	new_ts: TermSize;
	moveCursor_start();
	if _batch {
		new_ts = _batchInfo.termSize;
		getSequence_moveright(new_ts.width, &_batchInfo.builder);
		_batchInfo.cursor.x = new_ts.width;
	} else {
		new_ts = getTermSize();
		if termSize != nil do termSize^ = new_ts;
		str := getSequence_moveright(new_ts.width);
		os.write_string(os.stdout, str);
	}
}

// TODO: The write and print functions don't change the cursor position correctly
// due to needing to scan the string for escape sequences, new lines, \b,
// non-printable characters, and combinational utf-8 characters
write_string_nocolor :: proc(s: string) {
	if _batch {
		strings.write_string(&_batchInfo.builder, s);
		_batchInfo.cursor.x += len(s); // TODO: This would not work with \b, non-printable chars, and escape sequences within the string
	} else {
		os.write_string(os.stdout, s);
	}
}

write_string_at_nocolor :: proc(cursor: CursorPos, s: string) {
	saveCursor();
	setCursor(cursor);
	write_string_nocolor(s);
	restoreCursor();
}

write_string_color :: proc(fg: ForegroundColor, s: string) {
	setColor(fg);
	if _batch {
		strings.write_string(&_batchInfo.builder, s);
		_batchInfo.cursor.x += len(s); // TODO: This would not work with \b, non-printable chars, and escape sequences within the string
	} else {
		os.write_string(os.stdout, s);
	}
	resetColors();
}

write_string_at_color :: proc(cursor: CursorPos, fg: ForegroundColor, s: string) {
	saveCursor();
	setCursor(cursor);
	write_string_color(fg, s);
	restoreCursor();
}

write_string :: proc{write_string_nocolor, write_string_color, write_string_at_nocolor, write_string_at_color};
// TODO: write_strings functions with ..string arg, but doesn't use print/printf/println

write_strings_nocolor :: proc(args: ..string) {
	for s in args {
		write_string(s);
	}
}

write_strings_at_nocolor :: proc(cursor: CursorPos, args: ..string) {
	saveCursor();
	setCursor(cursor);
	write_strings_nocolor(..args);
	restoreCursor();
}

write_strings_color :: proc(fg: ForegroundColor, args: ..string) {
	for s in args {
		write_string(fg, s);
	}
}

write_strings_at_color :: proc(cursor: CursorPos, fg: ForegroundColor, args: ..string) {
	saveCursor();
	setCursor(cursor);
	write_strings_color(fg, ..args);
	restoreCursor();
}

write_strings :: proc{write_strings_nocolor, write_strings_color, write_strings_at_nocolor, write_strings_at_color};

write_line_nocolor :: proc(s: string) {
	if _batch {
		strings.write_string(&_batchInfo.builder, s);
	} else {
		os.write_string(os.stdout, s);
	}
	newLine();
}

write_line_at_nocolor :: proc(cursor: CursorPos, s: string) {
	saveCursor();
	setCursor(cursor);
	write_line_nocolor(s);
	restoreCursor();
}

write_line_color :: proc(fg: ForegroundColor, s: string) {
	setColor(fg);
	if _batch {
		strings.write_string(&_batchInfo.builder, s);
	} else {
		os.write_string(os.stdout, s);
	}
	resetColors();
	newLine();
}

write_line_at_color :: proc(cursor: CursorPos, fg: ForegroundColor, s: string) {
	saveCursor();
	setCursor(cursor);
	write_line_color(fg, s);
	restoreCursor();
}

write_line :: proc{write_line_nocolor, write_line_color, write_line_at_nocolor, write_line_at_color};

write_byte_current :: proc(b: byte) {
	if _batch {
		strings.write_byte(&_batchInfo.builder, b);
		_batchInfo.cursor.x += 1;
	} else {
		os.write_byte(os.stdout, b);
	}
}

write_byte_at :: proc(cursor: CursorPos, b: byte) {
	saveCursor();
	setCursor(cursor);
	write_byte_current(b);
	restoreCursor();
}

write_byte :: proc{write_byte_current, write_byte_at};

write_rune_current :: proc(r: rune) {
	if _batch {
		strings.write_rune_builder(&_batchInfo.builder, r);
		_batchInfo.cursor.x += 1; // TODO: non-printable/combinational rune
	} else {
		os.write_rune(os.stdout, r);
	}
}

write_rune_at :: proc(cursor: CursorPos, r: rune) {
	saveCursor();
	setCursor(cursor);
	write_rune_current(r);
	restoreCursor();
}

write_rune :: proc{write_rune_current, write_rune_at};

// TODO: Not sure how to handle separator
print_nocolor :: proc(args: ..any, sep := " ") {
	if _batch {
		fmt.sbprint(&_batchInfo.builder, ..args);
	} else {
		fmt.print(..args);
	}
}

print_at_nocolor :: proc(cursor: CursorPos, args: ..any, sep := " ") {
	saveCursor();
	setCursor(cursor);
	print_nocolor(..args);
	restoreCursor();
}

print_color :: proc(fg: ForegroundColor, args: ..any, sep := " ") {
	setColor(fg);
	if _batch {
		fmt.sbprint(&_batchInfo.builder, ..args);
	} else {
		fmt.print(..args);
	}
	resetColors();
}

print_at_color :: proc(cursor: CursorPos, fg: ForegroundColor, args: ..any, sep := " ") {
	saveCursor();
	setCursor(cursor);
	print_color(fg, ..args);
	restoreCursor();
}

print :: proc{print_nocolor, print_color, print_at_nocolor, print_at_color};

println_nocolor :: proc(args: ..any, sep := " ") {
	if _batch {
		fmt.sbprintln(&_batchInfo.builder, ..args);
		_batchInfo.cursor.y += 1; // For the last newline
	} else {
		fmt.println(..args);
	}
}

println_at_nocolor :: proc(cursor: CursorPos, args: ..any, sep := " ") {
	saveCursor();
	setCursor(cursor);
	println_nocolor(..args);
	restoreCursor();
}

println_color :: proc(fg: ForegroundColor, args: ..any, sep := " ") {
	setColor(fg);
	if _batch {
		fmt.sbprintln(&_batchInfo.builder, ..args);
		_batchInfo.cursor.y += 1; // For the last newline
	} else {
		fmt.println(..args);
	}
	resetColors();
}

println_at_color :: proc(cursor: CursorPos, fg: ForegroundColor, args: ..any, sep := " ") {
	saveCursor();
	setCursor(cursor);
	println_color(fg, ..args);
	restoreCursor();
}

println :: proc{println_nocolor, println_color, println_at_nocolor, println_at_color};

printf_nocolor :: proc(format: string, args: ..any) {
	if _batch {
		fmt.sbprintf(&_batchInfo.builder, format, ..args);
	} else {
		fmt.printf(format, ..args);
	}
}

printf_at_nocolor :: proc(cursor: CursorPos, format: string, args: ..any) {
	saveCursor();
	setCursor(cursor);
	printf_nocolor(format, ..args);
	restoreCursor();
}

printf_color :: proc(fg: ForegroundColor, format: string, args: ..any) {
	setColor(fg);
	if _batch {
		fmt.sbprintf(&_batchInfo.builder, format, ..args);
	} else {
		fmt.printf(format, ..args);
	}
	resetColors();
}

printf_at_color :: proc(cursor: CursorPos, fg: ForegroundColor, format: string, args: ..any) {
	saveCursor();
	setCursor(cursor);
	printf_color(fg, format, ..args);
	restoreCursor();
}

printf :: proc{printf_nocolor, printf_color, printf_at_nocolor, printf_at_color};

newLine :: proc(amt: int = 1) {
	if _batch {
		for i in 0..<amt {
			strings.write_string(&_batchInfo.builder, NEWLINE);
		}
		_batchInfo.cursor.x = 1;
		_batchInfo.cursor.y += amt;
	} else {
		for i in 0..<amt {
			os.write_string(os.stdout, NEWLINE);
		}
	}
}

clearScreen :: proc() {
	if _batch {
		// Clearing the screen with erase everything before it.
		// Therefore, we can reset everything that was already in
		// the string builder
		strings.reset_builder(&_batchInfo.builder);
		strings.write_string(&_batchInfo.builder, CLEAR);
	} else {
		os.write_string(os.stdout, CLEAR);
	}
}

clearLine :: proc() {
	if _batch {
		strings.write_string(&_batchInfo.builder, CLEAR_LINE);
	} else {
		os.write_string(os.stdout, CLEAR_LINE);
	}
}

clearLine_right :: proc() {
	if _batch {
		strings.write_string(&_batchInfo.builder, CLEAR_LINE_RIGHT);
	} else {
		os.write_string(os.stdout, CLEAR_LINE_RIGHT);
	}
}

clearLine_left :: proc() {
	if _batch {
		strings.write_string(&_batchInfo.builder, CLEAR_LINE_LEFT);
	} else {
		os.write_string(os.stdout, CLEAR_LINE_LEFT);
	}
}

backspace :: proc(amt := 1, clear := true) {
	if amt == 0 do return;
	if _batch {
		// TODO: This doesn't handle escape sequences, non-printable characters, or combinational characters
		// TODO: Problem - doing a backspace after a backspace that has added escape sequences will result
		// in the deletion of some of the previous backspace, potentially.
		/*for i in 0..<min(amt, strings.builder_len(_batchInfo.builder)) {
			strings.pop_rune(&_batchInfo.builder);
		}*/
		
		// If trying to backspace more than what was buffered, then
		// just add new escape sequences to the buffer to do this.
		// 		diff := amt - strings.builder_len(_batchInfo.builder);
		diff := amt;
		if (diff > 0) {
			moveCursor_left(diff);
			if clear do clearLine_right();
			else {
				for i in 0..<diff {
					os.write_string(os.stdout, " ");
				}
				moveCursor_left(diff);
			}
		}
	} else {
		moveCursor_left(amt);
		if clear do clearLine_right();
		else {
			for i in 0..<amt {
				os.write_string(os.stdout, " ");
			}
			moveCursor_left(amt);
		}
	}
}


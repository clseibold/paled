package main

import ncure ".."
import "core:strconv"
import "core:time"

main :: proc() {
	ncure.disableEcho(false);
	defer ncure.enableEcho();

	itoa_buf: [129]byte;
	termSize := ncure.getTermSize();

	ncure.batch_start();
	{
		ncure.clearScreen();
		ncure.setCursor_topleft();
		ncure.write_strings(ncure.ForegroundColor.Magenta, "Current Terminal Size: (", strconv.itoa(itoa_buf[:], termSize.width), ", ", strconv.itoa(itoa_buf[:], termSize.height), ")");

		ncure.setCursor_topright();
		str_topRight := "Hello!";
		ncure.moveCursor_left(len(str_topRight));
		ncure.write_string(str_topRight);

		ncure.setCursor(5, 4);
		ncure.write_string(ncure.ForegroundColor.Cyan, "Set cursor to (5, 4)");
		ncure.moveCursor_down();
		ncure.moveCursor_right(2);
		ncure.write_string(ncure.ForegroundColor.Red, "Gone down one and right two!");
		ncure.moveCursor_up(2);
		ncure.write_string(ncure.ForegroundColor.Red, "Gone up two lines!");
		ncure.moveCursor_down(3);
		ncure.moveCursor_start();
		ncure.write_string(ncure.ForegroundColor.Green, "Down 3 and Back at start!");

		ncure.moveCursor_down();
	}
	ncure.batch_end();

	pos := ncure.getCursor();
	ncure.batch_start();
	{
		ncure.write_strings(ncure.ForegroundColor.Blue, "Cursor pos at start of this text: (", strconv.itoa(itoa_buf[:], pos.x), ", ", strconv.itoa(itoa_buf[:], pos.y), ")");
		ncure.newLine();

		ncure.moveCursor_end();
		ncure.write_string("Cursor moved to end of line. Blahhhhh");
		ncure.moveCursor_left(8);
		ncure.clearLine_right();
		ncure.newLine();
		ncure.write_rune('x');
		ncure.newLine();
	}
	ncure.batch_end();

	pos = ncure.getCursor();
	ncure.batch_start();
	{
		ncure.setCursor_bottomleft();
		ncure.write_string("Testing bottom left");
		ncure.setCursor_bottomright();
		str_bottomRight := "Testing bottom right";
		ncure.moveCursor_left(len(str_bottomRight));
		ncure.write_string(str_bottomRight);

		ncure.setCursor(pos);

		ncure.write_string(ncure.ForegroundColor.Green, "Going back to saved cursor position");
		ncure.newLine();
	}
	ncure.batch_end();

	// Progress bar test
	termSize = ncure.getTermSize();
	division := 10;
	ncure.batch_start();
	{
		ncure.hideCursor();
		ncure.moveCursor_right((termSize.width / division) + 1);
		ncure.write_byte('|');
		ncure.moveCursor_start();
		ncure.write_byte('|');
	}
	ncure.batch_end();

	for i in 0..<(termSize.width / division) {
		ncure.write_string(ncure.ForegroundColor.Cyan, "=");

		time.sleep(1 * time.Second);
	}
	ncure.newLine();


	// Progress bar test 2
	// with clearLine and write_byte_at
	ncure.moveCursor_right((termSize.width / division) + 1);
	rightPos := ncure.getCursor();
	startPos := ncure.CursorPos { 1, rightPos.y };
	ncure.batch_start();
	{
		ncure.write_byte('|');
		ncure.moveCursor_start();
		ncure.write_byte('|');
	}
	ncure.batch_end();

	for i in 0..<(termSize.width / division) {
		ncure.batch_start();

		ncure.clearLine();

		// Redraw bounds
		ncure.write_byte_at(rightPos, '|');
		ncure.write_byte_at(startPos, '|');

		ncure.write_string(ncure.ForegroundColor.Cyan, "=");

		ncure.batch_end();
		time.sleep(1 * time.Second);
	}
	ncure.newLine();

	ncure.showCursor();
}

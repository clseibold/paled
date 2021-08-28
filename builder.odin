package main

import "core:strings"
import "core:unicode/utf8"

peek_byte :: proc(b: ^strings.Builder) -> (r: byte) {
	if len(b.buf) == 0 {
		return 0;
	}
	r = b.buf[len(b.buf) - 1];
	return;
}

peek_rune :: proc(b: ^strings.Builder) -> (r: rune, width: int) {
	r, width = utf8.decode_last_rune(b.buf[:]);
	return;
}


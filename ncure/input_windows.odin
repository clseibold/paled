package ncure

Input :: enum u8 {
	CTRL_C = 3,
	CTRL_L = 12,
	CTRL_O = 15,
	CTRL_X = 24,
	ESC = 27,

	SPECIAL1 = -32, // TODO
	SPECIAL2 = 224
}

isSpecial :: proc(c: byte) -> bool {
	if c == SPECIAL1 || c == SPECIAL2 {
		return true;
	}

	return false;
}


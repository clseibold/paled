package ncure

import "core:os"
import "core:strings"
import "core:strconv"

RESET_COLORS :: "\e[0m"; // TODO: \e[39;49m

setColor_foreground :: proc(fg: ForegroundColor) {
	new_builder: strings.Builder;
	b: ^strings.Builder;
	if _batch {
		b = &_batchInfo.builder;
	} else {
		new_builder = strings.make_builder(0, len(SEQUENCE_START));
		b = &new_builder;
	}
	
	strings.write_string(b, SEQUENCE_START); // ESC[
	buf: [129]byte;
	strings.write_string(b, strconv.itoa(buf[:], int(fg)));
	strings.write_rune_builder(b, 'm');
	
	if !_batch {
		os.write_string(os.stdout, strings.to_string(b^));
		strings.destroy_builder(b);
	}
}

setColor_background :: proc(bg: BackgroundColor) {
	new_builder: strings.Builder;
	b: ^strings.Builder;
	if _batch {
		b = &_batchInfo.builder;
	} else {
		new_builder = strings.make_builder(0, len(SEQUENCE_START));
		b = &new_builder;
	}
	
	strings.write_string(b, SEQUENCE_START); // ESC[
	buf: [129]byte;
	strings.write_string(b, strconv.itoa(buf[:], int(bg)));
	strings.write_rune_builder(b, 'm');
	
	if !_batch {
		os.write_string(os.stdout, strings.to_string(b^));
		strings.destroy_builder(b);
	}
}

setColor_fg_bg :: proc(fg: ForegroundColor, bg: BackgroundColor) {
	new_builder: strings.Builder;
	b: ^strings.Builder;
	if _batch {
		b = &_batchInfo.builder;
	} else {
		new_builder = strings.make_builder(0, len(SEQUENCE_START));
		b = &new_builder;
	}
	
	strings.write_string(b, SEQUENCE_START); // ESC[
	buf: [129]byte;
	strings.write_string(b, strconv.itoa(buf[:], int(fg)));
	strings.write_rune_builder(b, ';');
	strings.write_string(b, strconv.itoa(buf[:], int(bg)));
	strings.write_rune_builder(b, 'm');
	
	if !_batch {
		os.write_string(os.stdout, strings.to_string(b^));
		strings.destroy_builder(b);
	}
}

setColor :: proc{setColor_foreground, setColor_background, setColor_fg_bg};

resetColors :: proc() {
	if _batch {
		strings.write_string(&_batchInfo.builder, RESET_COLORS);
	} else {
		os.write_string(os.stdout, RESET_COLORS);
	}
}


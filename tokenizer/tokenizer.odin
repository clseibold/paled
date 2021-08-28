package tokenizer

import "core:fmt"
import "core:strings"
import "core:unicode/utf8"

Set :: distinct map[string]bool;

// TODO: Use an arena allocator
Tokenizer :: struct {
	source: string,
	keywords: ^Set,
	ident_allowWhitespace: bool,

	tokenContext: TokenizerContext,
	line, col: int,
	newLine: bool, // TODO
	backslashEscape: bool, // TODO
	quoted: bool,

	currentIndex: int,
	currentRune: rune,
	currentRuneSize: int,

	tokenStart: int,

	tokens: [dynamic]Token,
}

TokenizerContext :: enum u8 {
	None,
	Number,
	Identifier,
	QuotedIdentifier,
	Char,
	String,
	RawString,
}

TokenType :: enum u16 {
	// 0 - 255 are the ascii characters
	Null = 0,
	HorizontalTab = 9,
	ESC = 27,
	Exclamation = 33,
	Hash = 35,
	DollarSign = 36,
	Percent = 37,
	Ampersand = 38,
	LeftParen = 40,
	RightParen = 41,
	Astrisk = 42,
	Plus = 43,
	Comma = 44,
	Dash = 45,
	Dot = 46,
	Slash = 47,
	Colon = 58,
	Semicolon = 59,
	LessThan = 60,
	Equal = 61,
	GreaterThan = 62,
	QuestionMark = 63,
	At = 64,
	LeftBracket = 91,
	Backslash = 92,
	RightBracket = 93,
	Hat = 94, // ^
	Unerscore = 95,
	Backtick = 96, // `
	LeftCurlyBracket = 123,
	VerticalBar = 124, // |
	RightCurlyBracket = 125,

	Whitespace = 256,
	Identifier,
	QuotedIdentifier,
	Keyword,
	Number,
	String,
	RawString,
	Char,
	End,
}

Token :: struct {
	type: TokenType,
	str: string,
	line, col: int,
}

makeToken :: proc(type: TokenType, str: string, line, col: int) -> Token {
	token: Token;
	token.type = type;
	token.str = str;
	token.line = line;
	token.col = col - len(str) + 1;

	return token;
}

makeTokenizer :: proc(source: string, keywords: ^Set, ident_allowWhitespace: bool = false) -> Tokenizer {
	tokenizer: Tokenizer;
	tokenizer.tokenContext = TokenizerContext.None;
	tokenizer.source = source;
	tokenizer.line = 1;
	tokenizer.col = 0;
	tokenizer.tokens = make([dynamic]Token, 0);
	tokenizer.keywords = keywords;
	tokenizer.ident_allowWhitespace = ident_allowWhitespace;

	return tokenizer;
}

destroyTokenizer :: proc(tok: ^Tokenizer) {
	delete(tok.tokens);
}

is_newline :: proc(r: rune) -> bool {
	switch r {
		case '\n', '\r': return true;
		case: return false;
	}
}

// -----

tokenize :: proc(tok: ^Tokenizer) {
	newLine: bool = false;
	for r, i in tok.source {
		tok.currentIndex = i;
		tok.currentRune = r;
		tok.currentRuneSize = utf8.rune_size(r);

		if is_newline(r) && !newLine {
			tok.line += 1;
			tok.col = 0;
			newLine = true;
			continue;
		} else {
			tok.col += 1;
			newLine = false;
		}

		switch tok.tokenContext {
			case .None: handleNone(tok);
			case .Number: handleNumber(tok);
			case .Identifier: handleIdentifier(tok);
			case .QuotedIdentifier: handleIdentifier(tok, true);
			case .Char: handleChar(tok);
			case .String: handleString(tok, false);
			case .RawString: handleString(tok, true);
		}
	}

	// End of file/input
	tok.currentIndex += 1;
	tok.currentRune = '\x00';
	tok.currentRuneSize = 1;

	switch tok.tokenContext {
		case .None: handleNone(tok);
		case .Number: handleNumber(tok);
		case .Identifier: handleIdentifier(tok);
		case .QuotedIdentifier: handleIdentifier(tok, true);
		case .Char: handleChar(tok);
		case .String: handleString(tok, false);
		case .RawString: handleString(tok, true);
	}

	// End token
	endToken := makeToken(TokenType.End, tok.source[tok.currentIndex:], tok.line, tok.col);
	append(&tok.tokens, endToken);
}

printTokens :: proc(tok: ^Tokenizer) {
	for token in tok.tokens {
		fmt.println(token);
		if token.type == TokenType.Semicolon {
			fmt.println("");
		}
	}
}

handleNone :: proc(using tok: ^Tokenizer) {
	// Skip Whitespace
	if strings.is_space(currentRune) do return;

	switch currentRune {
		case 'a'..'z', 'A'..'Z': {
			tokenStart = currentIndex;
			if quoted do tokenContext = TokenizerContext.QuotedIdentifier;
			else do tokenContext = TokenizerContext.Identifier;
		}
		case '(': {
			token := makeToken(TokenType.LeftParen, source[currentIndex:currentIndex + 1], line, col);
			append(&tokens, token);
		}
		case ')': {
			token := makeToken(TokenType.RightParen, source[currentIndex:currentIndex + 1], line, col);
			append(&tokens, token);
		}
		case '{': {
			token := makeToken(TokenType.LeftCurlyBracket, source[currentIndex:currentIndex + 1], line, col);
			append(&tokens, token);
		}
		case '}': {
			token := makeToken(TokenType.RightCurlyBracket, source[currentIndex:currentIndex + 1], line, col);
			append(&tokens, token);
		}
		case ':': {
			token := makeToken(TokenType.Colon, source[currentIndex:currentIndex + 1], line, col);
			append(&tokens, token);
		}
		case ';': {
			token := makeToken(TokenType.Semicolon, source[currentIndex:currentIndex + 1], line, col);
			append(&tokens, token);
		}
		case ',': {
			token := makeToken(TokenType.Comma, source[currentIndex:currentIndex + 1], line, col);
			append(&tokens, token);
		}
		case '"': {
			tokenStart = currentIndex;
			tokenContext = TokenizerContext.String;
		}
		case '`': {
			tokenStart = currentIndex;
			tokenContext = TokenizerContext.RawString;
		}
		case '\'': {
			tokenStart = currentIndex;
			tokenContext = TokenizerContext.Char;
		}
		case '0'..'9': {
			tokenStart = currentIndex;
			tokenContext = TokenizerContext.Number;
		}
		case '-': // TODO
		case '+': {
			token := makeToken(TokenType.Plus, source[currentIndex:currentIndex + 1], line, col);
			append(&tokens, token);
		}
		case '*': {
			token := makeToken(TokenType.Astrisk, source[currentIndex:currentIndex + 1], line, col);
			append(&tokens, token);
		}
		case '/': {
			token := makeToken(TokenType.Slash, source[currentIndex:currentIndex + 1], line, col);
			append(&tokens, token);
		}
		case '\\': {
			token := makeToken(TokenType.Backslash, source[currentIndex:currentIndex + 1], line, col);
			append(&tokens, token);
		}
		case '^': {
			token := makeToken(TokenType.Hat, source[currentIndex:currentIndex + 1], line, col);
			append(&tokens, token);
		}
		case '.': {
			token := makeToken(TokenType.Dot, source[currentIndex:currentIndex + 1], line, col);
			append(&tokens, token);
		}
		case '=': {
			token := makeToken(TokenType.Equal, source[currentIndex:currentIndex + 1], line, col);
			append(&tokens, token);
		}
		case '$': {
			quoted = true;
			return;
		}
		case: {
		}
	}

	if quoted do quoted = false;
}

handleIdentifier :: proc(using tok: ^Tokenizer, quotedIdentifier: bool = false) {
	// Allow whitespace in identifiers
	if tok.ident_allowWhitespace && strings.is_space(currentRune) do return;

	switch(currentRune) {
		case 'a'..'z', 'A'..'Z', '0'..'9', '_', '-': {
			return;
		}
		case: {
			type: TokenType = TokenType.Identifier;
			if quotedIdentifier do type = TokenType.QuotedIdentifier;

			str := source[tokenStart:currentIndex];
			if tok.keywords[str] {
				type = TokenType.Keyword;
			}

			token := makeToken(type, str, line, col);
			append(&tokens, token);
			tokenContext = TokenizerContext.None;

			handleNone(tok);
		}
	}
}

handleString :: proc(using tok: ^Tokenizer, raw: bool = false) {
	// Allow whitespace in strings
	if strings.is_space(currentRune) do return;

	if currentRune == '"' && !raw {
		token := makeToken(TokenType.String, source[tokenStart:currentIndex + 1], line, col);
		append(&tokens, token);
		tokenContext = TokenizerContext.None;
	} else if currentRune == '`' && raw {
		token := makeToken(TokenType.RawString, source[tokenStart:currentIndex + 1], line, col);
		append(&tokens, token);
		tokenContext = TokenizerContext.None;
	}
}

// TODO: Error on more than one character in char literal
handleChar :: proc(using tok: ^Tokenizer) {
	if currentRune == '\'' {
		token := makeToken(TokenType.Char, source[tokenStart:currentIndex + 1], line, col);
		append(&tokens, token);
		tokenContext = TokenizerContext.None;
	}
}

handleNumber :: proc(using tok: ^Tokenizer) {
	switch currentRune {
		case '0'..'9', '.': {
			return;
		}
		case: { // Note: Whitespace *not* allowed
			token := makeToken(TokenType.Number, source[tokenStart:currentIndex], line, col);
			append(&tokens, token);
			tokenContext = TokenizerContext.None;

			handleNone(tok);
		}
	}
}


package main

import "core:runtime"
import "tokenizer"
import "ncure"

BuiltinProc :: #type proc(self: ^Builtin, globalData: ^GlobalData);
CallProc :: #type proc(self: ^Call, globalData: ^GlobalData);

Parser :: struct {
	builtins: ^map[string]BuiltinProc,
	builtinCalls: ^map[string]CallProc,
	statements: [dynamic]Statement,
	currentTokenIndex: int,
}

Statement :: union {
	Builtin,
	Call,
	ParserError,
}

ParserError :: union {
	ParserError_Internal,
	ParserError_UnknownIdent,
	ParserError_UnknownCall,
	ParserError_NoParams,
	ParserError_UnexpectedToken,
	ParserError_Unimplemented,
}
/*ParserErrorBase :: struct {
	tokens: []tokenizer.Token,
}*/
ParserError_Internal :: struct {
	tokens: []tokenizer.Token,
	internal_location: runtime.Source_Code_Location,
}
ParserError_UnknownIdent :: struct {
	tokens: []tokenizer.Token,
}
ParserError_UnknownCall :: struct {
	tokens: []tokenizer.Token,
}
ParserError_NoParams :: struct {
	tokens: []tokenizer.Token,
}
ParserError_UnexpectedToken :: struct {
	tokens: []tokenizer.Token,
}
ParserError_Unimplemented :: struct {}

Builtin :: struct {
	p: BuiltinProc,
	rest: []tokenizer.Token,
}

make_builtin :: proc(builtin: ^Builtin, p: BuiltinProc, rest: []tokenizer.Token) {
	builtin.p = p;
	builtin.rest = rest;
}

Call :: struct {
	p: CallProc,
	command: []tokenizer.Token,
	subcommand: []tokenizer.Token,
	hasSubcommand: bool,
	help: bool, // True is no parentheses - should show help of command
	params: [dynamic]Parameter, // TODO
}

make_call :: proc(call: ^Call, command: []tokenizer.Token, subcommand: []tokenizer.Token = nil) {
	call.p = defaultCallProc;
	call.command = command;
	call.subcommand = nil;
	if len(subcommand) > 0 {
		call.hasSubcommand = true;
		call.subcommand = subcommand;
	}
	call.help = true;
	call.params = make([dynamic]Parameter);
}

make_builtinCall :: proc(call: ^Call, p: CallProc) {
	make_call(call, nil, nil);
	call.p = p;
}

destroy_call :: proc(call: ^Call) {
	delete(call.params);
}

Parameter :: struct {
	value: Value,
	name: ^tokenizer.Token,
}

makeParser :: proc(parser: ^Parser, builtins: ^map[string]BuiltinProc, builtinCalls: ^map[string]CallProc) {
	parser.builtins = builtins;
	parser.builtinCalls = builtinCalls;
	parser.statements = make([dynamic]Statement);
}

destroyParser :: proc(parser: ^Parser) {
	for i in 0..<len(parser.statements) {
		statement := &parser.statements[i];

		#partial switch v in statement {
			case Call: {
				destroy_call(transmute(^Call) statement);
			}
		}
	}

	delete(parser.statements);
}

Value :: struct {
	using _: ^tokenizer.Token,
	boolean: bool,
}

currentToken :: proc(parser: ^Parser, tok: ^tokenizer.Tokenizer) -> (^tokenizer.Token, int) {
	if parser.currentTokenIndex >= len(tok.tokens) do return nil, parser.currentTokenIndex;
	return &tok.tokens[parser.currentTokenIndex], parser.currentTokenIndex;
}

nextToken :: proc(parser: ^Parser, tok: ^tokenizer.Tokenizer) -> (^tokenizer.Token, int) {
	parser.currentTokenIndex += 1;
	return currentToken(parser, tok);
}

hasNextToken :: proc(parser: ^Parser, tok: ^tokenizer.Tokenizer) -> bool {
	token, i := peekNextToken(parser, tok);
	return i < len(tok.tokens) && token.type != tokenizer.TokenType.End;
}

hasNextTokenIf :: proc(parser: ^Parser, tok: ^tokenizer.Tokenizer, type: tokenizer.TokenType) -> bool {
	token, i := peekNextToken(parser, tok);
	return i < len(tok.tokens) && token.type != tokenizer.TokenType.End && token.type == type;
}

nextTokenIf :: proc(parser: ^Parser, tok: ^tokenizer.Tokenizer, type: tokenizer.TokenType) -> (^tokenizer.Token, int, bool) {
	index := parser.currentTokenIndex + 1;
	token := &tok.tokens[index];
	if token.type == type {
		parser.currentTokenIndex = index;
		return token, index, true;
	}

	return nil, -1, false;
}

peekNextToken :: proc(parser: ^Parser, tok: ^tokenizer.Tokenizer) -> (^tokenizer.Token, int) {
	return &tok.tokens[parser.currentTokenIndex + 1], parser.currentTokenIndex + 1;
}

incrementTokenIndex :: proc(parser: ^Parser, tok: ^tokenizer.Tokenizer) {
	parser.currentTokenIndex += 1;
}

parseInput :: proc(parser: ^Parser, tok: ^tokenizer.Tokenizer) -> ParserError {
	using tokenizer;

	parser.currentTokenIndex = 0;
	for {
		current_token, current_i := currentToken(parser, tok);

		#partial switch (current_token.type) {
			case TokenType.Keyword: {
				statement := parseKeywordStatement(parser, tok);
				if err, isError := statement.(ParserError); isError {
					return err;
				}
				ncure.println(statement);
				append(&parser.statements, statement);
			}
			case TokenType.Identifier: {
				statement := parseIdentifierStatement(parser, tok);
				if err, isError := statement.(ParserError); isError {
					return err;
				}
				append(&parser.statements, statement);
			}
			case: {
				// TODO: Cleanup
				error: ParserError = ParserError_UnexpectedToken{tok.tokens[current_i:current_i + 1]};
				return error;
			}
		}

		current_token, current_i = currentToken(parser, tok);
		if current_i >= len(tok.tokens) || current_token.type == TokenType.End {
			break;
		}
	}

	return nil;
}

// TODO
parseKeywordStatement :: proc(parser: ^Parser, tok: ^tokenizer.Tokenizer) -> (Statement) {
	using tokenizer;

	keyword, startTokenIndex := currentToken(parser, tok);
	nextToken, nextTokenIndex := nextToken(parser, tok);

	#partial switch nextToken.type {
		case TokenType.LeftParen: {
			incrementTokenIndex(parser, tok);

			p, ok := parser.builtinCalls[keyword.str];
			if ok {
				call: Call;
				make_builtinCall(&call, p);
				return call;
			} else {
				// Check if regular builtin
				p, ok := parser.builtins[keyword.str];
				if ok {
					semicolonToken_index := findStatementEnd(parser, tok);
					builtin: Builtin;
					make_builtin(&builtin, p, tok.tokens[parser.currentTokenIndex:semicolonToken_index]);
					parser.currentTokenIndex = semicolonToken_index + 1; // TODO
					return builtin;
				} else {
					// ERROR
// 					error: ParserError = ParserError_Internal{tok.tokens[startTokenIndex:parser.currentTokenIndex], #location};
// 					return error;
				}
			}
		}
		case: {
			/*p, ok := parser.builtins[keyword.str];
			if ok {
				semicolonToken_index := findStatementEnd(parser, tok);
				builtin: Builtin;
				make_builtin(&builtin, p, tok.tokens[parser.currentTokenIndex:semicolonToken_index]);
				parser.currentTokenIndex = semicolonToken_index + 1;
				return builtin;
			} else {
			}*/
			// TODO: Cleanup
			error: ParserError = ParserError_Unimplemented{};
			return error;
		}
	}

	unreachable();
}


// Check ident in builtins
// Check left paren
//   Check Subcommand
//   Check ident in builtin Calls
//   Otherwise, check in command hashmaps
//   Check in current directory last (maybe...)
parseIdentifierStatement :: proc(parser: ^Parser, tok: ^tokenizer.Tokenizer) -> (Statement) {
	using tokenizer;

	ident, identIndex := currentToken(parser, tok);
	nextToken, nextTokenIndex := nextToken(parser, tok);

	// Check if in builtins
	p, is_builtin := parser.builtins[ident.str];
	if is_builtin {
		semicolonToken_index := findStatementEnd(parser, tok);
		builtin: Builtin;
		make_builtin(&builtin, p, tok.tokens[parser.currentTokenIndex:semicolonToken_index]);
		parser.currentTokenIndex = semicolonToken_index + 1;
		return builtin;
	}

	#partial switch nextToken.type {
		case TokenType.Dot: {
			return parseSubcommand(parser, tok, identIndex);
		}
		case TokenType.LeftParen: {
			return parseCall(parser, tok, identIndex);
		}
		case TokenType.End, TokenType.Semicolon: {
			return parseHelpCall(parser, tok, identIndex);
		}
		case: {
			// TODO: Cleanup
			error: ParserError = ParserError_UnexpectedToken{tok.tokens[nextTokenIndex:nextTokenIndex + 1]};
			return error;
		}
	}

	unreachable();
}

parseSubcommand :: proc(parser: ^Parser, tok: ^tokenizer.Tokenizer, identIndex: int) -> Statement {
	using tokenizer;

	subcommand, subcommandIndex, hasSubcommand := nextTokenIf(parser, tok, TokenType.Identifier);
	if !hasSubcommand {
		// TODO: Cleanup
		error: ParserError = ParserError_UnexpectedToken{tok.tokens[subcommandIndex:subcommandIndex + 1]};
		return error;
	}

	nextToken, nextTokenIndex := nextToken(parser, tok);
	#partial switch nextToken.type {
		case TokenType.LeftParen: {
			return parseCall(parser, tok, identIndex, true, subcommandIndex);
		}
		case TokenType.End, TokenType.Semicolon: {
			incrementTokenIndex(parser, tok);
			return parseHelpCall(parser, tok, identIndex, true, subcommandIndex);
		}
		case: {
			// TODO: Cleanup
			error: ParserError = ParserError_UnexpectedToken{tok.tokens[nextTokenIndex:nextTokenIndex + 1]};
			return error;
		}
	}

	unreachable();
}

parseHelpCall :: proc(parser: ^Parser, tok: ^tokenizer.Tokenizer, identIndex: int, hasSubcommand := false, subcommandIndex: int = 0) -> Statement {
	call: Call;

	if hasSubcommand do make_call(&call, tok.tokens[identIndex:identIndex + 1], tok.tokens[subcommandIndex:subcommandIndex + 1]);
	else do make_call(&call, tok.tokens[identIndex:identIndex + 1]);

	call.help = true;

	return call;
}

parseCall :: proc(parser: ^Parser, tok: ^tokenizer.Tokenizer, identIndex: int, hasSubcommand := false, subcommandIndex: int = 0) -> Statement {
	using tokenizer;

	call: Call;

	if hasSubcommand do make_call(&call, tok.tokens[identIndex:identIndex + 1], tok.tokens[subcommandIndex:subcommandIndex + 1]);
	else do make_call(&call, tok.tokens[identIndex:identIndex + 1]);

	call.help = false;
	error := parseParameters(parser, tok, &call.params);
	if error != nil {
		// TODO: Cleanup stuff
		return error;
	}

	return call;
}

// FirstParameter  := (ident = value) | value
// OtherParameters := ',' ((ident = value) | value)
// value           := Number | String | Char | Boolean
parseParameters :: proc(parser: ^Parser, tok: ^tokenizer.Tokenizer, params: ^[dynamic]Parameter) -> ParserError {
	using tokenizer;

	param: Parameter;
	hasName := false;
	hasValue := false;
	outer: for {
		nextToken, nextTokenIndex := nextToken(parser, tok);
		#partial switch nextToken.type {
			case TokenType.Identifier: {
				// Check if there's an equals, if not, then expression, otherwise a named parameter
				equalsToken, equalsTokenIndex, hasEquals := nextTokenIf(parser, tok, TokenType.Equal);
				if hasEquals && !hasName {
					param.name = nextToken;
					hasName = true;
				} else {
					// Identifier Value
					// TODO: Not currently allowed atm
					return ParserError_UnexpectedToken {tok.tokens[nextTokenIndex + 1:nextTokenIndex + 2]};
				}
			}
			case TokenType.Number: {
				if hasValue {
					// TODO: Cleanup
					// TODO: Expressions?
					error: ParserError = ParserError_UnexpectedToken{tok.tokens[nextTokenIndex:nextTokenIndex + 1]};
					return error;
				}
				param.value = Value { nextToken, false };
				hasValue = true;
			}
			case TokenType.String: {
				if hasValue {
					// TODO: Cleanup
					// TODO: Expressions?
					error: ParserError = ParserError_UnexpectedToken{tok.tokens[nextTokenIndex:nextTokenIndex + 1]};
					return error;
				}
				param.value = Value { nextToken, false };
				hasValue = true;
			}
			case TokenType.Char: {
				if hasValue {
					// TODO: Cleanup
					// TODO: Expressions?
					error: ParserError = ParserError_UnexpectedToken{tok.tokens[nextTokenIndex:nextTokenIndex + 1]};
					return error;
				}
				param.value = Value { nextToken, false };
				hasValue = true;
			}
			case TokenType.Keyword: {
				if hasValue {
					// TODO: Cleanup
					// TODO: Expressions?
					error: ParserError = ParserError_UnexpectedToken{tok.tokens[nextTokenIndex:nextTokenIndex + 1]};
					return error;
				}
				if nextToken.str == "true" || nextToken.str == "false" {
					param.value = Value { nextToken, true };
					hasValue = true;
				}
			}
			case TokenType.Comma: {
				// End of current parameter. Append it to list
				if !hasValue {
					// TODO: Cleanup
					// TODO: No parameter value error
					error: ParserError = ParserError_UnexpectedToken{tok.tokens[nextTokenIndex:nextTokenIndex + 1]};
					return error;
				}
				append(params, param);
				param.name = nil;
				param.value = Value { nil, false };
				hasName = false;
				hasValue = false;
			}
			case TokenType.RightParen: {
				if hasName && !hasValue {
					// TODO: Cleanup
					// TODO: No parameter value error
					error: ParserError = ParserError_UnexpectedToken{tok.tokens[nextTokenIndex:nextTokenIndex + 1]};
					return error;
				} else if hasValue {
					append(params, param);
// 					ncure.println("Test");
					param.name = nil;
					param.value = Value { nil, false };
					hasName = false;
					hasValue = false;
				}
				nextTokenIf(parser, tok, TokenType.Semicolon);
				incrementTokenIndex(parser, tok);
				break outer;
			}
			case TokenType.Semicolon: {
				if hasName && !hasValue {
					// TODO: Cleanup
					// TODO: No parameter value error
					error: ParserError = ParserError_UnexpectedToken{tok.tokens[nextTokenIndex:nextTokenIndex + 1]};
					return error;
				} else {
					// TODO: Cleanup
					// TODO: Error, no right parentheses
					error: ParserError = ParserError_UnexpectedToken{tok.tokens[nextTokenIndex:nextTokenIndex + 1]};
					return error;
				}
			}
			case TokenType.End: {
				if hasName && !hasValue {
					// TODO: Cleanup
					// TODO: No parameter value error
					error: ParserError = ParserError_UnexpectedToken{tok.tokens[nextTokenIndex:nextTokenIndex + 1]};
					return error;
				} else {
					// TODO: Cleanup
					// TODO: Error, no right parentheses
					error: ParserError = ParserError_UnexpectedToken{tok.tokens[nextTokenIndex:nextTokenIndex + 1]};
					return error;
				}
			}
			case: {
				// TODO: Cleanup
				error: ParserError = ParserError_UnexpectedToken{tok.tokens[nextTokenIndex:nextTokenIndex + 1]};
				return error;
			}
		}
	}

	return nil;
}

findStatementEnd :: proc(parser: ^Parser, tok: ^tokenizer.Tokenizer) -> int {
	using tokenizer;

	offset := parser.currentTokenIndex;
	for token, i in tok.tokens[parser.currentTokenIndex:] {
		if token.type == TokenType.Semicolon || token.type == TokenType.End {
			return offset + i;
		}
	}

	unreachable();
}

findToken :: proc(parser: ^Parser, tok: ^tokenizer.Tokenizer, type: tokenizer.TokenType) -> (int, bool) {
	using tokenizer;

	offset := parser.currentTokenIndex;
	for token, i in tok.tokens[parser.currentTokenIndex:] {
		if token.type == type {
			return offset + i, true;
		}
	}

	return len(tok.tokens) - 1, false;
}



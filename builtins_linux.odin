package main

BuiltinCd :: proc(self: ^Builtin, globalData: ^GlobalData) {
	linux.setenv("OLDPWD", globalData.current, true);
	
	ncure.println(self.rest);
	
	globalData.current = os.get_current_directory();
	linux.setenv("PWD", globalData.current, true);
}

BuiltinGetenv :: proc(self: ^Builtin, globaldata: ^GlobalData) {
	if self.rest[0].type == tokenizer.TokenType.Identifier {
		result, ok := linux.secure_getenv(self.rest[0].str);
		if ok {
			ncure.println(result);
		}
	}
}

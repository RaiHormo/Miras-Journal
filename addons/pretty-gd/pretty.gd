class_name Prettifier

var indent_str = "\t"
var tab_size = 4

var input = ""
var pos = 0
var first_words = []
var last_token = ""


func prettify(_input: String) -> String:
	reset(_input)
	var output = ""
	var min_indent = 0
	var max_indent = 80
	while not is_eof():
		var line = read_line(min_indent, max_indent)
		if line.strip_edges():
			for first_token in first_words:
				if doubleblank.has(first_token):
					var i = output.rfind("\n\n")
					if i > 0: output = output.substr(0, i) + "\n" + output.substr(i)
			min_indent = 0
			max_indent = ceil(space_size(line) / tab_size) + 2
			output += line + "\n"
			if last_token == ":":
				max_indent += -1
				min_indent = max_indent
		elif not output.ends_with("\n\n"):
			min_indent = 0
			output += "\n"
	return output.strip_edges(false, true)


func reset(_input = input, _indent_str = indent_str, _tab_size = tab_size, _pos = 0):
	input = _input
	indent_str = _indent_str
	tab_size = _tab_size
	pos = _pos
	if not indent_str: indent_str = "\t"
	tab_size = space_size(indent_str)
	var first_words = []
	var last_token = ""


func read_line(min_indent = 0, max_indent = 10):
	var line = read_whitespace()
	first_words = []
	last_token = ""
	if is_eol(): return read().strip_edges()
	var indent = clamp(ceil((space_size(line) + tab_size - 1) / tab_size), min_indent, max_indent)
	line = ""
	for i in range(indent):
		line += indent_str
	var tokens = ["", "", ""]
	while not is_eol():
		tokens.push_back(read_token())
		while tokens.size() > 3: tokens.pop_front()
		line += between(tokens[0], tokens[1], tokens[2]) + tokens.back()
	first_words = get_first_words(line)
	line += read()
	return line.strip_edges(false, true)


func read_token():
	var token = ""
	read_whitespace()
	if longoperators.has(peek(4)):
		token += read(4)
	elif longoperators.has(peek(3)):
		token += read(3)
	elif longoperators.has(peek(2)):
		token += read(2)
	elif peek() == "#":
		token += read_until("\n")
	elif peek() == "@" and identifier.containsn(peek(1, 1)):
		token += read() + read_while(identifier)
	elif peek() == "." and number.containsn(peek(1, 1)):
		token += read_number()
	elif number.containsn(peek()):
		token += read_number()
	elif string.containsn(peek()) and quote.containsn(peek(1, 1)):
		token += read_string()
	elif quote.containsn(peek()):
		token += read_string()
	elif identifier.containsn(peek()):
		token += read_while(identifier)
	elif node.containsn(peek()):
		token += read_node()
	else:
		token += read()
	read_whitespace()
	if not token.begins_with("#"):
		last_token = token
	return token


func read_node():
	var token = read().to_lower()
	if quote.containsn(peek()):
		token += read_string()
	else:
		token += read_while(nodepath)
	return token


func read_string():
	var token = ""
	var quot = read().to_lower()
	if string.containsn(quot):
		token += quot
		quot = read()
	if peek(2) == quot + quot:
		quot += read(2)
	token += quot
	while not is_eof() && peek(quot.length()) != quot:
		if peek() == "\\": token += read(2)
		else: token += read(1)

	token += read(quot.length())
	return token


func read_number():
	var token = ""
	var reg = peek()
	while reg.containsn(peek()):
		token += read().to_lower()
		if token == ".": token = "0."
		if token == "0":
			reg = ".0123456789_bex"
			if "0123456789".containsn(peek()):
				token = ""
		elif token.begins_with("0x"): reg = "0123456789_abcdef"
		elif token.begins_with("0b"): reg = "01_"
		elif token.ends_with("e"): reg = "+-0123456789_"
		elif token.containsn("e"): reg = "0123456789_"
		elif token.containsn("."): reg = "0123456789_e"
		else: reg = ".0123456789_e"

	if token == "0x": token += "0"
	elif token == "0b": token += "0"
	elif token.ends_with("."): token += "0"
	elif token.ends_with("e"): token += "0"
	elif token.ends_with("-"): token += "0"
	elif token.ends_with("+"): token += "0"

	return token


func read_word():
	var token = ""
	while peek().strip_edges():
		token += read()
	return token


func read_whitespace():
	var token = ""
	while not is_eol() and not peek().strip_edges():
		token += read()
	return token


func read_while(charset):
	var output = ""
	while charset.containsn(peek()) or (charset.containsn("ø") and peek().unicode_at(0) > 127):
		output += read()
	return output


func read_until(delimiter):
	var output = ""
	while peek(delimiter.length()) != delimiter and not is_eof():
		output += read()
	return output


func read(len = 1):
	if is_eof(): return ""
	pos += len
	return input.substr(pos - len, len)


func peek(len = 1, skip = 0):
	if is_eof(): return ""
	return input.substr(pos + skip, len)


func is_eol():
	return is_eof() or peek() == "\n"


func is_eof():
	return pos >= input.length()


func between(token0, token1, token2):
	if !token1: return ""
	if !token2: return ""
	if token2.begins_with("#"): return "  "

	if sign.containsn(token1):
		if keywords.has(token0): return ""
		if parens_end.containsn(token0): return " "
		if quote.containsn(token0.right(1)): return " "
		if identifier.containsn(token0.right(1)): return " "
		return ""

	if token1 == "{": return " "
	if token2 == "}": return " "

	if parens_start.containsn(token1): return ""
	if longoperators.has(token1): return " "
	if longoperators.has(token2): return " "
	if operator.containsn(token1): return " "
	if operator.containsn(token2): return " "
	if comma.containsn(token1): return " "
	if comma.containsn(token2): return ""
	if keywords.has(token1): return " "
	if keywords.has(token2): return " "
	if parens.containsn(token1): return ""
	if parens.containsn(token2): return ""

	if identifier.containsn(token1.right(1)): return " "

	return ""


func get_first_words(line):
	return Array(line.strip_edges().get_slice("#", 0).get_slice("'", 0).get_slice('"', 0).split(" ", false))


func space_size(whitespace):
	if not whitespace: return 0
	if not tab_size: tab_size = 4
	var sum = 0
	for char in whitespace:
		match char:
			"\n":
				sum = 0

			"\t":
				sum += 1
				while sum % tab_size: sum += 1

			" ":
				sum += 1

			_:
				return sum
	return sum

const keywords = ["if", "else", "elif", "for", "while", "break", "continue",
	"pass", "return", "class", "class_name", "extends", "is", "as", "signal",
	"static", "const", "enum", "var", "breakpoint", "yield", "in", "and", "or"]
const doubleblank = ["class", "func"]
const longoperators = ["**", "<<", ">>", "==", "!=", ">=", "<=", "&&", "||",
	"+=", "-=", "*=", "/=", "%=", "**=", "&=", "^=", "|=", "<<=", ">>=",
	":=", "->"]
const operator = "%&*+-/<=>?\\^|"
const string = "r&^"
const quote = "\"\'"
const node = "$%"
const comma = ",;:"
const parens_start = "(["
const parens = "([.])"
const parens_end = "]})"
const sign = "!+-"
const number = "0123456789"
const identifier = "0123456789_abcdefghijklmnopqrstuvwxyzø"
const nodepath = "%/" + identifier

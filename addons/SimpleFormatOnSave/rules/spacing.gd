class_name RuleSpacing

const SYMBOLS = [
	r"\*\*=",
	r"\*\*",
	"<<=",
	">>=",
	"<<",
	">>",
	"==",
	"!=",
	">=",
	"<=",
	"&&",
	r"\|\|",
	r"\+=",
	"-=",
	r"\*=",
	"/=",
	"%=",
	"&=",
	r"\^=",
	r"\|=",
	"~=",
	":=",
	"->",
	r"&",
	r"\|",
	r"\^",
	"-",
	r"\+",
	"/",
	r"\*",
	">",
	"<",
	"-",
	"%",
	"=",
	":",
	",",
];
const KEYWORDS = [
	"and",
	"is",
	"or",
	"not",
]


static func apply(code: String) -> String:
	var string_regex = RegEx.new()
	string_regex.compile(r'(?<!#)("""|\'\'\'|"|\')((?:.|\n)*?)\1')

	var string_matches = string_regex.search_all(code)
	var string_map = {}

	for i in range(string_matches.size()):
		var match = string_matches[i]
		var original = match.get_string()
		var placeholder = "__STRING__%d__" % i
		string_map[placeholder] = original
		code = _replace(code, original, placeholder)

	var comment_regex = RegEx.new()
	comment_regex.compile("#.*")
	var comment_matches = comment_regex.search_all(code)
	var comment_map = {}

	for i in range(comment_matches.size()):
		var match = comment_matches[i]
		var original = match.get_string()
		var placeholder = "__COMMENT__%d__" % i
		comment_map[placeholder] = original
		code = _replace(code, original, placeholder)

	var ref_regex = RegEx.new()
	ref_regex.compile(r"\$[^.]*")
	var ref_matches = ref_regex.search_all(code)
	var ref_map = {}

	for i in range(ref_matches.size()):
		var match = ref_matches[i]
		var original = match.get_string()
		var placeholder = "__REF__%d__" % i
		ref_map[placeholder] = original
		code = _replace(code, original, placeholder)

	code = _format_operators_and_commas(code)

	for placeholder in ref_map:
		code = code.replace(placeholder, ref_map[placeholder])

	for placeholder in comment_map:
		code = code.replace(placeholder, comment_map[placeholder])

	for placeholder in string_map:
		code = code.replace(placeholder, string_map[placeholder])

	return code


static func _format_operators_and_commas(code: String) -> String:
	var indent_regex = RegEx.create_from_string(r"^\s{4}")
	var new_code = indent_regex.sub(code, "\t", true)

	while (code != new_code):
		code = new_code
		new_code = indent_regex.sub(code, "\t", true)

	var symbols_regex = "(" + ") | (".join(SYMBOLS) + ")"
	symbols_regex = " * ?(" + symbols_regex + ") * "
	var symbols_operator_regex = RegEx.create_from_string(symbols_regex)
	code = symbols_operator_regex.sub(code, " $1 ", true)

	# ": =" => ":="
	code = RegEx.create_from_string(r" *: *= *").sub(code, " := ", true)

	# "a(" => "a (" 
	code = RegEx.create_from_string(r"(?<=[\w\)\]]) *([\(:,])(?!=)").sub(code, "$1", true)

	# "( a" => "(a"
	code = RegEx.create_from_string(r"([\(\{}]) *").sub(code, "$1", true)

	# "a )" => "a)"
	code = RegEx.create_from_string(r" *([\)\}])").sub(code, "$1", true)

	# "if(" => "if ("
	code = RegEx.create_from_string(r"\b(if|for|while|switch|match)\(").sub(code, "$1 (", true)

	var keywoisrd_regex = r"|".join(KEYWORDS)
	var keyword_operator_regex = RegEx.create_from_string(r"(?<=[ \)\]])(" + keywoisrd_regex + r")(?=[ \(\[])")
	code = keyword_operator_regex.sub(code, " $1 ", true)

	# tab "a\t=" => "a ="
	code = RegEx.create_from_string(r"(\t*. * ?)\t * ").sub(code, "$1", true)

	#trim
	code = RegEx.create_from_string("[ \t]*\n").sub(code, "\n", true)

	# "  " => " "
	code = RegEx.create_from_string(" +").sub(code, " ", true)

	# "= -a" => "= -a"
	code = RegEx.create_from_string(r"([=,(] ?)- ").sub(code, "$1-", true)

	return code


static func _replace(text: String, what: String, forwhat: String) -> String:
	var index := text.find(what)

	if index != -1:
		text = text.substr(0, index) + forwhat + text.substr(index + what.length())

	return text

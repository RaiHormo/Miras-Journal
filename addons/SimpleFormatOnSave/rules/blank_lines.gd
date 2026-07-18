class_name RuleBlankLines

var FORMAT_ACTION := "simple_format_on_save/format_code"
var format_key: InputEventKey


static func apply(code: String) -> String:
	var trim1_regex = RegEx.create_from_string("\n{2,}")
	code = trim1_regex.sub(code, "\n\n", true)
	code = _blank_for_func_class(code)
	var trim2_regex = RegEx.create_from_string("\n{3,}")
	code = trim2_regex.sub(code, "\n\n\n", true)
	return code


static func _blank_for_func_class(code: String) -> String:
	var assignment_regex = RegEx.create_from_string(r".*=.*")
	var statement_regex = RegEx.create_from_string(r"^\s+(if|for|while|match)[\s|\(].*")
	var misc_statement_regex = RegEx.create_from_string(r"\s+(else|elif|\}|\]|\)|\,).*")
	var func_class_regex = RegEx.create_from_string(r".*(func|class) .*")
	var comment_line_regex = RegEx.create_from_string(r"^\s*#")
	var empty_line_regex = RegEx.create_from_string(r"^\s+$")
	var lines := code.split('\n')
	var modified_lines: Array[String] = []

	for line: String in lines:
		# Spaces between functions & classes
		if func_class_regex.search(line):
			if modified_lines.size() > 0:
				var i := modified_lines.size() - 1

				while i > 0 and comment_line_regex.search(modified_lines[i]):
					i -= 1

				if i == 0:
					modified_lines.append(line)
					continue

				modified_lines.insert(i + 1, "")
				modified_lines.insert(i + 1, "")

		# 1 space between assignment & statement
		if statement_regex.search(line):
			if modified_lines.size() > 0:
				var i := modified_lines.size() - 1

				if assignment_regex.search(modified_lines[i]) \
					and not func_class_regex.search(modified_lines[i]) \
					and not statement_regex.search(modified_lines[i]):
					modified_lines.insert(i + 1, "")

				else:
					pass

		# Space after a code block (Doesn't work with spaces for now)
		var indent_count := line.count("\t")

		if indent_count and not misc_statement_regex.search(line):
			if modified_lines.size() > 0:
				var i := modified_lines.size() - 1

				if modified_lines[i].count("\t") > indent_count and not misc_statement_regex.search(modified_lines[i]):
					modified_lines.insert(i + 1, "")

		modified_lines.append(line)

	return "\n".join(modified_lines)

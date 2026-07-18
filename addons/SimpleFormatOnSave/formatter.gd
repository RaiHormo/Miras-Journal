class_name Formatter

const RuleSpacing = preload("./rules/spacing.gd")
const RuleBlankLines = preload("./rules/blank_lines.gd")


func format_code(code: String) -> String:
	code = RuleSpacing.apply(code)
	code = RuleBlankLines.apply(code)
	return code

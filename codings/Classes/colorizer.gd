extends Node
class_name Colorizer

static var ElementColor: Dictionary = {
	heat = Color.hex(0xff6b50ff), electric = Color.hex(0xfcde42ff), natural = Color.hex(0xd1ff3cff),
	wind = Color.hex(0x56d741ff), spiritual = Color.hex(0x52f8b5ff), cold = Color.hex(0x52f8b5ff),
	liquid = Color.hex(0x57a0f9ff), technical = Color.hex(0x7f17ffff), corruption = Color.hex(0xc333c3ff),
	physical = Color.hex(0xd3446dff),

	attack = Color.hex(0xdf3737ff), magic = Color.hex(0x5a68dfff), defence = Color.hex(0x40f178ff)}

static func colorize(str: String) -> String:
	for i in ElementColor.keys():
		var elname: String = i
		#str = colorize_replace(elname, str, i)
		str = colorize_replace(elname.capitalize(), str, i)
		str = colorize_replace(state_element_verbing(elname), str, i)
		str = colorize_replace(state_element_verbs(elname), str, i)
		str = colorize_replace(state_element_verbed(elname), str, i)
		str = colorize_replace(state_element_verb(elname), str, i)
	return str

static func colorize_replace(elname, str: String, i) -> String:
	if elname in str:
		var hex: String = "#%02X%02X%02X" % [ElementColor[i].r*255, ElementColor[i].g*255, ElementColor[i].b*255]
		var hex_out: String = "#%02X%02X%02X" % [ElementColor[i].r*100, ElementColor[i].g*100, ElementColor[i].b*100]
		return str.replacen(elname, "[outline_size=12][outline_color=" + hex_out + "][color=" + hex + "]" + elname + "[/color][/outline_color][/outline_size]")
	return str

static func state_element_verb(str: String) -> String:
	match str:
		"heat": return "burn"
		"wind": return "launch"
		"corruption": return "poison"
		"spiritual": return "confuse"
		"cold": return "freeze"
		"technical": return "deflect"
		"physical": return "bind"
		"liquid": return "soak"
		"electric": return "zap"
		"natural": return "leech"
		"defence": return "guard"
		"attack": return "knock out"
		"magic": return "Aura break"
	return str

static func state_element_verbs(str: String) -> String:
	match str:
		"heat": return "burns"
		"wind": return "launches"
		"corruption": return "poisons"
		"spiritual": return "confuses"
		"cold": return "freezes"
		"technical": return "deflects"
		"physical": return "binds"
		"liquid": return "soaks"
		"heat": return "burns"
		"electric": return "zaps"
		"natural": return "leeches"
		"defence": return "guards"
		"attack": return "knocks out"
		"magic": return "breaks their Aura"
	return str

static func state_element_verbed(str: String) -> String:
	match str:
		"heat": return "burned"
		"wind": return "launched"
		"corruption": return "poisoned"
		"spiritual": return "confused"
		"cold": return "freezed"
		"technical": return "deflected"
		"physical": return "bound"
		"liquid": return "soaked"
		"heat": return "burned"
		"electric": return "zapped"
		"natural": return "leeched"
		"defence": return "guarded"
		"attack": return "knocked out"
		"magic": return "Aura broken"
	return str

static func state_element_verbing(str: String) -> String:
	match str:
		"heat": return "burning"
		"wind": return "launching"
		"corruption": return "poisoning"
		"spiritual": return "confusing"
		"cold": return "freezing"
		"technical": return "deflecting"
		"physical": return "binding"
		"liquid": return "soaking"
		"heat": return "burning"
		"electric": return "zapping"
		"natural": return "leeching"
		"defence": return "guarding"
		"attack": return "knocking out"
		"magic": return "breaking their Aura"
	return str

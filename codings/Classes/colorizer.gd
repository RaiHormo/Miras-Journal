extends Node
class_name Colorizer

static var ElementColor: Dictionary[String, Color] = {
	heat = Color.hex(0xff6b50ff), electric = Color.hex(0xfcde42ff), natural = Color.hex(0xd1ff3cff),
	wind = Color.hex(0x56d741ff), spiritual = Color.hex(0x52f8b5ff), cold = Color.hex(0x52f8b5ff),
	liquid = Color.hex(0x57a0f9ff), technical = Color.hex(0x7f17ffff), corruption = Color.hex(0xc333c3ff),
	physical = Color.hex(0xd3446dff),

	attack = Color.hex(0xdf3737ff), magic = Color.hex(0x5a68dfff), defence = Color.hex(0x40f178ff) }


static func colorize(string: String) -> String:
	for i: String in ElementColor.keys():
		var elname: String = i
		#str = colorize_replace(elname, str, i)
		string = string.replace("[color=%" + i + "]", "[color=" + ElementColor.get(i).to_html() + "]")
		string = colorize_replace(elname.capitalize(), string, i)
		string = colorize_replace(state_element_verbing(elname), string, i)
		string = colorize_replace(state_element_verbs(elname), string, i)
		string = colorize_replace(state_element_verbed(elname), string, i)
		string = colorize_replace(state_element_verb(elname), string, i)
	return string


static func colorize_explicit(stri: String) -> String:
	for elname: String in ElementColor.keys():
		if "[color=%" + elname + "]" in stri:
			var color: Color = ElementColor.get(elname)
			color.v = min(color.v, 0.8)
			stri = stri.replace("[color=%" + elname + "]", "[color=" + color.to_html() + "]")
	return stri


static func colorize_replace(elname: String, stri: String, i: String) -> String:
	if elname in stri:
		var hex: String = ElementColor[i].to_html()
		var out_color := (ElementColor[i] / 3)
		out_color.a = 1
		var hex_out: String = out_color.to_html()
		return stri.replacen(elname, "[outline_size=12][outline_color=" + hex_out + "][color=" + hex + "]" + elname + "[/color][/outline_color][/outline_size]")
	return stri


static func state_element_verb(string: String) -> String:
	match string:
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
	return string


static func state_element_verbs(string: String) -> String:
	match string:
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
	return string


static func state_element_verbed(string: String) -> String:
	match string:
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
	return string


static func state_element_verbing(string: String) -> String:
	match string:
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
	return string

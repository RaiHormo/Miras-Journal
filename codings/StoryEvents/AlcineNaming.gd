extends CanvasLayer
signal enter
var txt: String = ''

func _ready() -> void:
	hide()

func start():
	get_tree().paused = false
	PartyUI.Expanded = false
	show()
	$TextureRect.texture = await Query.find_member("Alcine").RenderArtwork()
	$Error.hide()
	$TextEdit.grab_focus()
	$TextEdit.set_caret_column(10)
	await enter
	queue_free()

func _on_text_edit_text_changed(text: String) -> void:
	if "\n" in text:
		$TextEdit.text = text.replace("\n", "")
		return
	if text.length() > 10:
		$Error.text = "Bit too long, isn't it?"
		$Error.show()
		if text.length() > 10 and text.length() > txt.length():
			$TextEdit.text = txt
			$TextEdit.set_caret_column(20)
	else:
		$Error.hide()
	txt = $TextEdit.text

func on_confirm(text: String) -> void:
	$TextEdit.text = $TextEdit.text.dedent()
	if $TextEdit.text != "":
		$TextEdit.text[0].to_upper()
	await Event.wait(0.03)
	$TextEdit.set_caret_column(20)
	txt = $TextEdit.text
	txt = txt.to_lower()
	if txt.length() > 10: return
	elif txt.length() == 1:
		$Error.text = "Let's try to be a little more creative."
		$Error.show()
	elif txt.length() == 0:
		$TextEdit.text = "Alcine"
		on_confirm("Alcine")
	elif check_for_symbols():
		$Error.text = "I shouldn't include symbols"
		$Error.show()
	elif "fuck" in txt or "shit" in txt or "ass" in txt or "cunt" in txt or "butt" in txt or "nigg" in txt or "faggot" in txt or "tranny" in txt:
		$Error.text = "No."
		$Error.show()
	elif "mira" == txt or "levenor" == txt:
		$Error.text = "That's a little egotistical..."
		$Error.show()
	elif ("daze" == txt or "asteria" == txt or "versea" == txt or
	"feni" == txt or "kai" == txt or "maple" == txt or "anemythe" == txt or "noreen" == txt or "daroca" == txt or "reshanne" in txt or "yaru" == txt):
		$Error.text = "I feel like I shouldn't choose that name."
		$Error.show()
	elif ("guardian" == txt):
		$Error.text = "I need to keep that for something greater."
		$Error.show()
	elif "erinn" == txt:
		$Error.text = "Name them after my cousin?\n Why?"
		$Error.show()
	elif "erin" == txt:
		$Error.text = "It's spelled with two Ns,\n and no."
		$Error.show()
	elif "brent" == txt:
		$Error.text = "What does he have to do with this?!"
		$Error.show()
	elif "enowme" in txt:
		$Error.text = "..."
		$Error.show()
	elif "spirit" == txt:
		$Error.text = "That was just placeholder..."
		$Error.show()
	elif "enowmi" in txt or "enomi" in txt or "eknowme" in txt or "enowm" in txt:
		$Error.text = "You think you're clever, huh?"
		$Error.show()
	elif txt == "piss":
		$Error.text = "That is an absolutely terrible name, why would I ever even consider it for a creature like this?"
		$Error.show()
	elif txt == "pissed":
		$Error.text = "I'm absolutely pissed that I'm even going down this thought process, oh how can I be so cruel."
		$Error.show()
	elif txt == "pissing":
		$Error.text = "It is a terrible fate that has fallen upon me."
		$Error.show()
	elif "aaa" in txt:
		$Error.text = "Seriously? I think i can do better than this."
		$Error.show()
	else:
		Query.find_member("Alcine").FirstName = txt.capitalize()
		Global.textbox("naming", "what_about")
	await get_tree().process_frame
	$TextEdit.set_caret_column(14)

func check_for_symbols():
	var res = false
	for i in txt:
		if !(i.is_valid_identifier() or i == " ") or i == "_":
			res = true
	return res

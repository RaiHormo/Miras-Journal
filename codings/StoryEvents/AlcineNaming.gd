extends Control
signal enter
var txt: String = ''

func _ready() -> void:
	hide()

func start():
	PartyUI.Expanded = false
	show()
	$TextureRect.texture = await Global.find_member("Alcine").RenderArtwork()
	$Error.hide()
	$TextEdit.grab_focus()
	$TextEdit.set_caret_column(10)
	await enter

func _on_text_edit_text_changed() -> void:
	if "\n" in $TextEdit.text:
		$TextEdit.text = $TextEdit.text.replace("\n", "")
		return
	if $TextEdit.text.length() > 13:
		$Error.text = "Bit too long, isn't it?"
		$Error.show()
		if $TextEdit.text.length() > 13:
			$TextEdit.text = txt
			$TextEdit.set_caret_column(14)
	else:
		$Error.hide()
	txt = $TextEdit.text

func on_confirm() -> void:
	$TextEdit.text = $TextEdit.text.dedent()
	$TextEdit.text = $TextEdit.text.capitalize()
	await Event.wait(0.03)
	$TextEdit.set_caret_column(14)
	txt = $TextEdit.text
	txt = txt.to_lower()
	if txt.length() > 13: return
	elif txt.length() == 1:
		$Error.text = "Let's try to be a little more creative."
		$Error.show()
	elif txt.length() == 0:
		$TextEdit.text = "Alcine"
		on_confirm()
	elif check_for_symbols():
		$Error.text = "I shouldn't include symbols"
		$Error.show()
	elif "fuck" in txt or "shit" in txt or "ass" in txt or "cunt" in txt or "butt" in txt or "nigg" in txt or "faggot" in txt:
		$Error.text = "No."
		$Error.show()
	elif "mira" == txt or "levenor" == txt:
		$Error.text = "That's a little egotistical..."
		$Error.show()
	elif ("daze" == txt or "asteria" == txt or "versea" == txt or
	"feni" == txt or "kai" == txt or "maple" == txt or "anemythe" == txt or "noreen" == txt):
		$Error.text = "I feel like i shouldn't choose that name."
		$Error.show()
	elif "erinn" == txt:
		$Error.text = "Name them after my cousin?\n Why?"
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
	elif "aaa" in txt:
		$Error.text = "Seriously? I think i can do better than this."
		$Error.show()
	else:
		Global.find_member("Alcine").FirstName = txt.capitalize()
		enter.emit()
	await get_tree().process_frame
	$TextEdit.set_caret_column(14)


func _input(event: InputEvent) -> void:
	if InputMap.event_is_action(event, "Options") or Input.is_key_pressed(KEY_ENTER):
		on_confirm()

func check_for_symbols():
	var res = false
	for i in txt:
		if !(i.is_valid_identifier() or i == " ") or i == "_":
			res = true
	return res

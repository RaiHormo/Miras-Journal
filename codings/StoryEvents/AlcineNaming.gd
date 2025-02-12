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
	if $TextEdit.text.length() > 10:
		$Error.text = "Bit too long, isn't it?"
		$Error.show()
		if $TextEdit.text.length() > 11:
			$TextEdit.text = txt
			$TextEdit.set_caret_column(11)
	else:
		$Error.hide()
	txt = $TextEdit.text

func on_confirm() -> void:
	$TextEdit.text = $TextEdit.text.dedent()
	$TextEdit.text = $TextEdit.text.capitalize()
	await Event.wait(0.03)
	$TextEdit.set_caret_column(11)
	txt = $TextEdit.text
	txt = txt.to_lower()
	if txt.length() > 10: return
	elif txt.length() == 1:
		$Error.text = "Let's try to be a little more creative."
		$Error.show()
	elif txt.length() == 0:
		$TextEdit.text = "Alcine"
		on_confirm()
	elif check_for_symbols():
		$Error.text = "Why would I include symbols in a name?"
		$Error.show()
	elif "fuck" in txt or "shit" in txt or "ass" in txt or "cunt" in txt:
		$Error.text = "No."
		$Error.show()
	elif "mira" in txt or "levenor" in txt:
		$Error.text = "That's a little egotistical..."
		$Error.show()
	elif ("daze" == txt or "asteria" == txt or "versea" == txt or
	"feni" == txt or "kai" == txt or "maple" == txt):
		$Error.text = "I feel like i shouldn't choose that name."
		$Error.show()
	elif "erinn" in txt:
		$Error.text = "Name them after my cousin?\n Why?"
		$Error.show()
	elif "enowme" in txt:
		$Error.text = "..."
		$Error.show()
	elif "enowmi" in txt or "enomi" in txt:
		$Error.text = "You think you're clever, huh?"
		$Error.show()
	elif "aaa" in txt:
		$Error.text = "Seriously?"
		$Error.show()
	else:
		Global.find_member("Alcine").FirstName = txt.capitalize()
		enter.emit()
	await Event.wait(0.02)
	$TextEdit.set_caret_column(11)


func _input(event: InputEvent) -> void:
	if InputMap.event_is_action(event, "Options") or Input.is_key_pressed(KEY_ENTER):
		on_confirm()

func check_for_symbols():
	var res = false
	for i in txt:
		if !(i.is_valid_identifier() or i == " ") or i == "_":
			res = true
	return res

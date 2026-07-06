extends AudioStreamPlayer

func _ready() -> void:
	volume_db = -5
	process_mode = Node.PROCESS_MODE_ALWAYS

func cursor_sound(dont_force := false) -> void:
	if not(dont_force and playing):
		stream = preload("res://sound/SFX/cursor.wav")
		play()

func buzzer_sound() -> void:
	stream = preload("res://sound/SFX/buzzer.ogg")
	play()

func confirm_sound() -> void:
	stream = preload("res://sound/SFX/confirm.ogg")
	play()

func cancel_sound() -> void:
	stream = preload("res://sound/SFX/Quit.ogg")
	play()

func item_sound() -> void:
	stream = preload("res://sound/SFX/item.ogg")
	play()

func ui_sound(string: String) -> void:
	stream = await Loader.load_res("res://sound/SFX/" + string + ".ogg")
	play()

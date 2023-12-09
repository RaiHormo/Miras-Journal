extends DialogueLabel
var soundfreq
var varience
@export var AudioPlayer: AudioStreamPlayer
var count: int = 0

func type_out_with_sound(sound, freq, vari) -> void:
	AudioPlayer.stream = sound
	soundfreq = freq
	varience = vari
	type_out()


func _on_spoke(letter: String, letter_index: int, speed: float) -> void:
	count += 1
	if count == soundfreq:
		AudioPlayer.pitch_scale = randf_range((10-varience)/10, (10+varience)/10)
		AudioPlayer.play()
		count = 0

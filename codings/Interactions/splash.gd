extends Area2D
@export var text: String

func _on_body_entered(body: Node2D) -> void:
	if body == Global.Player:
		if text == "Amberelm" and not Event.f("EnteredAmberelm", 2):
			Event.take_control()
			Global.Player.camera_follow(false)
			var t = create_tween()
			Global.Player.set_anim("IdleUp")
			t.tween_property(Global.get_cam(), "position", Vector2(150, 252), 7)
			await Event.wait(1)
			Global.location_name(text)
			await Event.wait(5)
			Loader.gray_out(1, 1)
			Event.flag_progress("EnteredAmberelm", 2)
			await Event.wait(2)
			Event.give_control()
			Global.Player.position = Vector2(222, 429)
			Event.take_control(false, true)
			await Event.wait(1)
			Loader.ungray.emit()
			await Global.textbox("amberelm_txt", "what_happened_here")
			await Loader.transition("R")
			Global.Player.position = Vector2(150, 345)
			Loader.detransition()
			Event.give_control()
			Global.Player.set_anim("IdleRight")


extends Button
class_name WaveButton

var focused := false
@export var enable_waves := true
@export var theme_color: Color = Color.html("#e3936e")
@onready var glow: Panel = $Glow
@onready var timer: Timer = $Timer


func _ready() -> void:
	if not get_theme_color("font_focus_color") == theme_color:
		add_theme_color_override("font_focus_color", theme_color)
		add_theme_color_override("font_pressed_color", theme_color)
		add_theme_color_override("font_hover_pressed_color", theme_color)
		var glow_panel: StyleBoxFlat = glow.get_theme_stylebox("panel").duplicate()
		glow_panel.bg_color = theme_color
		glow.add_theme_stylebox_override("panel", glow_panel)


func _on_focus_entered() -> void:
	if focused: return
	focused = true
	if enable_waves:
		wave()
	timer.start(1)


func _on_focus_exited() -> void:
	focused = false
	timer.stop()


func wave() -> void:
	if not enable_waves: return

	var this := glow.duplicate()
	this.size = size
	this.show()
	add_child(this)
	var t := create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	t.tween_property(this, "size", Vector2(24, 24), 1).as_relative()
	t.tween_property(this, "position", -Vector2(12, 12), 1).as_relative()
	t.tween_property(this, "modulate:a", 0, 1)
	await t.finished
	this.queue_free()


func _on_timer_timeout() -> void:
	if focused:
		wave()

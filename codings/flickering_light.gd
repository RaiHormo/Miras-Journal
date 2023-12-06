extends PointLight2D
@export var flicker := false
@export var around_scale := 3.0
@export var around_energy := 1.5
@export var amount := 0.05

func _physics_process(delta: float) -> void:
	if flicker:
		texture_scale = around_scale + randf_range(-amount, amount)
		energy = around_energy + randf_range(-amount, amount)

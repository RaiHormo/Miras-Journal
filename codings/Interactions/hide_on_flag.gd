extends Node2D

@export var flag: String = ""
@export var hide_if: bool = true
@export var use_sprite = false
@export var free_instead:= false

func _ready() -> void:
	check()
	Global.check_party.connect(check)

func check():
	if get_node_or_null("Sprite") != null: use_sprite = true
	if flag == "": return
	if Event.f(flag) == hide_if:
		if use_sprite:
			if $Sprite.animation != "hide": $Sprite.play("hide")
		elif free_instead:
			get_parent().queue_free()
		else:
			get_parent().hide()
		for i in get_parent().get_children():
			if i is CollisionShape2D: i.disabled = true
	else:
		if use_sprite:
			if $Sprite.animation != "default": $Sprite.play("default")
		else:
			get_parent().show()
		for i in get_parent().get_children():
			if i is CollisionShape2D: i.disabled = false

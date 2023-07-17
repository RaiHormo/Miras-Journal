extends Node2D

func _process(delta):
	$MiraBody/RemoteTransform2D.remote_path = get_path_to(get_parent())

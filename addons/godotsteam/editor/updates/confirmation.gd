@tool
extends ConfirmationDialog

signal cancel_update
signal continue_update

@onready var cancel_button: Button = %Cancel
@onready var continue_button: Button = %Continue
@onready var downloading: ProgressBar = %Downloading
@onready var message: Label = %Message
@onready var version_title: Label = %VersionTitle


func _ready() -> void:
	connect_signals()
	set_defaults()


#region Setup
func set_defaults() -> void:
	size = Vector2(450, 330)
	get_ok_button().visible = false
	get_cancel_button().visible = false
#endregion


#region Signals
func connect_signals() -> void:
	cancel_button.pressed.connect(_on_cancel_pressed)
	continue_button.pressed.connect(_on_continue_pressed)


func _on_cancel_pressed() -> void:
	cancel_update.emit()
	queue_free()


func _on_continue_pressed() -> void:
	continue_update.emit()
#endregion


#region Updating text
func update_interface(version_string: String, is_downloader: bool) -> void:
	if not is_node_ready(): await ready
	cancel_button.visible = true
	continue_button.visible = not is_downloader
	downloading.visible = is_downloader
	if is_downloader:
		message.text = "You are downloading the update, please wait. Closing this window will cancel the update."
		version_title.text = "Downloading GodotSteam %s" % version_string
	else:
		message.text = "You are about to update plug-in version to %s.  The editor will restart at the end of this process." % version_string
		version_title.text = "Update To GodotSteam %s" % version_string


func update_progress(new_percentage: int) -> void:
	downloading.value = new_percentage
#endregion

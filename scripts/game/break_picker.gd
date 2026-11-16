class_name BreakPicker extends Node
## Node, a piece of Game: Romper's choosing. While it is active the whole tree is paused (Game
## pauses it) and this piece, which keeps processing, takes the next tap: picked(screen) with where
## it was, or cancelled for Esc. The HUD's Romper button keeps working too and takes its own taps
## first (a Control before unhandled input). Game asks the Jar which creature is there.

signal picked(screen: Vector2)
signal cancelled

var active := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_unhandled_input(false)


func start() -> void:
	active = true
	set_process_unhandled_input(true)


func stop() -> void:
	active = false
	set_process_unhandled_input(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cancelled.emit()
		return
	var press := event as InputEventMouseButton
	if press and press.pressed and press.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		picked.emit(press.position)

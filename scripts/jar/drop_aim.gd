class_name DropAim extends Node3D
## Node, a piece of Jar: the creature waiting at the top of the jar, the faint vertical line
## under it that marks where it will fall, and the input that moves it and lets it go. A touch or
## a click anywhere puts it at the finger's x (kept inside the jar), dragging moves it, lifting
## the finger emits released; on the desktop the arrows or A/D move it and Space lets it go. A
## phone's touches arrive as mouse events (Godot's emulate_mouse_from_touch), so the mouse path is
## the only one. Controls take their own events first (the HUD's pause button). Jar calls step()
## every physics frame (the keys).

signal released(x: float)

const KEY_SPEED := 6.0
const LINE_WIDTH := 0.04

var x := 0.0
var enabled := true
var _camera: Camera3D
var _radius := 0.3
var _waiting: Node3D
var _line: MeshInstance3D
var _held := false


func setup(camera: Camera3D) -> void:
	_camera = camera


func _ready() -> void:
	_line = JarBuilder.line(LINE_WIDTH, JarSpec.WAIT_Y, UiTokens.color(&"aim-line"))
	_line.visible = false
	add_child(_line)


func show_waiting(data: CreatureData) -> void:
	hide_waiting()
	_waiting = CreatureLooks.build(data)
	add_child(_waiting)
	_radius = data.radius
	_move_to(x)
	_line.visible = true


func hide_waiting() -> void:
	if _waiting:
		_waiting.queue_free()
		_waiting = null
	_line.visible = false


func step(delta: float) -> void:
	if not enabled:
		return
	var direction := 0.0
	if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A):
		direction -= 1.0
	if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D):
		direction += 1.0
	if direction != 0.0:
		_move_to(x + direction * KEY_SPEED * delta)


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	var button := event as InputEventMouseButton
	if button and button.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		_move_to(_world_x(button.position))
		if button.pressed:
			_held = true
		elif _held:
			_held = false
			released.emit(x)
		return
	var motion := event as InputEventMouseMotion
	if motion and _held:
		if not (motion.button_mask & MOUSE_BUTTON_MASK_LEFT):
			_held = false
			return
		_move_to(_world_x(motion.position))
		return
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
		released.emit(x)


## The world x under a point of the screen (the camera is orthographic and head on).
func _world_x(screen: Vector2) -> float:
	return _camera.project_ray_origin(screen).x


func _move_to(value: float) -> void:
	x = JarSpec.clamp_x(value, _radius)
	if _waiting:
		_waiting.position = Vector3(x, JarSpec.WAIT_Y, 0.0)
	_line.position = Vector3(x, JarSpec.WAIT_Y / 2.0, JarBuilder.BACK_Z + 0.05)

class_name Jar extends Node3D
## Node: the jar of one round and its creatures as physics bodies (CreatureBody). It only
## reports what happens (released: the finger let the waiting creature go) and plays back what
## Game tells it (drop, show_waiting). Built by JarBuilder, with its backdrop and camera; its
## piece is DropAim. Game creates a new one for every round and calls step() every physics
## frame: no piece runs its own _physics_process.

signal released(x: float)

var camera: Camera3D
var _bodies: Array[CreatureBody] = []
var _aim: DropAim


func _ready() -> void:
	JarBuilder.backdrop(self)
	JarBuilder.jar(self)
	camera = JarBuilder.camera(self)
	get_viewport().size_changed.connect(_fit)
	_fit()
	_aim = DropAim.new()
	_aim.setup(camera)
	_aim.released.connect(released.emit)
	add_child(_aim)


func step(delta: float) -> void:
	for body in _bodies:
		body.age += delta
	_aim.step(delta)


## The waiting creature falls from the top at x (kept inside the jar).
func drop(data: CreatureData, x: float) -> CreatureBody:
	_aim.hide_waiting()
	return _spawn(data, Vector3(JarSpec.clamp_x(x, data.radius), JarSpec.WAIT_Y, 0.0))


func show_waiting(data: CreatureData) -> void:
	_aim.show_waiting(data)


## The creatures in the jar (read only: the autoplay and Danger look at them).
func creatures() -> Array[CreatureBody]:
	return _bodies


func _fit() -> void:
	JarBuilder.fit_camera(camera)


func _spawn(data: CreatureData, at: Vector3) -> CreatureBody:
	var body := CreatureBody.new(data)
	body.position = at
	add_child(body)
	_bodies.append(body)
	return body

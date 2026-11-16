class_name Jar extends Node3D
## Node: the jar of one round and its creatures as physics bodies (CreatureBody). It only
## reports what happens (released: the finger let the waiting creature go; merge_found: two equal creatures touch) and plays back what
## Game tells it (drop, show_waiting, merge, vanish). Built by JarBuilder, with its backdrop and camera; its
## pieces are DropAim and MergeWatcher. Game creates a new one for every round and calls step() every physics
## frame: no piece runs its own _physics_process.

signal released(x: float)
signal merge_found(a: CreatureBody, b: CreatureBody)

var camera: Camera3D
var _bodies: Array[CreatureBody] = []
var _aim: DropAim
var _watcher: MergeWatcher


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
	_watcher = MergeWatcher.new()
	_watcher.touched.connect(merge_found.emit)
	add_child(_watcher)


func step(delta: float) -> void:
	for body in _bodies:
		body.age += delta
	_aim.step(delta)
	_watcher.step(_bodies)


## The waiting creature falls from the top at x (kept inside the jar).
func drop(data: CreatureData, x: float) -> CreatureBody:
	_aim.hide_waiting()
	return _spawn(data, Vector3(JarSpec.clamp_x(x, data.radius), JarSpec.WAIT_Y, 0.0))


## a and b go; data's creature appears between them, with the mean of their speeds, and grows
## into its place.
func merge(a: CreatureBody, b: CreatureBody, data: CreatureData) -> CreatureBody:
	var at := (a.position + b.position) / 2.0
	var velocity := (a.linear_velocity + b.linear_velocity) / 2.0
	_remove(a)
	_remove(b)
	var body := _spawn(data, at)
	body.linear_velocity = velocity
	body.grow()
	return body


## Two of the last level vanish.
func vanish(a: CreatureBody, b: CreatureBody) -> void:
	_remove(a)
	_remove(b)


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


## Out of the physics space at once (the frame may still have physics steps to run).
func _remove(body: CreatureBody) -> void:
	_bodies.erase(body)
	remove_child(body)
	body.queue_free()

class_name Jar extends Node3D
## Node: the jar of one round and its creatures as physics bodies (CreatureBody). It only
## reports what happens (released: the finger let the waiting creature go; merge_found: two equal creatures touch) and plays back what
## Game tells it (drop, show_waiting, merge, vanish). Built by JarBuilder, with its backdrop and camera; its
## pieces are DropAim, MergeWatcher, DangerLine and FusionFx. Game creates a new one for every round and calls step() every physics
## frame: no piece runs its own _physics_process.

signal released(x: float)
signal merge_found(a: CreatureBody, b: CreatureBody)

var camera: Camera3D
var _bodies: Array[CreatureBody] = []
var _aim: DropAim
var _watcher: MergeWatcher
var _danger: DangerLine
var _fx: FusionFx


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
	_danger = DangerLine.new()
	add_child(_danger)
	_fx = FusionFx.new()
	add_child(_fx)


func step(delta: float) -> void:
	for body in _bodies:
		body.age += delta
	_aim.step(delta)
	_watcher.step(_bodies)
	_danger.step(delta)


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
	_fx.pop(body.figure)
	_fx.burst(at, data.color)
	return body


## Two of the last level vanish, with a flash.
func vanish(a: CreatureBody, b: CreatureBody) -> void:
	var at := (a.position + b.position) / 2.0
	var radius := a.data.radius
	_remove(a)
	_remove(b)
	_fx.flash(at, radius)


## The points a merge won, rising over at.
func show_points(at: Vector3, value: int) -> void:
	_fx.points(at, value)


func show_waiting(data: CreatureData) -> void:
	_aim.show_waiting(data)


## The creatures in the jar (read only: the autoplay and Danger look at them).
func creatures() -> Array[CreatureBody]:
	return _bodies


## The highest top of the creatures that have been at least min_age in the jar; -INF for none.
func highest_top(min_age: float) -> float:
	var top := -INF
	for body in _bodies:
		if body.age >= min_age:
			top = maxf(top, body.top())
	return top


## fraction of Danger.LOSE_TIME gone (0: calm).
func show_danger(fraction: float) -> void:
	_danger.set_alert(fraction)


## The round is lost: every creature stops where it is and nothing more can be dropped.
func freeze_all() -> void:
	_aim.enabled = false
	_aim.hide_waiting()
	for body in _bodies:
		body.freeze = true


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

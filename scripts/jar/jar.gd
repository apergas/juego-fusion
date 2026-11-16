class_name Jar extends Node3D
## Node: the jar of one round and its creatures as physics bodies (CreatureBody). It only reports
## what happens (released: the finger let the waiting creature go; merge_found: two equal
## creatures touch) and plays back what Game tells it (drop, show_waiting, merge, vanish,
## break_creature (Romper), and rebuild() for a kept round; snapshot() gives its creatures to
## RoundSnapshot; creature_at() finds the one under a point). Built by JarBuilder, with its
## backdrop and camera; its pieces are DropAim, MergeWatcher, DangerLine and FusionFx. Game creates
## a new one for every round and calls step() every physics frame: no piece runs its own
## _physics_process.

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


## Each creature as RoundSnapshot.creature(); the ones taken by a merge are about to go and are
## left out.
func snapshot() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for body in _bodies:
		if body.merged:
			continue
		list.append(RoundSnapshot.creature(body.data.level,
			Vector2(body.position.x, body.position.y), body.rotation.z,
			Vector2(body.linear_velocity.x, body.linear_velocity.y), body.angular_velocity.z,
			body.age))
	return list


## The creatures of a kept round (RoundSnapshot.creatures_of()) back where they were, turned and
## moving as they were.
func rebuild(creatures: Array[Dictionary]) -> void:
	for item in creatures:
		var at: Vector2 = item.at
		var velocity: Vector2 = item.velocity
		var body := _spawn(Chain.data(item.level), Vector3(at.x, at.y, 0.0))
		body.rotation.z = item.angle
		body.linear_velocity = Vector3(velocity.x, velocity.y, 0.0)
		body.angular_velocity = Vector3(0.0, 0.0, item.spin)
		body.age = item.age


## The waiting creature's x (kept with a round) and putting it back.
func aim_x() -> float:
	return _aim.x


func set_aim_x(value: float) -> void:
	_aim.set_x(value)


## The world point (in the jar's plane) under a point of the screen: the camera is orthographic
## and head on.
func world_point(screen: Vector2) -> Vector2:
	var origin := camera.project_ray_origin(screen)
	return Vector2(origin.x, origin.y)


## The creature under point (PowerUps.hit()), or null; the ones taken by a merge don't count. A
## creature is where its body is (its figure only stays upright while the body rolls).
func creature_at(point: Vector2) -> CreatureBody:
	var free: Array[CreatureBody] = []
	var centres: Array[Vector2] = []
	var radii: Array[float] = []
	for body in _bodies:
		if body.merged:
			continue
		free.append(body)
		centres.append(Vector2(body.position.x, body.position.y))
		radii.append(body.data.radius)
	var index := PowerUps.hit(point, centres, radii)
	return free[index] if index >= 0 else null


## Romper: body goes at once, in a big burst of its colour.
func break_creature(body: CreatureBody) -> void:
	var at := body.position
	var color := body.data.color
	_remove(body)
	_fx.burst(at, color, FusionFx.FLASH, FusionFx.FLASH_SPEED)


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

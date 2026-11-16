class_name RoundSnapshot extends RefCounted
## A round in progress as a Dictionary, so it survives closing the game (SaveData keeps it in the
## save's "round", Profile.saved_round), and back. Pure: no nodes, no files. The Jar gives each
## creature as creature() (its level, where it is, how it is turned and moving, its age); the rest
## is the GameState and the waiting creature's x. Spawner's generator goes as its state, written as
## a String (JSON would round a 64-bit number). The combo's clock is kept at most at
## Scoring.COMBO_WINDOW (later than that it is all the same, and JSON has no INF). is_valid()
## refuses what a round still going can't have: an unknown level, a negative score, a waiting
## creature Spawner can't give, a danger count already lost, more than MAX_CREATURES, a number
## that is not one; creatures_of() keeps each x inside the jar.

## More creatures than this never fit in the jar.
const MAX_CREATURES := 120


## One creature in the jar: its level, its centre in the plane, its turn around Z (radians), its
## velocity, its turning speed and its seconds in the jar.
static func creature(level: int, at: Vector2, angle: float, velocity: Vector2, spin: float,
		age: float) -> Dictionary:
	return {"level": level, "x": at.x, "y": at.y, "angle": angle, "vx": velocity.x,
		"vy": velocity.y, "spin": spin, "age": age}


## The round of state, with its creatures (creature() each) and the waiting creature's x.
static func from(state: GameState, creatures: Array[Dictionary], aim_x: float) -> Dictionary:
	return {"score": state.score, "combo": state.combo, "max_level": state.max_level,
		"since_merge": minf(state.since_merge, Scoring.COMBO_WINDOW),
		"current": state.current, "next": state.next, "can_drop": state.can_drop,
		"wait_left": state.wait_left, "aim_x": aim_x, "danger_time": state.danger_time,
		"elapsed": state.elapsed, "rng_state": str(state.rng.state),
		"creatures": creatures.duplicate(true)}


static func is_valid(data: Dictionary) -> bool:
	if not (_whole_from(data.get("score"), 0) and _whole_from(data.get("combo"), 0)):
		return false
	if not _whole_in(data.get("max_level"), 0, Chain.MAX_LEVEL):
		return false
	var top := Spawner.WEIGHTS.size()
	if not (_whole_in(data.get("current"), 1, top) and _whole_in(data.get("next"), 1, top)):
		return false
	if not data.get("can_drop") is bool:
		return false
	if not _number_in(data.get("wait_left"), 0.0, Spawner.DROP_WAIT):
		return false
	if not _number_in(data.get("since_merge"), 0.0, Scoring.COMBO_WINDOW):
		return false
	var danger: Variant = data.get("danger_time")
	if not _number_in(danger, 0.0, Danger.LOSE_TIME) or Danger.lost(float(danger)):
		return false
	if not _number_in(data.get("elapsed"), 0.0, INF) or not _number(data.get("aim_x")):
		return false
	var rng_state: Variant = data.get("rng_state")
	if not rng_state is String or not (rng_state as String).is_valid_int():
		return false
	var creatures: Variant = data.get("creatures")
	if not creatures is Array or (creatures as Array).size() > MAX_CREATURES:
		return false
	for item: Variant in creatures:
		if not _is_creature(item):
			return false
	return true


## The GameState of a valid round: its generator where it was, not over.
static func state_of(data: Dictionary) -> GameState:
	var state := GameState.new(0)
	state.rng.state = (data.rng_state as String).to_int()
	state.score = int(data.score)
	state.combo = int(data.combo)
	state.max_level = int(data.max_level)
	state.since_merge = float(data.since_merge)
	state.current = int(data.current)
	state.next = int(data.next)
	state.can_drop = data.can_drop
	state.wait_left = float(data.wait_left)
	state.danger_time = float(data.danger_time)
	state.elapsed = float(data.elapsed)
	return state


## The creatures of a valid round, ready for Jar.rebuild(): {"level", "at", "angle", "velocity",
## "spin", "age"}, each x kept inside the jar.
static func creatures_of(data: Dictionary) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for item: Dictionary in data.creatures:
		var level := int(item.level)
		var radius := Chain.data(level).radius
		list.append({"level": level,
			"at": Vector2(JarSpec.clamp_x(float(item.x), radius), float(item.y)),
			"angle": float(item.angle), "velocity": Vector2(float(item.vx), float(item.vy)),
			"spin": float(item.spin), "age": float(item.age)})
	return list


static func aim_x_of(data: Dictionary) -> float:
	return float(data.aim_x)


## A valid round written again as from() would: the round the game kept (whole numbers) and the
## one the file gives back (every number a float) read the same (the autoplay's check).
static func normalized(data: Dictionary) -> Dictionary:
	var creatures: Array[Dictionary] = []
	for item in creatures_of(data):
		creatures.append(creature(item.level, item.at, item.angle, item.velocity, item.spin,
			item.age))
	return from(state_of(data), creatures, aim_x_of(data))


static func _is_creature(item: Variant) -> bool:
	if not item is Dictionary:
		return false
	var body: Dictionary = item
	if not _whole_in(body.get("level"), 1, Chain.MAX_LEVEL):
		return false
	for key: String in ["x", "y", "angle", "vx", "vy", "spin"]:
		if not _number(body.get(key)):
			return false
	return _number_in(body.get("age"), 0.0, INF)


## A finite number (JSON gives floats; the game keeps ints too).
static func _number(value: Variant) -> bool:
	return value is int or (value is float and is_finite(value))


static func _number_in(value: Variant, low: float, high: float) -> bool:
	return _number(value) and float(value) >= low and float(value) <= high


static func _whole_in(value: Variant, low: int, high: int) -> bool:
	return SaveData.whole(value) and int(value) >= low and int(value) <= high


static func _whole_from(value: Variant, low: int) -> bool:
	return SaveData.whole(value) and int(value) >= low

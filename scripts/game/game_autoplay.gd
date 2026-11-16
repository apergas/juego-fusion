class_name GameAutoplay extends Node
## Node, a piece of Game, only with --autoplay: plays rounds by itself. Each time a creature
## waits it thinks THINK seconds and drops it over the highest settled creature of its own level,
## or, with none, where the pile is lowest (_choose_x()). It prints what a reader of the log
## follows. Uses only Game's Callables (drop) and the Jar's public functions; never stores Game
## or a Jar (it asks jar_of each time: the Jar changes every round).

const THINK := 0.5
## How finely it looks for the lowest place of the pile, in metres.
const SCAN_STEP := 0.25

## drop.call(x): Game.drop_at().
var drop: Callable
var _state_of: Callable
var _jar_of: Callable
var _think := THINK


## state_of and jar_of return the current GameState and Jar.
func setup(state_of: Callable, jar_of: Callable) -> void:
	_state_of = state_of
	_jar_of = jar_of


## Every physics frame (Game._physics_process()).
func step(delta: float) -> void:
	var state: GameState = _state_of.call()
	if state.over or not state.can_drop:
		_think = THINK
		return
	_think -= delta
	if _think > 0.0:
		return
	_think = THINK
	var jar: Jar = _jar_of.call()
	drop.call(_choose_x(Chain.data(state.current), jar.creatures()))


func on_dropped(id: String, x: float) -> void:
	print("Suelta: %s en x=%.1f" % [id, x])


## Over the highest settled creature of data's level; with none, where the pile is lowest
## (the middle wins a tie).
func _choose_x(data: CreatureData, bodies: Array[CreatureBody]) -> float:
	var best: CreatureBody = null
	for body in bodies:
		if body.merged or body.data.level != data.level or body.age < JarSpec.SETTLE_TIME:
			continue
		if best == null or body.position.y > best.position.y:
			best = body
	if best:
		return JarSpec.clamp_x(best.position.x, data.radius)
	var low_x := 0.0
	var low_y := INF
	var x := -JarSpec.WIDTH / 2.0 + data.radius
	while x <= JarSpec.WIDTH / 2.0 - data.radius + 0.001:
		var y := _rest_height(x, data.radius, bodies)
		if y < low_y - 0.01 or (absf(y - low_y) <= 0.01 and absf(x) < absf(low_x)):
			low_y = y
			low_x = x
		x += SCAN_STEP
	return low_x


## Where the centre of a creature of radius falling at x would come to rest on the pile.
func _rest_height(x: float, radius: float, bodies: Array[CreatureBody]) -> float:
	var y := radius
	for body in bodies:
		var reach := body.data.radius + radius
		var dx := absf(body.position.x - x)
		if dx < reach:
			y = maxf(y, body.position.y + sqrt(reach * reach - dx * dx))
	return y

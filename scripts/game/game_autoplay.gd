class_name GameAutoplay extends Node
## Node, a piece of Game, only with --autoplay: plays rounds by itself. Each time a creature
## waits it thinks THINK seconds and drops it over the highest settled creature of its own level,
## or, with none, where the pile is lowest (_choose_x()). Before a drop it uses Cambiar when the
## waiting creature has no settled mate and «Siguiente» has one, and while the danger has counted
## BREAK_AT seconds it uses Romper on the settled creature that reaches highest, not again for
## BREAK_GAP seconds (`Cambia: gota por seta`, `Rompe: lobo`; after each round `Ayudas: 2 Romper,
## 5 Cambiar`, with the averages `Ayudas de media: ...`). It prints what a reader of the log
## follows: each drop (`Suelta: gota en x=1.2`), merge (`Fusión: slime_azul (combo 2)`) and new
## creature (`Nueva: lobo`), the result of each round (`Partida: 1240 puntos, máxima golem,
## 3 min 10 s`) and, with --autoplay-games=N, the averages of the N rounds (`Media de ...`); with
## --autoplay-save, the save written and read back after each round (`Guardado:` and `Cargado:`,
## the same); with --autoplay-resume, RESUME_AT seconds into the first round, the round kept as if
## the player left and read back from the file (`Tarro guardado:` and `Tarro leído:`, the same),
## then played on from there (`Tarro seguido:`). With --autoplay-menu it opens the pause once,
## TOUR_PAUSE_AT seconds into the first round, then Opciones over it, TOUR_STEP seconds each
## (start_menu_tour()). END_WAIT seconds after a round it starts the next (restart) or, after the
## last, asks to quit (quit_requested). Each round it checks that no creature left the plane. Uses
## only Game's Callables (drop, restart, open_pause, close_pause, open_options, close_options,
## keep_round, resume_round, swap, break_creature) and the Jar's public functions; never stores
## Game or a Jar (it asks jar_of each time: the Jar changes every round).

signal quit_requested

const THINK := 0.5
## Seconds the end window stays before the next round (or the quit).
const END_WAIT := 1.0
## How finely it looks for the lowest place of the pile, in metres.
const SCAN_STEP := 0.25
## A creature farther than this from z 0 has left the plane: the axis lock failed.
const DRIFT_LIMIT := 0.01
## The averages count the rounds that reached this level (the spec asks for the 6, the Lobo de
## niebla, in most of them).
const GOAL_LEVEL := 6

## drop.call(x): Game.drop_at().
var drop: Callable
## restart.call(): Game's Otra vez.
var restart: Callable
## open_pause.call(), close_pause.call(), open_options.call() and close_options.call(): Game's
## pause and its Opciones (the menu tour).
var open_pause: Callable
var close_pause: Callable
var open_options: Callable
var close_options: Callable
## keep_round.call() -> Dictionary and resume_round.call(data): Game's keep_round() and
## resume_round() (--autoplay-resume).
var keep_round: Callable
var resume_round: Callable
## swap.call() -> bool and break_creature.call(body) -> bool: Game's swap_waiting() and
## break_creature().
var swap: Callable
var break_creature: Callable
var _state_of: Callable
var _jar_of: Callable
var _games := 1
var _print_save := false
var _check_resume := false
var _resumed := false
var _think := THINK
## Counts down after a round; below 0, no round is over.
var _end_wait := -1.0
var _results: Array[Dictionary] = []
var _breaks_used := 0
var _swaps_used := 0
var _break_wait := 0.0

#region Autoplay
## --autoplay-menu: when the pause opens (seconds of the round) and how long each step stays.
const TOUR_PAUSE_AT := 6.0
const TOUR_STEP := 2.0
## --autoplay-resume: seconds into the first round when it leaves and comes back.
const RESUME_AT := 20.0
## Romper once the danger has counted this long, and not again for BREAK_GAP seconds.
const BREAK_AT := 1.5
const BREAK_GAP := 1.0
#endregion


## state_of and jar_of return the current GameState and Jar; games is --autoplay-games,
## print_save --autoplay-save, check_resume --autoplay-resume.
func setup(state_of: Callable, jar_of: Callable, games: int, print_save: bool,
		check_resume: bool) -> void:
	_state_of = state_of
	_jar_of = jar_of
	_games = games
	_print_save = print_save
	_check_resume = check_resume


## Every physics frame (Game._physics_process()), also while a round is over.
func step(delta: float) -> void:
	if _end_wait >= 0.0:
		_end_wait -= delta
		if _end_wait < 0.0:
			_next_round()
		return
	var state: GameState = _state_of.call()
	if _check_resume and not _resumed and not state.over and state.elapsed >= RESUME_AT:
		_resumed = true
		_leave_and_come_back()
		return
	if state.over:
		_think = THINK
		return
	_maybe_break(state, delta)
	if not state.can_drop:
		_think = THINK
		return
	_think -= delta
	if _think > 0.0:
		return
	_think = THINK
	var jar: Jar = _jar_of.call()
	_maybe_swap(state, jar.creatures())
	drop.call(_choose_x(Chain.data(state.current), jar.creatures()))


func on_dropped(id: String, x: float) -> void:
	print("Suelta: %s en x=%.1f" % [id, x])


## id is the creature made, "" for two of the last level (they vanish).
func on_merged(id: String, combo: int) -> void:
	if id == "":
		var top: String = Chain.IDS[Chain.MAX_LEVEL - 1]
		print("Fusión: %s + %s (combo %d)" % [top, top, combo])
		return
	print("Fusión: %s (combo %d)" % [id, combo])


func on_discovered(id: String) -> void:
	print("Nueva: %s" % id)


## result: score, max_level, seconds, new_record; saved: what SaveStore wrote ({} if nothing).
func on_round_over(result: Dictionary, saved: Dictionary) -> void:
	_check_plane()
	print("Partida: %d puntos, máxima %s, %s" % [result.score, Chain.IDS[result.max_level - 1],
		GameState.time_text(result.seconds)])
	print("Ayudas: %d Romper, %d Cambiar" % [_breaks_used, _swaps_used])
	result.breaks = _breaks_used
	result.swaps = _swaps_used
	_breaks_used = 0
	_swaps_used = 0
	_break_wait = 0.0
	if _print_save:
		_print_round_trip(saved)
	_results.append(result)
	_end_wait = END_WAIT


## --autoplay-menu: the pause opens once, then Opciones over it, then everything closes (its
## timer runs while the tree is paused).
func start_menu_tour() -> void:
	await get_tree().create_timer(TOUR_PAUSE_AT, false).timeout
	open_pause.call()
	await get_tree().create_timer(TOUR_STEP).timeout
	open_options.call()
	await get_tree().create_timer(TOUR_STEP).timeout
	close_options.call()
	await get_tree().create_timer(TOUR_STEP).timeout
	close_pause.call()


func _next_round() -> void:
	if _results.size() < _games:
		restart.call()
		return
	if _games > 1:
		_print_averages()
	quit_requested.emit()


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


## "Media de 20 partidas: 1532 puntos, máxima lobo (12 de 20), 4 min 5 s, 6 o más en 15 de 20".
func _print_averages() -> void:
	var points := 0
	var seconds := 0.0
	var counts := {}
	var goal := 0
	for result in _results:
		points += int(result.score)
		seconds += float(result.seconds)
		var level: int = result.max_level
		counts[level] = counts.get(level, 0) + 1
		if level >= GOAL_LEVEL:
			goal += 1
	var top := 0
	for level: int in counts:
		if top == 0 or counts[level] > counts[top] or (counts[level] == counts[top] and level > top):
			top = level
	var n := _results.size()
	print("Media de %d partidas: %d puntos, máxima %s (%d de %d), %s, %d o más en %d de %d" % [
		n, roundi(points / float(n)), Chain.IDS[top - 1], counts[top], n,
		GameState.time_text(seconds / n), GOAL_LEVEL, goal, n])
	var breaks := 0
	var swaps := 0
	for result in _results:
		breaks += int(result.breaks)
		swaps += int(result.swaps)
	print("Ayudas de media: %.1f Romper, %.1f Cambiar" % [breaks / float(n), swaps / float(n)])


## Cambiar before a drop, when the waiting creature has no settled mate in the jar and «Siguiente»
## has one.
func _maybe_swap(state: GameState, bodies: Array[CreatureBody]) -> void:
	if not PowerUps.can_swap(state) or _has_mate(state.current, bodies) 			or not _has_mate(state.next, bodies):
		return
	var waiting: String = Chain.IDS[state.current - 1]
	if swap.call():
		_swaps_used += 1
		print("Cambia: %s por %s" % [waiting, Chain.IDS[state.current - 1]])


## Romper once the danger has counted BREAK_AT seconds: the settled creature that reaches
## highest; not again for BREAK_GAP seconds.
func _maybe_break(state: GameState, delta: float) -> void:
	_break_wait -= delta
	if state.danger_time < BREAK_AT or _break_wait > 0.0:
		return
	var jar: Jar = _jar_of.call()
	if not PowerUps.can_break(state, jar.creatures().size()):
		return
	var target: CreatureBody = null
	for body in jar.creatures():
		if body.merged or body.age < JarSpec.SETTLE_TIME:
			continue
		if target == null or body.top() > target.top():
			target = body
	if target == null:
		return
	var id := target.data.id
	if break_creature.call(target):
		_break_wait = BREAK_GAP
		_breaks_used += 1
		print("Rompe: %s" % id)


## A settled creature of level, not taken by a merge, is in bodies.
func _has_mate(level: int, bodies: Array[CreatureBody]) -> bool:
	for body in bodies:
		if not body.merged and body.data.level == level and body.age >= JarSpec.SETTLE_TIME:
			return true
	return false


## The save written and the same save read back from the file into a fresh profile and options:
## the two lines must be identical.
func _print_round_trip(saved: Dictionary) -> void:
	var profile := Profile.new()
	var options := GameOptions.new()
	SaveStore.load_into(profile, options)
	print("Guardado: %s" % JSON.stringify(saved))
	print("Cargado: %s" % JSON.stringify(SaveData.from(profile, options)))


## --autoplay-resume: the round kept as if the player left, read back from the file into a fresh
## profile and played on from there. The two lines must be identical (RoundSnapshot.normalized()
## reads the kept round's whole numbers and the file's floats the same).
func _leave_and_come_back() -> void:
	var kept: Dictionary = keep_round.call()
	var profile := Profile.new()
	SaveStore.load_into(profile, GameOptions.new())
	if kept.is_empty() or profile.saved_round.is_empty():
		push_warning("No se ha guardado el tarro")
		return
	print("Tarro guardado: %s" % JSON.stringify(RoundSnapshot.normalized(kept)))
	print("Tarro leído: %s" % JSON.stringify(RoundSnapshot.normalized(profile.saved_round)))
	resume_round.call(profile.saved_round)
	var state: GameState = _state_of.call()
	var jar: Jar = _jar_of.call()
	print("Tarro seguido: %d criaturas, %d puntos" % [jar.creatures().size(), state.score])


## The creatures are locked on Z: one away from z 0 means the lock failed.
func _check_plane() -> void:
	var jar: Jar = _jar_of.call()
	for body in jar.creatures():
		if absf(body.position.z) > DRIFT_LIMIT:
			push_warning("Una criatura se ha salido del plano: %s en z=%.3f"
				% [body.data.id, body.position.z])
			return

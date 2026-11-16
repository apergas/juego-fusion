extends RefCounted
## Shared builders of the tests: a round in progress as a game would keep it. A test that needs it
## preloads this file (const Fixtures := preload("res://tests/fixtures.gd")); it has no tests.


## A round 95 s in: points, a combo going on, the danger counting, the wait after a drop, a few
## creatures already drawn from the generator.
static func round_state() -> GameState:
	var state := GameState.new(7)
	Spawner.start(state)
	for i in 5:
		Spawner.advance(state)
	state.score = 1234
	state.combo = 2
	state.since_merge = 0.4
	state.danger_time = 1.5
	state.elapsed = 95.5
	state.max_level = 6
	state.can_drop = false
	state.wait_left = 0.3
	return state


## Three creatures: a Lobo de niebla settled on the left, a Slime azul rolling and a Gota falling.
static func round_creatures() -> Array[Dictionary]:
	var creatures: Array[Dictionary] = [
		RoundSnapshot.creature(6, Vector2(-1.5, 1.0), 0.3, Vector2(0.2, -0.1), 0.5, 40.0),
		RoundSnapshot.creature(3, Vector2(1.2, 0.52), -1.1, Vector2.ZERO, 0.0, 12.25),
		RoundSnapshot.creature(1, Vector2(0.4, 7.2), 0.0, Vector2(0.0, -3.0), 0.0, 0.1)]
	return creatures


## The round as the save file gives it back: through JSON, every number a float.
static func kept_round() -> Dictionary:
	var data := RoundSnapshot.from(round_state(), round_creatures(), 0.75)
	return JSON.parse_string(JSON.stringify(data))

extends GutTest
## RoundSnapshot: a round in progress through JSON and back, what a round still going can't have,
## and the creatures kept inside the jar. No node and no file is touched here.

const Fixtures := preload("res://tests/fixtures.gd")

## What a round still going can't have: [key, value]. Each is refused.
const BROKEN := [
	["score", -1.0], ["score", 2.5], ["score", "mucho"], ["combo", -1.0], ["max_level", 9.0],
	["current", 0.0], ["current", 5.0], ["next", 9.0], ["can_drop", 1.0], ["wait_left", -0.1],
	["wait_left", 0.6], ["since_merge", -1.0], ["since_merge", 1.5], ["danger_time", 3.0],
	["danger_time", -0.5], ["elapsed", -1.0], ["aim_x", "centro"], ["rng_state", 12.0],
	["rng_state", "mucho"], ["creatures", {}], ["creatures", "lobo"]]
## What a creature in the jar can't have: [key, value]. Each is refused.
const BROKEN_CREATURE := [
	["level", 0.0], ["level", 9.0], ["level", 2.5], ["x", "fuera"], ["vy", null], ["age", -1.0]]


func test_a_round_goes_through_json_and_back() -> void:
	var data := Fixtures.kept_round()
	assert_true(RoundSnapshot.is_valid(data))
	var original := Fixtures.round_state()
	var state := RoundSnapshot.state_of(data)
	for key: String in ["score", "combo", "max_level", "current", "next", "can_drop"]:
		assert_eq(state.get(key), original.get(key), key)
	for key: String in ["wait_left", "since_merge", "danger_time", "elapsed"]:
		assert_almost_eq(float(state.get(key)), float(original.get(key)), 0.0001, key)
	assert_false(state.over)
	assert_almost_eq(RoundSnapshot.aim_x_of(data), 0.75, 0.0001)


func test_the_creatures_come_back_as_they_were() -> void:
	var creatures := RoundSnapshot.creatures_of(Fixtures.kept_round())
	var expected := Fixtures.round_creatures()
	assert_eq(creatures.size(), expected.size())
	for i in creatures.size():
		var at: Vector2 = creatures[i].at
		var velocity: Vector2 = creatures[i].velocity
		assert_eq(creatures[i].level, int(expected[i].level))
		assert_almost_eq(at.x, float(expected[i].x), 0.0001)
		assert_almost_eq(at.y, float(expected[i].y), 0.0001)
		assert_almost_eq(float(creatures[i].angle), float(expected[i].angle), 0.0001)
		assert_almost_eq(velocity.x, float(expected[i].vx), 0.0001)
		assert_almost_eq(velocity.y, float(expected[i].vy), 0.0001)
		assert_almost_eq(float(creatures[i].spin), float(expected[i].spin), 0.0001)
		assert_almost_eq(float(creatures[i].age), float(expected[i].age), 0.0001)


func test_the_generator_goes_on_where_it_was() -> void:
	var original := Fixtures.round_state()
	var state := RoundSnapshot.state_of(Fixtures.kept_round())
	for i in 30:
		assert_eq(Spawner.pick(state.rng), Spawner.pick(original.rng), "pick %d" % i)


func test_the_combo_clock_is_never_infinite_and_an_old_combo_starts_again() -> void:
	var fresh := GameState.new(1)
	assert_eq(fresh.since_merge, INF)
	var none: Array[Dictionary] = []
	var data: Dictionary = JSON.parse_string(JSON.stringify(RoundSnapshot.from(fresh, none, 0.0)))
	assert_true(RoundSnapshot.is_valid(data))
	assert_eq(float(data.since_merge), Scoring.COMBO_WINDOW)
	var state := RoundSnapshot.state_of(data)
	assert_eq(Scoring.next_combo(state.combo, state.since_merge), 1)


func test_what_a_round_still_going_cannot_have_is_refused() -> void:
	for change: Array in BROKEN:
		var data := Fixtures.kept_round()
		data[change[0]] = change[1]
		assert_false(RoundSnapshot.is_valid(data), "%s = %s" % [change[0], change[1]])


func test_a_broken_creature_is_refused() -> void:
	for change: Array in BROKEN_CREATURE:
		var data := Fixtures.kept_round()
		data.creatures[0][change[0]] = change[1]
		assert_false(RoundSnapshot.is_valid(data), "creature %s = %s" % [change[0], change[1]])
	var data := Fixtures.kept_round()
	data.creatures[1] = "slime"
	assert_false(RoundSnapshot.is_valid(data), "a creature that is not a Dictionary")


func test_a_round_missing_a_field_is_refused() -> void:
	for key: String in Fixtures.kept_round().keys():
		var data := Fixtures.kept_round()
		data.erase(key)
		assert_false(RoundSnapshot.is_valid(data), "without %s" % key)
	var data := Fixtures.kept_round()
	data.creatures[2].erase("spin")
	assert_false(RoundSnapshot.is_valid(data), "a creature without spin")


func test_more_creatures_than_fit_are_refused() -> void:
	var data := Fixtures.kept_round()
	var many := []
	for i in RoundSnapshot.MAX_CREATURES + 1:
		many.append(data.creatures[0])
	data.creatures = many
	assert_false(RoundSnapshot.is_valid(data))
	data.creatures = many.slice(0, RoundSnapshot.MAX_CREATURES)
	assert_true(RoundSnapshot.is_valid(data))


func test_a_creature_outside_the_jar_comes_back_in() -> void:
	var data := Fixtures.kept_round()
	data.creatures[1].x = 10.0
	data.creatures[2].x = -10.0
	var creatures := RoundSnapshot.creatures_of(data)
	var right: Vector2 = creatures[1].at
	var left: Vector2 = creatures[2].at
	assert_almost_eq(right.x, JarSpec.WIDTH / 2.0 - Chain.data(3).radius, 0.0001)
	assert_almost_eq(left.x, -JarSpec.WIDTH / 2.0 + Chain.data(1).radius, 0.0001)


func test_the_kept_round_and_the_file_read_the_same() -> void:
	var kept := RoundSnapshot.from(Fixtures.round_state(), Fixtures.round_creatures(), 0.75)
	assert_eq(JSON.stringify(RoundSnapshot.normalized(kept)),
		JSON.stringify(RoundSnapshot.normalized(Fixtures.kept_round())))

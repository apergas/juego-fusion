extends GutTest
## RoundSnapshot: a round in progress through JSON and back, what a round still going can't have,
## and the creatures kept inside the jar. No node and no file is touched here.

const Fixtures := preload("res://tests/fixtures.gd")

## What a round still going can't have: [key, value]. Each is refused.
var broken := [
	["score", -1.0], ["score", 2.5], ["score", "mucho"], ["combo", -1.0], ["max_level", 9.0],
	["current", 0.0], ["current", Spawner.WEIGHTS.size() + 1.0], ["next", 9.0], ["can_drop", 1.0],
	["wait_left", -0.1], ["wait_left", Spawner.DROP_WAIT + 0.1], ["since_merge", -1.0],
	["since_merge", Scoring.COMBO_WINDOW + 0.5], ["danger_time", Danger.LOSE_TIME],
	["danger_time", -0.5], ["elapsed", -1.0], ["aim_x", "centro"], ["rng_state", 12.0],
	["rng_state", "mucho"], ["creatures", {}], ["creatures", "lobo"],
	["breaks", PowerUps.MAX + 1.0], ["breaks", -1.0], ["swaps", 1.5]]
## What a creature in the jar can't have: [key, value]. Each is refused.
const BROKEN_CREATURE := [
	["level", 0.0], ["level", 9.0], ["level", 2.5], ["x", "fuera"], ["vy", null], ["age", -1.0]]


func test_a_round_goes_through_json_and_back() -> void:
	var data := Fixtures.kept_round()
	assert_true(RoundSnapshot.is_valid(data))
	var original := Fixtures.round_state()
	var state := RoundSnapshot.state_of(data)
	for key: String in ["score", "combo", "max_level", "current", "next", "can_drop", "breaks",
			"swaps"]:
		assert_eq(state.get(key), original.get(key), key)
	for key: String in ["wait_left", "since_merge", "danger_time", "elapsed"]:
		assert_almost_eq(float(state.get(key)), float(original.get(key)), 0.0001, key)
	assert_false(state.over)
	assert_almost_eq(RoundSnapshot.aim_x_of(data), 0.75, 0.0001)


func test_a_round_that_can_drop_goes_through_json_and_back() -> void:
	var original := Fixtures.round_state()
	original.can_drop = true
	var none: Array[Dictionary] = []
	var data: Dictionary = JSON.parse_string(JSON.stringify(RoundSnapshot.from(original, none, 0.0)))
	assert_true(RoundSnapshot.is_valid(data))
	assert_true(RoundSnapshot.state_of(data).can_drop)


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
	for change: Array in broken:
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
		if key in ["breaks", "swaps"]:
			continue
		var data := Fixtures.kept_round()
		data.erase(key)
		assert_false(RoundSnapshot.is_valid(data), "without %s" % key)
	var data := Fixtures.kept_round()
	data.creatures[2].erase("spin")
	assert_false(RoundSnapshot.is_valid(data), "a creature without spin")


func test_a_round_kept_before_the_helps_gets_one_of_each() -> void:
	var data := Fixtures.kept_round()
	data.erase("breaks")
	data.erase("swaps")
	assert_true(RoundSnapshot.is_valid(data))
	var state := RoundSnapshot.state_of(data)
	assert_eq(state.breaks, PowerUps.START)
	assert_eq(state.swaps, PowerUps.START)


func test_a_round_with_every_charge_of_one_help_and_none_of_the_other_is_accepted() -> void:
	var data := Fixtures.kept_round()
	data["breaks"] = PowerUps.MAX
	data["swaps"] = 0
	assert_true(RoundSnapshot.is_valid(data))
	var state := RoundSnapshot.state_of(data)
	assert_eq(state.breaks, PowerUps.MAX)
	assert_eq(state.swaps, 0)


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


func test_a_number_that_is_not_finite_is_never_written() -> void:
	var state := Fixtures.round_state()
	state.elapsed = INF
	state.danger_time = NAN
	var creatures: Array[Dictionary] = [
		RoundSnapshot.creature(2, Vector2(NAN, 1.0), INF, Vector2(NAN, -INF), NAN, INF)]
	var data := RoundSnapshot.from(state, creatures, INF)
	var back: Dictionary = JSON.parse_string(JSON.stringify(data))
	assert_true(RoundSnapshot.is_valid(back))
	assert_eq(float(back.aim_x), 0.0)
	assert_eq(float(back.elapsed), 0.0)
	assert_eq(float(back.danger_time), 0.0)
	for key: String in ["x", "angle", "vx", "vy", "spin", "age"]:
		assert_eq(float(back.creatures[0][key]), 0.0, key)


func test_an_infinite_number_in_a_kept_round_is_refused() -> void:
	for change: Array in [["score", INF], ["aim_x", INF], ["elapsed", INF], ["aim_x", NAN]]:
		var data := Fixtures.kept_round()
		data[change[0]] = change[1]
		assert_false(RoundSnapshot.is_valid(data), "%s = %s" % [change[0], change[1]])
	var data := Fixtures.kept_round()
	data.creatures[0].vx = INF
	assert_false(RoundSnapshot.is_valid(data), "creature vx = INF")

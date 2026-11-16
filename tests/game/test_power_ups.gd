extends GutTest
## PowerUps: the helps a round starts with, how they are earned (never past MAX), what Cambiar and
## Romper need and spend, and which creature is under the finger.


## A round on, with a creature waiting and the helps of a start.
func _round() -> GameState:
	var state := GameState.new(3)
	Spawner.start(state)
	PowerUps.start(state)
	state.can_drop = true
	return state


func test_a_round_starts_with_one_of_each() -> void:
	var state := _round()
	assert_eq(state.breaks, PowerUps.START)
	assert_eq(state.swaps, PowerUps.START)


func test_cambiar_is_earned_each_time_the_score_crosses_a_step() -> void:
	var state := _round()
	state.score = PowerUps.SWAP_EVERY - 1
	assert_eq(PowerUps.earn(state, 0, 0).swaps, 0)
	state.score = PowerUps.SWAP_EVERY
	assert_eq(PowerUps.earn(state, PowerUps.SWAP_EVERY - 1, 0).swaps, 1)
	state.swaps = 0
	state.score = PowerUps.SWAP_EVERY * 2 + floori(PowerUps.SWAP_EVERY / 2.0)
	assert_eq(PowerUps.earn(state, floori(PowerUps.SWAP_EVERY / 2.0), 0).swaps, 2)
	assert_eq(state.swaps, 2)


func test_romper_is_earned_by_each_new_biggest_from_its_level() -> void:
	var state := _round()
	var from := PowerUps.BREAK_FROM_LEVEL
	state.max_level = from - 1
	assert_eq(PowerUps.earn(state, 0, from - 2).breaks, 0)
	state.max_level = from
	assert_eq(PowerUps.earn(state, 0, from - 1).breaks, 1)
	state.breaks = 0
	state.max_level = Chain.MAX_LEVEL
	assert_eq(PowerUps.earn(state, 0, from).breaks, Chain.MAX_LEVEL - from)
	assert_eq(PowerUps.earn(state, 0, Chain.MAX_LEVEL).breaks, 0, "the same biggest again")


func test_no_help_ever_goes_past_max() -> void:
	var state := _round()
	state.score = PowerUps.SWAP_EVERY * 10
	state.max_level = Chain.MAX_LEVEL
	var earned := PowerUps.earn(state, 0, 0)
	assert_eq(state.swaps, PowerUps.MAX)
	assert_eq(state.breaks, PowerUps.MAX)
	assert_eq(earned.swaps, PowerUps.MAX - PowerUps.START)
	assert_eq(earned.breaks, PowerUps.MAX - PowerUps.START)


func test_cambiar_swaps_the_waiting_creature_with_the_next_and_spends_one() -> void:
	var state := _round()
	state.current = 1
	state.next = 3
	assert_true(PowerUps.can_swap(state))
	assert_true(PowerUps.swap(state))
	assert_eq(state.current, 3)
	assert_eq(state.next, 1)
	assert_eq(state.swaps, PowerUps.START - 1)


func test_cambiar_needs_a_charge_a_waiting_creature_two_different_and_a_round_on() -> void:
	var cases := {"no charge": "swaps", "nothing waits": "can_drop", "the same two": "next",
		"the round is over": "over"}
	for why: String in cases:
		var state := _round()
		state.current = 2
		state.next = 4
		match cases[why]:
			"swaps":
				state.swaps = 0
			"can_drop":
				state.can_drop = false
			"next":
				state.next = 2
			"over":
				state.over = true
		var before := [state.current, state.next, state.swaps]
		assert_false(PowerUps.can_swap(state), why)
		assert_false(PowerUps.swap(state), why)
		assert_eq([state.current, state.next, state.swaps], before, why)


func test_romper_spends_one_and_needs_a_charge_creatures_and_a_round_on() -> void:
	var state := _round()
	assert_true(PowerUps.can_break(state, 3))
	assert_false(PowerUps.can_break(state, 0), "an empty jar")
	assert_true(PowerUps.use_break(state))
	assert_eq(state.breaks, PowerUps.START - 1)
	state.breaks = 0
	assert_false(PowerUps.can_break(state, 3))
	assert_false(PowerUps.use_break(state))
	assert_eq(state.breaks, 0)
	state.breaks = 1
	state.over = true
	assert_false(PowerUps.can_break(state, 3))
	assert_false(PowerUps.use_break(state))
	assert_eq(state.breaks, 1)


func test_hit_finds_the_creature_under_the_finger() -> void:
	var centres: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(5.0, 5.0)]
	var radii: Array[float] = [0.8, 0.8, 0.3]
	assert_eq(PowerUps.hit(Vector2(-0.5, 0.0), centres, radii), 0)
	assert_eq(PowerUps.hit(Vector2(0.7, 0.0), centres, radii), 1, "inside both: the nearer")
	assert_eq(PowerUps.hit(Vector2(5.0, 5.2), centres, radii), 2)
	assert_eq(PowerUps.hit(Vector2(3.0, 3.0), centres, radii), -1)
	var none_c: Array[Vector2] = []
	var none_r: Array[float] = []
	assert_eq(PowerUps.hit(Vector2.ZERO, none_c, none_r), -1)
